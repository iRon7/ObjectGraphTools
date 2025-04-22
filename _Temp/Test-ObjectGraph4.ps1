using module .\..\..\ObjectGraphTools.psm1

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic

<#
.SYNOPSIS
    Tests the properties of an object-graph.

.DESCRIPTION
    Tests an object-graph against a schema object by verifying that the properties of the object-graph
    meet the constrains defined in the schema object.

    Statements:
    * @RequiredNodes defines the required nodes and the order of the nodes to be tested
    * Any child node that isn't listed in the `@Required` condition (even negated, as e.g.: `-Not NodeName`)
      is considered optional
    * @AllowExtraNodes: when set, optional nodes are required at least once and any additional (undefined) node is
      unconditional excepted


#>

[Alias('Test-Object', 'tso')]
[CmdletBinding(DefaultParameterSetName = 'ResultList', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-ObjectGraph.md')][OutputType([String])] param(

    [Parameter(ParameterSetName='ValidateOnly', Mandatory = $true, ValueFromPipeLine = $True)]
    [Parameter(ParameterSetName='ResultList', Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Parameter(ParameterSetName='ValidateOnly', Mandatory = $true, Position = 0)]
    [Parameter(ParameterSetName='ResultList', Mandatory = $true, Position = 0)]
    $SchemaObject,

    [Parameter(ParameterSetName='ValidateOnly')]
    [Switch]$ValidateOnly,

    [Parameter(ParameterSetName='ResultList')]
    [Switch]$Elaborate,

    [Parameter(ParameterSetName='ValidateOnly')]
    [Parameter(ParameterSetName='ResultList')]
    $AssertPrefix = '@',

    [Parameter(ParameterSetName='ValidateOnly')]
    [Parameter(ParameterSetName='ResultList')]
    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)

begin {

# JsonSchema Properties
# Schema properties: [NewtonSoft.Json.Schema.JsonSchema]::New() | Get-Member
# https://www.newtonsoft.com/json/help/html/Properties_T_Newtonsoft_Json_Schema_JsonSchema.htm


    Enum UniqueType { None; Node; Match } # if a node isn't unique the related option isn't uniquely matched either
    Enum CompareType { Scalar; OneOf; AllOf }

    $Script:Ordinal = @{$false = [StringComparer]::OrdinalIgnoreCase; $true = [StringComparer]::Ordinal }

    function StopError($Exception, $Id = 'TestNode', $Category = [ErrorCategory]::SyntaxError, $Object) {
        if ($Exception -is [ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new($Exception, $Id, $Category, $Object))
    }

    function SchemaError($Message, $ObjectNode, $SchemaNode, $Object = $SchemaObject) {
        $Exception = [ArgumentException]"$($SchemaNode.Synopsys) $Message"
        $Exception.Data.Add('ObjectNode', $ObjectNode)
        $Exception.Data.Add('SchemaNode', $SchemaNode)
        StopError -Exception $Exception -Id 'SchemaError' -Category InvalidOperation -Object $Object
    }

    $LimitTests = [Ordered]@{
        ExclusiveMaximum  = 'The value is less than'
        Maximum           = 'The value is less than or equal to'
        ExclusiveMinimum  = 'The value is greater than'
        Minimum           = 'The value is greater than or equal to'
    }

    $MatchTests = [Ordered]@{
        Like      = 'The value is like'
        Match     = 'The value matches'
        NotLike   = 'The value is not like'
        NotMatch  = 'The value not matches'
    }

    $Script:Tests = [Ordered]@{
        Title           = 'Title'
        References      = 'Assert references'
        Type            = 'The node or value is of type'
        NotType         = 'The node or value is not type'
        CaseSensitive   = 'The (descendant) node are considered case sensitive'
        Required        = 'The node is required'
        Unique          = 'The node is unique'
    } +
    $LimitTests +
    $MatchTests +
    [Ordered]@{
        Ordered         = 'The nodes are in order'
        RequiredNodes   = 'The node contains the nodes'
        AllowExtraNodes = 'Allow undefined child nodes'
    }

    $At = @{}
    $Tests.Get_Keys().Foreach{ $At[$_] = "$($AssertPrefix)$_" }

    function ResolveReferences($Node) {
        if ($Node.Cache.ContainsKey('TestReferences')) { return }
        $Stack = [Stack]::new()
        while ($true) {
            $ParentNode = $Node.ParentNode
            if ($ParentNode -and -not $ParentNode.Cache.ContainsKey('TestReferences')) {
                $Stack.Push($Node)
                $Node = $ParentNode
                continue
            }
            $RefNode = if ($Node.Contains($At.References)) { $Node.GetChildNode($At.References) }
            $Node.Cache['TestReferences'] = [HashTable]::new($Ordinal[[Bool]$RefNode.IsCaseSensitive])
            if ($RefNode) {
                foreach ($ChildNode in $RefNode.ChildNodes) {
                    if (-not $Node.Cache['TestReferences'].ContainsKey($ChildNode.Name)) {
                        $Node.Cache['TestReferences'][$ChildNode.Name] = $ChildNode
                    }
                }
            }
            $ParentNode = $Node.ParentNode
            if ($ParentNode) {
                foreach ($RefName in $ParentNode.Cache['TestReferences'].get_Keys()) {
                    if (-not $Node.Cache['TestReferences'].ContainsKey($RefName)) {
                        $Node.Cache['TestReferences'][$RefName] = $ParentNode.Cache['TestReferences'][$RefName]
                    }
                }
            }
            if ($Stack.Count -eq 0) { break }
            $Node = $Stack.Pop()
        }
    }

    function MatchNode (
        [PSNode]$ObjectNode,
        [PSNode]$TestNode,
        [Switch]$ValidateOnly,
        [Switch]$Elaborate,
        [Switch]$Ordered,
        [Nullable[Bool]]$CaseSensitive,
        [Switch]$MatchAll,
        $MatchedNames
    ) {
        $Violates = $null
        $Name = $TestNode.Name

        $ChildNodes = $ObjectNode.ChildNodes
        if ($ChildNodes.Count -eq 0) { return }

        if ($TestNode -is [PSLeafNode]) {
            $ParentNode = $TestNode.ParentNode
            $References = if ($ParentNode) {
                if (-not $ParentNode.Cache.ContainsKey('TestReferences')) { ResolveReferences $ParentNode }
                $ParentNode.Cache['TestReferences']
            } else { @{} }
            if ($References.Contains($TestNode.Value)) {
                $AssertNode = $References[$TestNode.Value]
                $AssertNode.Cache['TestReferences'] = $References
            }
            else { SchemaError "Unknown reference: $($TestNode.Value)" $ObjectNode $TestNode }
        } else { $AssertNode = $TestNode }

        if ($ObjectNode -is [PSMapNode] -and $TestNode.NodeOrigin -eq 'Map') {
            if ($ObjectNode.Contains($Name)) {
                $ChildNode = $ObjectNode.GetChildNode($Name)
                if ($Ordered -and $ChildNodes.IndexOf($ChildNode) -ne $TestNodes.IndexOf($TestNode)) {
                    $Violates = "Node $Name should be in order"
                }
            } else { $ChildNode = $false }
        }
        elseif ($ChildNodes.Count -eq 1) { $ChildNode = $ChildNodes[0] }
        elseif ($Ordered) {
            $NodeIndex = $TestNodes.IndexOf($TestNode)
            if ($NodeIndex -ge $ChildNodes.Count) {
                $Violates = "Should contain at least $($TestNodes.Count) nodes"
            }
            $ChildNode = $ChildNodes[$NodeIndex]
        }
        else { $ChildNode = $null }

        if ($Violates) {
            if (-not $ValidateOnly) {
                $Output = [PSCustomObject]@{
                    ObjectNode = $ObjectNode
                    SchemaNode = $AssertNode
                    Valid      = -not $Violates
                    Condition  = $Condition
                }
                $Output.PSTypeNames.Insert(0, 'TestResult')
                $Output
            }
            return
        }
        else {
            if ($ChildNode -is [PSNode]) {
                $Violates = $Null
                $TestParams = @{
                    ObjectNode     = $ChildNode
                    SchemaNode     = $AssertNode
                    Elaborate     = $Elaborate
                    CaseSensitive  = $CaseSensitive
                    ValidateOnly   = $ValidateOnly
                    RefInvalidNode = [Ref]$Violates
                }
                TestNode @TestParams
                if (-not $Violates) { $null = $MatchedNames.Add($ChildNode.Name) }
            }
            elseif ($null -eq $ChildNode) {
                foreach ($ChildNode in $ChildNodes) {
                    if ($MatchedNames.Contains($ChildNode.Name)) { continue }
                    $Violates = $Null
                    $TestParams = @{
                        ObjectNode     = $ChildNode
                        SchemaNode     = $AssertNode
                        Elaborate     = $Elaborate
                        CaseSensitive  = $CaseSensitive
                        ValidateOnly   = $true
                        RefInvalidNode = [Ref]$Violates
                    }
                    TestNode @TestParams
                    if (-not $Violates) {
                        $null = $MatchedNames.Add($ChildNode.Name)
                        if (-not $MatchAll) { break }
                    }
                    elseif ($Elaborate) { $Violates }
                }
            }
            elseif ($ChildNode -eq $false) { $AssertResults[$Name] = $false }
            else { throw "Unexpected return reference: $ChildNode" }
        }
    }

    function TestNode (
        [PSNode]$ObjectNode,
        [PSNode]$SchemaNode,
        [Switch]$Elaborate,            # if set, include the failed test results in the output
        [Nullable[Bool]]$CaseSensitive, # inherited the CaseSensitivity from the parent node if not defined
        [Switch]$ValidateOnly,          # if set, stop at the first invalid node
        $RefInvalidNode                 # references the first invalid node
    ) {
        $CallStack = Get-PSCallStack
        # if ($CallStack.Count -gt 20) { Throw 'Call stack failsafe' }
        if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
            $Caller = $CallStack[1]
            Write-Host "$([ANSI]::ParameterColor)Caller (line: $($Caller.ScriptLineNumber))$([ANSI]::ResetColor):" $Caller.InvocationInfo.Line.Trim()
            Write-Host "$([ANSI]::ParameterColor)ObjectNode:$([ANSI]::ResetColor)" $ObjectNode.Path "$ObjectNode"
            Write-Host "$([ANSI]::ParameterColor)SchemaNode:$([ANSI]::ResetColor)" $SchemaNode.Path "$SchemaNode"
            Write-Host "$([ANSI]::ParameterColor)ValidateOnly:$([ANSI]::ResetColor)" ([Bool]$ValidateOnly)
        }

        if ($SchemaNode -is [PSListNode] -and $SchemaNode.Count -eq 0) { return } # Allow any node

        $Value = $ObjectNode.Value
        $RefInvalidNode.Value = $null

        # Separate the assert nodes from the schema subnodes
        $AssertNodes = [Ordered]@{} # $AssertNodes{<Assert Test name>] = $ChildNodes.@<Assert Test name>
        if ($SchemaNode -is [PSMapNode]) {
            $TestNodes = [List[PSNode]]::new()
            foreach ($Node in $SchemaNode.ChildNodes) {
                if ($Node.Name.StartsWith($AssertPrefix)) {
                    $TestName = $Node.Name.SubString($AssertPrefix.Length)
                    if ($TestName -notin $Tests.Keys) { SchemaError "Unknown assert: '$($Node.Name)'" $ObjectNode $SchemaNode }
                    $AssertNodes[$TestName] = $Node
                }
                else { $TestNodes.Add($Node) }
            }
        }
        elseif ($SchemaNode -is [PSListNode]) { $TestNodes = $SchemaNode.ChildNodes }
        else { $TestNodes = @() }

        if ($AssertNodes.Contains('CaseSensitive')) { $CaseSensitive = [Nullable[Bool]]$AssertNodes['CaseSensitive'] }

#Region Node validation

        $RefInvalidNode.Value = $false
        $MatchedNames = [HashSet[Object]]::new()
        $AssertResults = $Null
        foreach ($TestName in $AssertNodes.get_Keys()) {
            $AssertNode = $AssertNodes[$TestName]
            $Criteria = $AssertNode.Value
            $Violates = $null # is either a boolean ($true if invalid) or a string with what was expected
            if ($TestName -eq 'Title') { $Null }
            elseif ($TestName -eq 'References') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = "The '$($AssertNode.Name)' assert requires a collection node"
                }
            }
            elseif ($TestName -in 'Type', 'notType') {
                $FoundType = foreach ($TypeName in $Criteria) {
                    if ($TypeName -in $null, 'Null', 'Void') {
                        if ($null -eq $Value) { $true; break }
                    }
                    elseif ($TypeName -is [Type]) { $Type = $TypeName } else {
                        $Type = $TypeName -as [Type]
                        if (-not $Type) {
                            SchemaError "Unknown type: $TypeName" $ObjectNode $SchemaNode
                        }
                    }
                    if ($ObjectNode -is $Type -or $Value -is $Type) { $true; break }
                }
                $Violates = $null -eq $FoundType -xor $TestName -eq 'notType'
            }
            elseif ($TestName -eq 'CaseSensitive') {
                if ($null -ne $Criteria -and $Criteria -isnot [Bool]) {
                    SchemaError "Invalid case sensitivity value: $Criteria" $ObjectNode $SchemaNode
                }
            }
            elseif ($TestName -eq 'ExclusiveMinimum') {
                $Violates =
                    if     ($CaseSensitive -eq $true)  { $Criteria -cge $Value }
                    elseif ($CaseSensitive -eq $false) { $Criteria -ige $Value }
                    else                               { $Criteria -ge  $Value }
            }
            elseif ($TestName -eq 'Minimum') {
                $Violates =
                    if     ($CaseSensitive -eq $true)  { $Criteria -cgt $Value }
                    elseif ($CaseSensitive -eq $false) { $Criteria -igt $Value }
                    else                               { $Criteria -gt  $Value }
            }
            elseif ($TestName -eq 'ExclusiveMaximum') {
                $Violates =
                    if     ($CaseSensitive -eq $true)  { $Criteria -cle $Value }
                    elseif ($CaseSensitive -eq $false) { $Criteria -ile $Value }
                    else                               { $Criteria -le  $Value }
            }
            elseif ($TestName -eq 'Maximum') {
                $Violates =
                    if     ($CaseSensitive -eq $true)  { $Criteria -clt $Value }
                    elseif ($CaseSensitive -eq $false) { $Criteria -ilt $Value }
                    else                               { $Criteria -lt  $Value }
            }

            elseif ($TestName -in 'Like', 'NotLike', 'Match', 'NotMatch') {
                $Negate = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                foreach ($x in $Value) {
                    $Match = $false
                    foreach ($AnyCriteria in $Criteria) {
                        $Match = if ($TestName.EndsWith('Like', 'OrdinalIgnoreCase')) {
                            if     ($true -eq $CaseSensitive)  { $x -cLike  $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $x -iLike  $AnyCriteria }
                            else                               { $x -Like   $AnyCriteria }
                        }
                        else { # if ($TestName.EndsWith('Match', 'OrdinalIgnoreCase')) {
                            if     ($true -eq $CaseSensitive)  { $x -cMatch $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $x -iMatch $AnyCriteria }
                            else                               { $x -Match  $AnyCriteria }
                        }
                        if ($Match) { break }
                    }
                    $Violates = -not $Match -xor $Negate
                    if ($Violates) { break }
                }
            }
            elseif ($TestName -eq 'Required') { }
            elseif ($TestName -eq 'Unique') {
                $ParentNode = $ObjectNode.ParentNode
                if (-not $ParentNode) {
                    SchemaError "The unique assert can't be used on a root node" $ObjectNode $SchemaNode
                }
                $ObjectComparer = [ObjectComparer]::new([ObjectComparison][Int][Bool]$CaseSensitive)
                foreach ($SiblingNode in $ParentNode.ChildNodes) {
                    if ($ObjectNode.Name -ceq $SiblingNode.Name) { continue } # Self
                    if ($ObjectComparer.IsEqual($ObjectNode, $SiblingNode)) {
                        $Violates = $true
                        break
                    }
                }
            }
            elseif ($TestName -eq 'AllowExtraNodes') {}
            elseif ($TestName -in 'Ordered', 'RequiredNodes') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = "The '$($AssertNode.Name)' assert requires a collection node"
                }
            }
            else { SchemaError "Unknown assert node: $TestName" $ObjectNode $SchemaNode }

            if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
                if (-not $Violates) { Write-Host -ForegroundColor Green "Valid: $TestName $Criteria" }
                else { Write-Host -ForegroundColor Red "Invalid: $TestName $Criteria" }
            }

            if ($Violates -or $Elaborate) {
                $Condition =
                    if ($Violates -is [String]) { $Violates }
                    elseif ($Criteria -eq $true) { $($Tests[$TestName]) }
                    else { "$($Tests[$TestName]) $(@($Criteria).foreach{ [PSSerialize]$_ } -Join ', ')" }
                $Output = [PSCustomObject]@{
                    ObjectNode = $ObjectNode
                    SchemaNode = $SchemaNode
                    Valid      = -not $Violates
                    Condition  = $Condition
                }
                $Output.PSTypeNames.Insert(0, 'TestResult')
                if ($Violates) {
                    $RefInvalidNode.Value = $Output
                    if ($ValidateOnly) { return }
                }
                if (-not $ValidateOnly -or $Elaborate) { <# Write-Output #> $Output }
            }
        }

