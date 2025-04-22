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

.EXAMPLE
    # Parse a object graph to a node instance

    The following example parses a hash table to `[PSNode]` instance:

        @{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node

        PathName Name Depth Value
        -------- ---- ----- -----
                          0 {My, Object}

.PARAMETER InputObject
    The input object that will be compared with the reference object (see: [-Reference] parameter).

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
    [Switch]$IncludeValid,

    [Parameter(ParameterSetName='ResultList')]
    [Switch]$IncludeLatent,

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

    $Ordinal = @{$false = [StringComparer]::OrdinalIgnoreCase; $true = [StringComparer]::Ordinal }

    function StopError($Exception, $Id = 'TestObject', $Category = [ErrorCategory]::SyntaxError, $Object) {
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

    # $LimitTests = [Ordered]@{
    #     ExclusiveMaximum  = 'The value is less than'
    #     cExclusiveMaximum = 'The value is (case sensitive) less than'
    #     iExclusiveMaximum = 'The value is (case insensitive) less than'
    #     Maximum           = 'The value is less than or equal to'
    #     cMaximum          = 'The value is (case sensitive) less than or equal to'
    #     iMaximum          = 'The value is (case insensitive) less than or equal to'
    #     ExclusiveMinimum  = 'The value is greater than'
    #     cExclusiveMinimum = 'The value is (case sensitive) greater than'
    #     iExclusiveMinimum = 'The value is (case insensitive) greater than'
    #     Minimum           = 'The value is greater than or equal to'
    #     cMinimum          = 'The value is (case sensitive) greater than or equal to'
    #     iMinimum          = 'The value is (case insensitive) greater than or equal to'
    # }

    # $MatchTests = [Ordered]@{
    #     Like      = 'The value is like'
    #     iLike     = 'The value is (case insensitive) like'
    #     cLike     = 'The value is (case sensitive) like'
    #     Match     = 'The value matches'
    #     iMatch    = 'The value (case insensitive) matches'
    #     cMatch    = 'The value (case sensitive) matches'
    #     NotLike   = 'The value is not like'
    #     iNotLike  = 'The value is not (case insensitive) like'
    #     cNotLike  = 'The value is not (case sensitive) like'
    #     NotMatch  = 'The value not matches'
    #     iNotMatch = 'The value not (case insensitive) matches'
    #     cNotMatch = 'The value not (case sensitive) matches'
    # }

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

    $Tests = [Ordered]@{
        Title          = 'Title'
        References     = 'Assert references'
        Type           = 'The node or value is of type'
        NotType        = 'The node or value is not type'
        CaseSensitive  = 'The (descendant) node are considered case sensitive'
        Unique         = 'The node is unique'
        Exclusive      = 'The assert is exclusive'
    } +
    $LimitTests +
    $MatchTests +
    [Ordered]@{
        Ordered        = 'The nodes are in order'
        RequiredNodes  = 'The node contains the nodes'
        DenyExtraNodes = 'There no additional nodes left over'
    }

    function TestObject (
        [PSNode]$ObjectNode,
        [PSNode]$SchemaNode,
        [Switch]$IncludeValid,          # if set, include the valid test results in the output
        [Switch]$IncludeLatent,         # if set, include the failed test results in the output
        [Nullable[Bool]]$CaseSensitive, # inherited the CaseSensitivity from the parent node if not defined
        [Switch]$ValidateOnly,
        $RefValid
    ) {
        $CallStack = Get-PSCallStack
        # if ($CallStack.Count -gt 20) { Throw 'Call stack failsafe' }
        if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
            $Caller = $CallStack[1]
            Write-Host "$([ANSI]::ParameterColor)Caller (line: $($Caller.ScriptLineNumber))$([ANSI]::ResetColor):" $Caller.InvocationInfo.Line.Trim()
            Write-Host "$([ANSI]::ParameterColor)ObjectNode:$([ANSI]::ResetColor)" $ObjectNode.Path "$ObjectNode"
            Write-Host "$([ANSI]::ParameterColor)SchemaNode:$([ANSI]::ResetColor)" $SchemaNode.Path "$SchemaNode"
            Write-Host "$([ANSI]::ParameterColor)ValidOnly:$([ANSI]::ResetColor)" ([Bool]$ValidateOnly)
        }

        $Value = $ObjectNode.Value

        # Separate the assert nodes from the schema subnodes
        $AssertNodes = [Ordered]@{}
        if ($SchemaNode -is [PSMapNode]) {
            $TestNodes = [List[PSNode]]::new()
            foreach ($Node in $SchemaNode.ChildNodes) {
                if ($Node.Name.StartsWith($AssertPrefix)) { $AssertNodes[$Node.Name.SubString(1)] = $Node.Value }
                else { $TestNodes.Add($Node) }
            }
        }
        elseif ($SchemaNode -is [PSListNode]) { $TestNodes = $SchemaNode.ChildNodes }
        else { $TestNodes = @() }

        # Define the required nodes if not already defined
        if (-not $AssertNodes.Contains('RequiredNodes') -and $ObjectNode -is [PSCollectionNode]) {
            $AssertNodes['RequiredNodes'] = $TestNodes.Name
        }

        if ($AssertNodes.Contains('CaseSensitive')) {
            $CaseSensitive = [Nullable[Bool]]$AssertNodes['CaseSensitive']
        }
        $DenyExtraNodes = $AssertNodes['DenyExtraNodes']
        $Ordered = $AssertNodes['Ordered']

        $RefValid.Value = $true
        $ChildNodes = $AssertResults = $Null
        foreach ($TestName in $Tests.Keys) {
            if ($TestName -notin $AssertNodes.Keys) { continue }

            if ($TestName -notin $Tests.Keys) { SchemaError "Unknown test name: $TestName" $ObjectNode $SchemaNode }
            $Criteria = $AssertNodes[$TestName]
            $Violates = $null # is either a boolean ($true if invalid) or a string with what was expected
            if ($TestName -eq 'Title') { $Null }
            elseif ($TestName -in 'Type', 'notType') {
                $FoundType = foreach ($TypeName in $Criteria) {
                    if ($TypeName -in $null, 'Null', 'Void' -and $null -eq $Value) { $true; break }
                    if ($TypeName -is [Type]) { $Type = $TypeName } else {
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
                $Match = foreach ($AnyCriteria in $Criteria) {
                    $IsMatch = if ($TestName.EndsWith('Like', 'OrdinalIgnoreCase')) {
                        if     ($true -eq $CaseSensitive)  { $Value -cLike  $AnyCriteria }
                        elseif ($false -eq $CaseSensitive) { $Value -iLike  $AnyCriteria }
                        else                               { $Value -Like   $AnyCriteria }
                    }
                    else { # if ($TestName.EndsWith('Match', 'OrdinalIgnoreCase')) {
                        if     ($true -eq $CaseSensitive)  { $Value -cMatch $AnyCriteria }
                        elseif ($false -eq $CaseSensitive) { $Value -iMatch $AnyCriteria }
                        else                               { $Value -Match  $AnyCriteria }
                    }
                    if ($IsMatch) { $true; break }
                }
                $Violates = -not $Match -xor $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
            }

            elseif ($TestName -eq 'Unique') {
                $ParentNode = $ObjectNode.ParentNode
                if ($ParentNode -isnot [PSCollectionNode]) {
                    $Violates = 'The unique assert requires a child node'
                }
                else {
                    $ObjectComparer = [ObjectComparer]::new([ObjectComparison][Int][Bool]$CaseSensitive)
                    foreach ($SiblingNode in $ParentNode.ChildNodes) {
                        if ($ObjectNode.Name -ceq $SiblingNode.Name) { continue } # Self
                        if ($ObjectComparer.IsEqual($ObjectNode, $SiblingNode)) {
                            $Violates = $true
                            break
                        }
                    }
                }
            }
            elseif ($TestName -eq 'Exclusive') { # the assert exclusivity is handled by the parent node
                if ($ObjectNode.ParentNode -isnot [PSCollectionNode]) {
                    $Violates = 'The exclusive assert requires a collection item'
                }
            }
            elseif ($TestName -eq 'Ordered') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = 'The ordered assert requires a collection node'
                }
            }

            elseif ($TestName -eq 'RequiredNodes') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = 'The requires assert requires a collection node'
                }
                else {
                    $ChildNodes = $ObjectNode.ChildNodes
                    $IsStrictCase = if ($ObjectNode -is [PSMapNode]) {
                        foreach ($ChildNode in $ChildNodes) {
                            $Name = $ChildNode.Name
                            $IsStrictCase = if ($Name -is [String] -and $Name -match '[a-z]') {
                                $Case = $Name.ToLower()
                                if ($Case -eq $Name) { $Case = $Name.ToUpper() }
                                -not $ObjectNode.Contains($Case) -or $ObjectNode.GetChildNode($Case).Name -ceq $Case
                                break
                            }
                        }
                    } elseif ($ObjectNode -is [PSCollectionNode]) { $false } else { $null }

                    $AssertResults = [HashTable]::new($Ordinal[[Bool]$IsStrictCase])
                    $ValidNodes = [HashSet[Object]]::new()
                    foreach ($Condition in $Criteria) {
                        $Term, $Accumulator, $Operand, $Operation, $Negate = $null
                        $LogicalFormula = [LogicalFormula]$Condition
                        $Enumerator = $LogicalFormula.Terms.GetEnumerator()
                        $Stack = [System.Collections.Stack]::new()
                        $Stack.Push(@{
                            Enumerator  = $Enumerator
                            Accumulator = $Null
                            Operator    = $Null
                            Negate      = $Null
                        })
                        $Accumulator = $Null
                        While ($Stack.Count -gt 0) {     # Accumulator = Accumulator <operation> Operand
                            if ($Stack.Count -gt 20) { Throw 'Formula stack failsafe'}
                            $Operand     = $Accumulator  # Resulted from sub expression
                            $Pop         = $Stack.Pop()
                            $Enumerator  = $Pop.Enumerator
                            $Accumulator = $Pop.Accumulator
                            $Operator    = $Pop.Operator
                            $Negate      = $Pop.Negate
                            while ($Enumerator.MoveNext()) {
                                $Term = $Enumerator.Current
                                if ($Term -is [LogicalVariable]) {
                                    $Name = $Term.Value
                                    if (-not $AssertResults.ContainsKey($Name)) {
                                        if (-not $SchemaNode.Contains($Name)) {
                                            SchemaError "Unknown test node: $Term" $ObjectNode $SchemaNode
                                        }
                                        $TestNode = $SchemaNode.GetChildNode($Name)
                                        $Name = $TestNode.Name # get the exact node name
                                        $Mapped = $ObjectNode -is [PSMapNode] -and $SchemaNode -is [PSMapNode]
                                        if ($Mapped -or $Ordered) {
                                            $ChildNode = $Null
                                            if ($Mapped) {
                                                if ($ObjectNode.Contains($Name)) {
                                                    $ChildNode = $ObjectNode.GetChildNode($Name)
                                                    if ($Ordered -and $ChildNodes.IndexOf($ChildNode) -ne $TestNodes.IndexOf($TestNode)) {
                                                        $Violates = "Node $Name should be in order"
                                                        $Stack.Clear(); break
                                                    }
                                                }
                                            }
                                            else {
                                                $TestNodeIndex = $TestNodes.IndexOf($TestNode)
                                                if ($TestNodeIndex -ge $ChildNodes.Count) {
                                                    $Violates = "Should contain at least $($TestNodes.Count) nodes"
                                                    $Stack.Clear(); break
                                                }
                                                $ChildNode = $ChildNodes[$NodeIndex]
                                            }
                                            if ($ChildNode) {
                                                $Valid = $Null
                                                $TestParams = @{
                                                    ObjectNode    = $ChildNode
                                                    SchemaNode    = $TestNode
                                                    IncludeValid  = $IncludeValid
                                                    IncludeLatent = $IncludeLatent
                                                    CaseSensitive = $CaseSensitive
                                                    ValidateOnly  = $ValidateOnly
                                                    RefValid      = [Ref]$Valid
                                                }
                                                TestObject @TestParams
                                                $AssertResults[$Name] = $Valid
                                            }
                                            else { $AssertResults[$Name] = $false }
                                        }
                                        else {
                                            $RestNames      = $AssertNodes.where{ -not $AssertResults.Contains($_.Name) }
                                            $UniqueNames    = $RestNames.where{ $AssertNodes[$_].GetValue('@Unique') }
                                            $ExclusiveNames = $RestNames.where{ $AssertNodes[$_].GetValue('@Exclusive') }
                                            if ($UniqueNames -or $ExclusiveNames) {
                                                $CheckNames = [List[String]]::new($UniqueNames)
                                                $ExclusiveNames.foreach{ if ($_ -notin $CheckNames) { $CheckNames.Add($_) } }
                                                $RestNames.foreach{ if ($_ -notin $CheckNames) { $CheckNames.Add($_) } }
                                            } else { $CheckNames = $ChildNodes.Name }
                                            $Found = $null
                                            $CountUnique = if ($UniqueNames) { @{} }
                                            $CountExclusive = if ($ExclusiveNames) { @{} }
                                            $CountNodes = $CountUnique -or $CountExclusive
                                            foreach ($ChildNode in $AssertNodes.get_Keys()) {

                                                if ($TestNode.GetValue('@Unique') -or $TestNode.GetValue('@Exclusive')) { continue }
                                                $Valid = $Null
                                                $TestParams = @{
                                                    ObjectNode    = $ChildNode
                                                    SchemaNode    = $TestNode
                                                    IncludeValid  = $IncludeValid
                                                    IncludeLatent = $IncludeLatent
                                                    CaseSensitive = $CaseSensitive
                                                    ValidateOnly  = $true
                                                    RefValid      = [Ref]$Valid
                                                }
                                                TestObject @TestParams
                                                if ($Valid) {
                                                    if ($CountNodes) {
                                                        if ($CountUnique) { $CountUnique[$ChildNode] += 1 }
                                                        if ($CountExclusive) { $CountExclusive[$ChildNode] += 1 }
                                                    } else { $Found = $ChildNode; break }
                                                }
                                            }
                                            if ($CountNodes) {
                                                foreach ($CheckNode in $CheckNames) {
                                                    $Found = $CheckNode
                                                    if ($CountUnique -and $CountUnique[$CheckNode] -ne 1) { $Found = $null }
                                                    if ($CountExclusive -and $CountExclusive[$CheckNode] -ne 1) { $Found = $null }
                                                    if ($Found) { break }
                                                }
                                            }
                                            if ($Found) {
                                                $AssertResults[$Name] = $true
                                                $null = $ValidNodes.Add($Found)
                                            } else { $AssertResults[$Name] = $false }
                                        }
                                    }
                                    $Operand = $AssertResults[$Name]
                                }
                                elseif ($Term -is [LogicalOperator]) {
                                    if ($Term -eq 'Not') { $Negate = -Not $Negate }
                                    if (
                                        $null -ne $Operation -or $null -eq $Accumulator) {
                                        SchemaError "Unexpected operator: $Term" $ObjectNode $SchemaNode
                                    }

                                }
                                elseif ($Term -is [List[Object]]) {
                                    $Stack.Push(@{
                                        Enumerator  = $Enumerator
                                        Accumulator = $Accumulator
                                        Operator    = $Operator
                                        Negate      = $Negate
                                    })
                                    $Accumulator = $null
                                    $Enumerator  = $Term.GetEnumerator()
                                    break
                                }
                                else { SchemaError "Unknown logical operator term: $Term" $ObjectNode $SchemaNode }
                                if ($null -ne $Operand) {
                                    if ($null -eq $Accumulator -xor $null -eq $Operator) {
                                        if ($Accumulator) { SchemaError "Missing operator before: $Term" $ObjectNode $SchemaNode }
                                        else { SchemaError "Missing variable before: $Operator $Term" $ObjectNode $SchemaNode }
                                    }
                                    $Operand = $Operand -Xor $Negate
                                    if ($Operator -eq 'And') {
                                        if (-not $DenyExtraNodes -and $Accumulator -eq $false) { break }
                                        $Accumulator = $Accumulator -and $Operand
                                    }
                                    elseif ($Operator -eq 'Or') {
                                        if (-not $DenyExtraNodes -and $Accumulator -eq $true) { break }
                                        $Accumulator = $Accumulator -Or $Operand
                                    }
                                    elseif ($Operator -eq 'Xor') {
                                        $Accumulator = $Accumulator -xor $Operand
                                    }
                                    else { $Accumulator = $Operand }
                                    $Operand, $Operator, $Negate = $Null
                                }
                            }
                            if ($null -ne $Operator -or $null -ne $Negate) {
                                SchemaError "Missing variable after $Term" $ObjectNode $SchemaNode
                            }
                        }
                        if ($Accumulator -eq $False) {
                            $Violates = "Meets the conditions of the nodes $LogicalFormula"
                            if ($ValidateOnly) { continue }
                        }
                    }
                }
            }
            elseif ($AssertNodes['DenyExtraNodes']) {
                $ChildNames = if ($ChildNodes) { $ChildNodes.Name } else { $ObjectNode.ChildNodes.Name }
                $ResultNames = if ($AssertResults) { $AssertResults.get_Keys() }
                if ($ResultNames.Count -lt $ChildNames.Count) {
                    $Extra = $ChildNames.where{ $ResultNames -cne $_ }.foreach{ [PSSerialize]$_ } -Join ', '
                    $Violates = "Deny the extra node(s): $Extra"
                }
            }
            else { SchemaError "Unknown assert node: $TestName" $ObjectNode $SchemaNode }

            $RefValid.Value = -not $Violates
            if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
                if ($RefValid.Value) { Write-Host -ForegroundColor Green "Valid: $TestName $Criteria" }
                else { Write-Host -ForegroundColor Red "Invalid: $TestName $Criteria" }
            }

            if ($IncludeLatent -or ($Violates -and -not $ValidateOnly) -or ($RefValid.Value -and $IncludeValid)) {
                $Condition =
                    if ($Violates -is [String]) { $Violates }
                    elseif ($Criteria -eq $true) { $($Tests[$TestName])}
                    else { "$($Tests[$TestName]) $(@($Criteria).foreach{ [PSSerialize]$_ } -Join ', ')" }
                $Output = [PSCustomObject]@{
                    ObjectNode = $ObjectNode
                    SchemaNode = $SchemaNode
                    Valid      = $RefValid.Value
                    Condition  = $Condition
                }
                $Output.PSTypeNames.Insert(0, 'TestResultTable')
                Write-Output $Output
            }
            if ($ValidateOnly) { if ($RefValid.Value) { continue } else { return } }
        }
    }

    $SchemaNode = [PSNode]::ParseInput($SchemaObject)
}

process {
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    $Valid = $Null
    $TestParams = @{
        ObjectNode    = $ObjectNode
        SchemaNode    = $SchemaNode
        IncludeValid  = $IncludeValid
        IncludeLatent = $IncludeLatent
        CaseSensitive = $CaseSensitive
        ValidateOnly  = $ValidateOnly
        RefValid      = [Ref]$Valid
    }
    TestObject @TestParams
    if ($ValidateOnly) { $Valid }
}