#EndRegion Node validation

        if ($Violates) { return }

#Region Required nodes

        $ChildNodes = $ObjectNode.ChildNodes

        if ($TestNodes.Count -and -not $AssertNodes.Contains('Type')) {
            if ($SchemaNode -is [PSListNode] -and $ObjectNode -isnot [PSListNode]) {
                $Violates = 'Expected a list node'
            }
            if ($SchemaNode -is [PSMapNode] -and $ObjectNode -isnot [PSMapNode]) {
                $Violates = 'Expected a map node'
            }
        }

        if (-Not $Violates) {
            $RequiredNodes = $AssertNodes['RequiredNodes']
            $CaseSensitiveNames = if ($ObjectNode -is [PSMapNode]) { $ObjectNode.IsCaseSensitive }
            $AssertResults = [HashTable]::new($Ordinal[[Bool]$CaseSensitiveNames])

            if ($RequiredNodes) { $RequiredList = [List[Object]]$RequiredNodes.Value } else { $RequiredList = [List[Object]]::new() }
            foreach ($TestNode in $TestNodes) {
                if ($TestNode -is [PSMapNode] -and $TestNode.GetValue($At.Required)) { $RequiredList.Add($TestNode.Name) }
            }

            foreach ($Requirement in $RequiredList) {
                $LogicalFormula = [LogicalFormula]$Requirement
                $Enumerator = $LogicalFormula.Terms.GetEnumerator()
                $Stack = [Stack]::new()
                $Stack.Push(@{
                    Enumerator  = $Enumerator
                    Accumulator = $null
                    Operator    = $null
                    Negate      = $null
                })
                $Term, $Operand, $Accumulator = $null
                While ($Stack.Count -gt 0) {
                    # Accumulator = Accumulator <operation> Operand
                    # if ($Stack.Count -gt 20) { Throw 'Formula stack failsafe'}
                    $Pop         = $Stack.Pop()
                    $Enumerator  = $Pop.Enumerator
                    $Operator    = $Pop.Operator
                    if ($null -eq $Operator) { $Operand = $Pop.Accumulator }
                    else { $Operand, $Accumulator = $Accumulator, $Pop.Accumulator }
                    $Negate      = $Pop.Negate
                    $Compute = $null -notin $Operand, $Operator, $Accumulator
                    while ($Compute -or $Enumerator.MoveNext()) {
                        if ($Compute) { $Compute = $false}
                        else {
                            $Term = $Enumerator.Current
                            if ($Term -is [LogicalVariable]) {
                                $Name = $Term.Value
                                if (-not $AssertResults.ContainsKey($Name)) {
                                    if (-not $SchemaNode.Contains($Name)) {
                                        SchemaError "Unknown test node: $Term" $ObjectNode $SchemaNode
                                    }
                                    $MatchCount0 = $MatchedNames.Count
                                    $MatchParams = @{
                                        ObjectNode    = $ObjectNode
                                        TestNode      = $SchemaNode.GetChildNode($Name)
                                        Elaborate    = $Elaborate
                                        ValidateOnly  = $ValidateOnly
                                        Ordered       = $AssertNodes['Ordered']
                                        CaseSensitive = $CaseSensitive
                                        MatchAll      = $false
                                        MatchedNames  = $MatchedNames
                                    }
                                    MatchNode @MatchParams
                                    $AssertResults[$Name] = $MatchedNames.Count -gt $MatchCount0
                                }
                                $Operand = $AssertResults[$Name]
                            }
                            elseif ($Term -is [LogicalOperator]) {
                                if ($Term.Value -eq 'Not') { $Negate = -Not $Negate }
                                elseif ($null -eq $Operator -and $null -ne $Accumulator) { $Operator = $Term.Value }
                                else { SchemaError "Unexpected operator: $Term" $ObjectNode $SchemaNode }
                            }
                            elseif ($Term -is [LogicalFormula]) {
                                $Stack.Push(@{
                                    Enumerator  = $Enumerator
                                    Accumulator = $Accumulator
                                    Operator    = $Operator
                                    Negate      = $Negate
                                })
                                $Accumulator, $Operator, $Negate = $null
                                $Enumerator  = $Term.Terms.GetEnumerator()
                                continue
                            }
                            else { SchemaError "Unknown logical operator term: $Term" $ObjectNode $SchemaNode }
                        }
                        if ($null -ne $Operand) {
                            if ($null -eq $Accumulator -xor $null -eq $Operator) {
                                if ($Accumulator) { SchemaError "Missing operator before: $Term" $ObjectNode $SchemaNode }
                                else { SchemaError "Missing variable before: $Operator $Term" $ObjectNode $SchemaNode }
                            }
                            $Operand = $Operand -Xor $Negate
                            $Negate = $null
                            if ($Operator -eq 'And') {
                                $Operator = $null
                                if ($Accumulator -eq $false -and -not $AssertNodes['AllowExtraNodes']) { break }
                                $Accumulator = $Accumulator -and $Operand
                            }
                            elseif ($Operator -eq 'Or') {
                                $Operator = $null
                                if ($Accumulator -eq $true -and -not $AssertNodes['AllowExtraNodes']) { break }
                                $Accumulator = $Accumulator -Or $Operand
                            }
                            elseif ($Operator -eq 'Xor') {
                                $Operator = $null
                                $Accumulator = $Accumulator -xor $Operand
                            }
                            else { $Accumulator = $Operand }
                            $Operand = $Null
                        }
                    }
                    if ($null -ne $Operator -or $null -ne $Negate) {
                        SchemaError "Missing variable after $Operator" $ObjectNode $SchemaNode
                    }
                }
                if ($Accumulator -eq $False) {
                    $Violates = "Meets the conditions of the nodes $LogicalFormula"
                    break
                }
            }
        }

#EndRegion Required nodes

#Region Optional nodes

        if (-not $Violates) {

            foreach ($TestNode in $TestNodes) {
                if ($MatchedNames.Count -ge $ChildNodes.Count) { break }
                if ($AssertResults.Contains($TestNode.Name)) { continue }
                $MatchCount0 = $MatchedNames.Count
                $MatchParams = @{
                    ObjectNode    = $ObjectNode
                    TestNode      = $TestNode
                    Elaborate    = $Elaborate
                    ValidateOnly  = $ValidateOnly
                    Ordered       = $AssertNodes['Ordered']
                    CaseSensitive = $CaseSensitive
                    MatchAll      = -not $AssertNodes['AllowExtraNodes']
                    MatchedNames  = $MatchedNames
                }
                MatchNode @MatchParams
                if ($AssertNodes['AllowExtraNodes'] -and $MatchedNames.Count -eq $MatchCount0) {
                    $Violates = "When extra nodes are allowed, the node $($TestNode.Name) should be accepted"
                    break
                }
                $AssertResults[$TestNode.Name] = $MatchedNames.Count -gt $MatchCount0
            }

            if (-not $AssertNodes['AllowExtraNodes'] -and $MatchedNames.Count -lt $ChildNodes.Count) {
                $Extra = $ChildNodes.Name.where{ -not $MatchedNames.Contains($_) }.foreach{ [PSSerialize]$_ } -Join ', '
                $Violates = "All the child nodes should be accepted, including the nodes: $Extra"
            }
        }

#EndRegion Optional nodes

        if ($Violates -or $Elaborate) {
            $Output = [PSCustomObject]@{
                ObjectNode = $ObjectNode
                SchemaNode = $SchemaNode
                Valid      = -not $Violates
                Condition  = if ($Violates) { $Violates } else { 'All the child nodes should be accepted'}
            }
            $Output.PSTypeNames.Insert(0, 'TestResult')
            if ($Violates) { $RefInvalidNode.Value = $Output }
            if (-not $ValidateOnly -or $Elaborate) { <# Write-Output #> $Output }
        }
    }

    $SchemaNode = [PSNode]::ParseInput($SchemaObject)
}

process {
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    $Invalid = $Null
    $TestParams = @{
        ObjectNode     = $ObjectNode
        SchemaNode     = $SchemaNode
        Elaborate     = $Elaborate
        ValidateOnly   = $ValidateOnly
        RefInvalidNode = [Ref]$Invalid
    }
    TestNode @TestParams
    if ($ValidateOnly) { -not $Invalid }

}

