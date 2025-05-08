using module .\..\..\..\ObjectGraphTools

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

The schema object has the following major features:

* Independent of the object notation (as e.g. [Json (JavaScript Object Notation)][2] or [PowerShell Data Files][3])
* Each test node is at the same level as the input node being validated
* Complex node requirements (as mutual exclusive nodes) might be selected using a logical formula

.EXAMPLE
#Test whether a `$Person` object meats the schema requirements.

    $Person = [PSCustomObject]@{
        FirstName = 'John'
        LastName  = 'Smith'
        IsAlive   = $True
        Birthday  = [DateTime]'Monday,  October 7,  1963 10:47:00 PM'
        Age       = 27
        Address   = [PSCustomObject]@{
            Street     = '21 2nd Street'
            City       = 'New York'
            State      = 'NY'
            PostalCode = '10021-3100'
        }
        Phone = @{
            Home   = '212 555-1234'
            Mobile = '212 555-2345'
            Work   = '212 555-3456', '212 555-3456', '646 555-4567'
        }
        Children = @('Dennis', 'Stefan')
        Spouse = $Null
    }

    $Schema = @{
        FirstName = @{ '@Type' = 'String' }
        LastName  = @{ '@Type' = 'String' }
        IsAlive   = @{ '@Type' = 'Bool' }
        Birthday  = @{ '@Type' = 'DateTime' }
        Age       = @{
            '@Type' = 'Int'
            '@Minimum' = 0
            '@Maximum' = 99
        }
        Address = @{
            '@Type' = 'PSMapNode'
            Street     = @{ '@Type' = 'String' }
            City       = @{ '@Type' = 'String' }
            State      = @{ '@Type' = 'String' }
            PostalCode = @{ '@Type' = 'String' }
        }
        Phone = @{
            '@Type' = 'PSMapNode',  $Null
            Home    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
            Mobile  = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
            Work    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
        }
        Children  = @(@{ '@Type' = 'String', $Null })
        Spouse    = @{ '@Type' = 'String', $Null }
    }

    $Person | Test-Object $Schema | Should -BeNullOrEmpty

.PARAMETER InputObject
Specifies the object to test for validity against the schema object.
The object might be any object containing embedded (or even recursive) lists, dictionaries, objects or scalar
values received from a application or an object notation as Json or YAML using their related `ConvertFrom-*`
cmdlets.

.PARAMETER SchemaObject
Specifies a schema to validate the JSON input against. By default, if any discrepancies, toy will be reported
in a object list containing the path to failed node, the value whether the node is valid or not and the issue.
If no issues are found, the output is empty.

For details on the schema object, see the [schema object definitions][1] documentation.

.PARAMETER ValidateOnly

If set, the cmdlet will stop at the first invalid node and return the test result object.

.PARAMETER Elaborate

If set, the cmdlet will return the test result object for all tested nodes, even if they are valid
or ruled out in a possible list node branch selection.

.PARAMETER AssertTestPrefix

The prefix used to identify the assert test nodes in the schema object. By default, the prefix is `AssertTestPrefix`.

.PARAMETER MaxDepth

The maximal depth to recursively test each embedded node.
The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/SchemaObject.md "Schema object definitions"

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
    [ValidateNotNullOrEmpty()][String]$AssertTestPrefix = 'AssertTestPrefix',

    [Parameter(ParameterSetName='ValidateOnly')]
    [Parameter(ParameterSetName='ResultList')]
    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)

begin {

    $Script:Yield = {
        $Name = "$Args" -Replace '\W'
        $Value = Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue
        if ($Value) { "$args" }
    }

    $Script:Ordinal = @{$false = [StringComparer]::OrdinalIgnoreCase; $true = [StringComparer]::Ordinal }

    # The maximum schema object depth is bound by the input object depth (+1 one for the leaf test definition)
    $SchemaNode = [PSNode]::ParseInput($SchemaObject, ($MaxDepth + 2)) # +2 to be safe
    $Script:AssertPrefix = if ($SchemaNode.Contains($AssertTestPrefix)) { $SchemaNode.Value[$AssertTestPrefix] } else { '@' }

    function StopError($Exception, $Id = 'TestNode', $Category = [ErrorCategory]::SyntaxError, $Object) {
        if ($Exception -is [ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new($Exception, $Id, $Category, $Object))
    }

    function SchemaError($Message, $ObjectNode, $SchemaNode, $Object = $SchemaObject) {
        $Exception = [ArgumentException]"$([String]$SchemaNode) $Message"
        $Exception.Data.Add('ObjectNode', $ObjectNode)
        $Exception.Data.Add('SchemaNode', $SchemaNode)
        StopError -Exception $Exception -Id 'SchemaError' -Category InvalidOperation -Object $Object
    }

    $Script:Tests = @{
        Description      = 'Describes the test node'
        References       = 'Contains a list of assert references'
        Type             = 'The node or value is of type'
        NotType          = 'The node or value is not type'
        CaseSensitive    = 'The (descendant) node are considered case sensitive'
        Required         = 'The node is required'
        Unique           = 'The node is unique'

        Minimum          = 'The value is greater than or equal to'
        ExclusiveMinimum = 'The value is greater than'
        ExclusiveMaximum = 'The value is less than'
        Maximum          = 'The value is less than or equal to'

        MinimumLength    = 'The value length is greater than or equal to'
        Length           = 'The value length is equal to'
        MaximumLength    = 'The value length is less than or equal to'

        MinimumCount     = 'The node count is greater than or equal to'
        Count            = 'The node count is equal to'
        MaximumCount     = 'The node count is less than or equal to'

        Like             = 'The value is like'
        Match            = 'The value matches'
        NotLike          = 'The value is not like'
        NotMatch         = 'The value not matches'

        Ordered          = 'The nodes are in order'
        RequiredNodes    = 'The node contains the nodes'
        AllowExtraNodes  = 'Allow extra nodes'
    }

    $At = @{}
    $Tests.Get_Keys().Foreach{ $At[$_] = "$($AssertPrefix)$_" }

    function ResolveReferences($Node) {
        if ($Node.Cache.ContainsKey('TestReferences')) { return }

    }

    function GetReference($LeafNode) {
        $TestNode = $LeafNode.ParentNode
        $References = if ($TestNode) {
            if (-not $TestNode.Cache.ContainsKey('TestReferences')) {
                $Stack = [Stack]::new()
                while ($true) {
                    $ParentNode = $TestNode.ParentNode
                    if ($ParentNode -and -not $ParentNode.Cache.ContainsKey('TestReferences')) {
                        $Stack.Push($TestNode)
                        $TestNode = $ParentNode
                        continue
                    }
                    $RefNode = if ($TestNode.Contains($At.References)) { $TestNode.GetChildNode($At.References) }
                    $TestNode.Cache['TestReferences'] = [HashTable]::new($Ordinal[[Bool]$RefNode.CaseMatters])
                    if ($RefNode) {
                        foreach ($ChildNode in $RefNode.ChildNodes) {
                            if (-not $TestNode.Cache['TestReferences'].ContainsKey($ChildNode.Name)) {
                                $TestNode.Cache['TestReferences'][$ChildNode.Name] = $ChildNode
                            }
                        }
                    }
                    $ParentNode = $TestNode.ParentNode
                    if ($ParentNode) {
                        foreach ($RefName in $ParentNode.Cache['TestReferences'].get_Keys()) {
                            if (-not $TestNode.Cache['TestReferences'].ContainsKey($RefName)) {
                                $TestNode.Cache['TestReferences'][$RefName] = $ParentNode.Cache['TestReferences'][$RefName]
                            }
                        }
                    }
                    if ($Stack.Count -eq 0) { break }
                    $TestNode = $Stack.Pop()
                }
            }
            $TestNode.Cache['TestReferences']
        } else { @{} }
        if ($References.Contains($LeafNode.Value)) {
            $AssertNode.Cache['TestReferences'] = $References
            $References[$LeafNode.Value]
        }
        else { SchemaError "Unknown reference: $LeafNode" $ObjectNode $LeafNode }
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

        $AssertNode = if ($TestNode -is [PSCollectionNode]) { $TestNode } else { GetReference $TestNode }

        if ($ObjectNode -is [PSMapNode] -and $TestNode.NodeOrigin -eq 'Map') {
            if ($ObjectNode.Contains($Name)) {
                $ChildNode = $ObjectNode.GetChildNode($Name)
                if ($Ordered -and $ChildNodes.IndexOf($ChildNode) -ne $TestNodes.IndexOf($TestNode)) {
                    $Violates = "The node $Name is not in order"
                }
            } else { $ChildNode = $false }
        }
        elseif ($ChildNodes.Count -eq 1) { $ChildNode = $ChildNodes[0] }
        elseif ($Ordered) {
            $NodeIndex = $TestNodes.IndexOf($TestNode)
            if ($NodeIndex -ge $ChildNodes.Count) {
                $Violates = "Expected at least $($TestNodes.Count) (ordered) nodes"
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
                    Issue      = $Violates
                }
                $Output.PSTypeNames.Insert(0, 'TestResult')
                $Output
            }
            return
        }
        if ($ChildNode -is [PSNode]) {
            $Issue = $Null
            $TestParams = @{
                ObjectNode     = $ChildNode
                SchemaNode     = $AssertNode
                Elaborate      = $Elaborate
                CaseSensitive  = $CaseSensitive
                ValidateOnly   = $ValidateOnly
                RefInvalidNode = [Ref]$Issue
            }
            TestNode @TestParams
            if (-not $Issue) { $null = $MatchedNames.Add($ChildNode.Name) }
        }
        elseif ($null -eq $ChildNode) {
            $SingleIssue = $Null
            foreach ($ChildNode in $ChildNodes) {
                if ($MatchedNames.Contains($ChildNode.Name)) { continue }
                $Issue = $Null
                $TestParams = @{
                    ObjectNode     = $ChildNode
                    SchemaNode     = $AssertNode
                    Elaborate      = $Elaborate
                    CaseSensitive  = $CaseSensitive
                    ValidateOnly   = $true
                    RefInvalidNode = [Ref]$Issue
                }
                TestNode @TestParams
                if($Issue) {
                    if ($Elaborate) { $Issue }
                    elseif (-not $ValidateOnly -and $MatchAll) {
                        if ($null -eq $SingleIssue) { $SingleIssue = $Issue } else { $SingleIssue = $false }
                    }
                }
                else {
                    $null = $MatchedNames.Add($ChildNode.Name)
                    if (-not $MatchAll) { break }
                }
            }
            if ($SingleIssue) { $SingleIssue }
        }
        elseif ($ChildNode -eq $false) { $AssertResults[$Name] = $false }
        else { throw "Unexpected return reference: $ChildNode" }
    }

    function TestNode (
        [PSNode]$ObjectNode,
        [PSNode]$SchemaNode,
        [Switch]$Elaborate,             # if set, include the failed test results in the output
        [Nullable[Bool]]$CaseSensitive, # inherited the CaseSensitivity frm the parent node if not defined
        [Switch]$ValidateOnly,          # if set, stop at the first invalid node
        $RefInvalidNode                 # references the first invalid node
    ) {
        $CallStack = Get-PSCallStack
        # if ($CallStack.Count -gt 20) { Throw 'Call stack failsafe' }
        if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
            $Caller = $CallStack[1]
            Write-Host "$([ParameterColor]'Caller (line: $($Caller.ScriptLineNumber))'):" $Caller.InvocationInfo.Line.Trim()
            Write-Host "$([ParameterColor]'ObjectNode:')" $ObjectNode.Path "$ObjectNode"
            Write-Host "$([ParameterColor]'SchemaNode:')" $SchemaNode.Path "$SchemaNode"
            Write-Host "$([ParameterColor]'ValidateOnly:')" ([Bool]$ValidateOnly)
        }
        if ($SchemaNode -is [PSListNode] -and $SchemaNode.Count -eq 0) { return } # Allow any node

        $AssertValue = $ObjectNode.Value
        $RefInvalidNode.Value = $null

        # Separate the assert nodes from the schema subnodes
        $AssertNodes = [Ordered]@{} # $AssertNodes{<Assert Test name>] = $ChildNodes.@<Assert Test name>
        if ($SchemaNode -is [PSMapNode]) {
            $TestNodes = [List[PSNode]]::new()
            foreach ($Node in $SchemaNode.ChildNodes) {
                if ($Null -eq $Node.Parent -and $Node.Name -eq $AssertTestPrefix) { continue }
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
        $AllowExtraNodes = if ($AssertNodes.Contains('AllowExtraNodes')) { $AssertNodes['AllowExtraNodes'] }

#Region Node validation

        $RefInvalidNode.Value = $false
        $MatchedNames = [HashSet[Object]]::new()
        $AssertResults = $Null
        foreach ($TestName in $AssertNodes.get_Keys()) {
            $AssertNode = $AssertNodes[$TestName]
            $Criteria = $AssertNode.Value
            $Violates = $null # is either a boolean ($true if invalid) or a string with what was expected
            if ($TestName -eq 'Description') { $Null }
            elseif ($TestName -eq 'References') { }
            elseif ($TestName -in 'Type', 'notType') {
                $FoundType = foreach ($TypeName in $Criteria) {
                    if ($TypeName -in $null, 'Null', 'Void') {
                        if ($null -eq $AssertValue) { $true; break }
                    }
                    elseif ($TypeName -is [Type]) { $Type = $TypeName } else {
                        $Type = $TypeName -as [Type]
                        if (-not $Type) {
                            SchemaError "Unknown type: $TypeName" $ObjectNode $SchemaNode
                        }
                    }
                    if ($ObjectNode -is $Type -or $AssertValue -is $Type) { $true; break }
                }
                $Not = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                if ($null -eq $FoundType -xor $Not) { $Violates = "The node or value is $(if (!$Not) { 'not ' })of type $AssertNode" }
            }
            elseif ($TestName -eq 'CaseSensitive') {
                if ($null -ne $Criteria -and $Criteria -isnot [Bool]) {
                    SchemaError "The case sensitivity value should be a boolean: $Criteria" $ObjectNode $SchemaNode
                }
            }
            elseif ($TestName -in 'Minimum', 'ExclusiveMinimum', 'ExclusiveMaximum', 'Maximum') {
                if ($null -eq $AllowExtraNodes) { $AllowExtraNodes = $true }
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $Violates = "The value '$Value' is not a string or value type"
                    }
                    elseif ($TestName -eq 'Minimum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -cle $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -ile $Value }
                            else                               { $Criteria -le  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is less or equal than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMinimum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -clt $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -ilt $Value }
                            else                               { $Criteria -lt  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is less than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMaximum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -cgt $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -igt $Value }
                            else                               { $Criteria -gt  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is greater than $AssertNode"
                        }
                    }
                    else { # if ($TestName -eq 'Maximum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -cge $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -ige $Value }
                            else                               { $Criteria -ge  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is greater than $AssertNode"
                        }
                    }
                    if ($Violates) { break }
                }
            }

            elseif ($TestName -in 'MinimumLength', 'Length', 'MaximumLength') {
                if ($null -eq $AllowExtraNodes) { $AllowExtraNodes = $true }
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $Violates = "The value '$Value' is not a string or value type"
                        break
                    }
                    $Length = "$Value".Length
                    if ($TestName -eq 'MinimumLength') {
                        if ($Length -lt $Criteria) {
                            $Violates = "The string length of '$Value' ($Length) is less than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'Length') {
                        if ($Length -ne $Criteria) {
                            $Violates = "The string length of '$Value' ($Length) is not equal to $AssertNode"
                        }
                    }
                    else { # if ($TestName -eq 'MaximumLength') {
                        if ($Length -gt $Criteria) {
                            $Violates = "The string length of '$Value' ($Length) is greater than $AssertNode"
                        }
                    }
                    if ($Violates) { break }
                }
            }

            elseif ($TestName -in 'Like', 'NotLike', 'Match', 'NotMatch') {
                if ($null -eq $AllowExtraNodes) { $AllowExtraNodes = $true }
                $Negate = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                $Match  = $TestName.EndsWith('Match', 'OrdinalIgnoreCase')
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $Violates = "The value '$Value' is not a string or value type"
                        break
                    }
                    $Found = $false
                    foreach ($AnyCriteria in $Criteria) {
                        $Found = if ($Match) {
                            if     ($true -eq $CaseSensitive)  { $Value -cMatch $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $Value -iMatch $AnyCriteria }
                            else                               { $Value -Match  $AnyCriteria }
                        }
                        else { # if ($TestName.EndsWith('Link', 'OrdinalIgnoreCase')) {
                            if     ($true -eq $CaseSensitive)  { $Value -cLike  $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $Value -iLike  $AnyCriteria }
                            else                               { $Value -Like   $AnyCriteria }
                        }
                        if ($Found) { break }
                    }
                    $IsValid = $Found -xor $Negate
                    if (-not $IsValid) {
                        $Not = if (-Not $Negate) { ' not' }
                        $Violates =
                            if ($Match) { "The $(&$Yield '(case sensitive) ')value $Value does$not match $AssertNode" }
                            else        { "The $(&$Yield '(case sensitive) ')value $Value is$not like $AssertNode" }
                    }
                }
            }

            elseif ($TestName -in 'MinimumCount', 'Count', 'MaximumCount') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = "The node $ObjectNode is not a collection node"
                }
                elseif ($TestName -eq 'MinimumCount') {
                    if ($ChildNodes.Count -lt $Criteria) {
                        $Violates = "The node count ($($ChildNodes.Count)) is less than $AssertNode"
                    }
                }
                elseif ($TestName -eq 'Count') {
                    if ($ChildNodes.Count -ne $Criteria) {
                        $Violates = "The node count ($($ChildNodes.Count)) is not equal to $AssertNode"
                    }
                }
                else { # if ($TestName -eq 'MaximumCount') {
                    if ($ChildNodes.Count -gt $Criteria) {
                        $Violates = "The node count ($($ChildNodes.Count)) is greater than $AssertNode"
                    }
                }
            }

            elseif ($TestName -eq 'Required') { }
            elseif ($TestName -eq 'Unique' -and $Criteria) {
                if (-not $ObjectNode.ParentNode) {
                    SchemaError "The unique assert can't be used on a root node" $ObjectNode $SchemaNode
                }
                if ($Criteria -eq $true) { $UniqueCollection = $ObjectNode.ParentNode.ChildNodes }
                elseif ($Criteria -is [String]) {
                    if (-not $UniqueCollections.Contains($Criteria)) {
                        $UniqueCollections[$Criteria] = [List[PSNode]]::new()
                    }
                    $UniqueCollection = $UniqueCollections[$Criteria]
                }
                else { SchemaError "The unique assert value should be a boolean or a string" $ObjectNode $SchemaNode }
                $ObjectComparer = [ObjectComparer]::new([ObjectComparison][Int][Bool]$CaseSensitive)
                foreach ($UniqueNode in $UniqueCollection) {
                    if ([object]::ReferenceEquals($ObjectNode, $UniqueNode)) { continue } # Self
                    if ($ObjectComparer.IsEqual($ObjectNode, $UniqueNode)) {
                        $Violates = "The node is equal to the node: $($UniqueNode.Path)"
                        break
                    }
                }
                if ($Criteria -is [String]) { $UniqueCollection.Add($ObjectNode) }
            }
            elseif ($TestName -eq 'AllowExtraNodes') {}
            elseif ($TestName -in 'Ordered', 'RequiredNodes') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = "The '$($AssertNode.Name)' is not a collection node"
                }
            }
            else { SchemaError "Unknown assert node: $TestName" $ObjectNode $SchemaNode }

            if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
                if (-not $Violates) { Write-Host -ForegroundColor Green "Valid: $TestName $Criteria" }
                else { Write-Host -ForegroundColor Red "Invalid: $TestName $Criteria" }
            }

            if ($Violates -or $Elaborate) {
                $Issue =
                    if ($Violates -is [String]) { $Violates }
                    elseif ($Criteria -eq $true) { $($Tests[$TestName]) }
                    else { "$($Tests[$TestName] -replace 'The value ', "The value $ObjectNode ") $AssertNode" }
                $Output = [PSCustomObject]@{
                    ObjectNode = $ObjectNode
                    SchemaNode = $SchemaNode
                    Valid      = -not $Violates
                    Issue      = $Issue
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
                $Violates = "The node $ObjectNode is not a list node"
            }
            if ($SchemaNode -is [PSMapNode] -and $ObjectNode -isnot [PSMapNode]) {
                $Violates = "The node $ObjectNode is not a map node"
            }
        }

        if (-Not $Violates) {
            $RequiredNodes = $AssertNodes['RequiredNodes']
            $CaseSensitiveNames = if ($ObjectNode -is [PSMapNode]) { $ObjectNode.CaseMatters }
            $AssertResults = [HashTable]::new($Ordinal[[Bool]$CaseSensitiveNames])

            if ($RequiredNodes) { $RequiredList = [List[Object]]$RequiredNodes.Value } else { $RequiredList = [List[Object]]::new() }
            foreach ($TestNode in $TestNodes) {
                $AssertNode = if ($TestNode -is [PSCollectionNode]) { $TestNode } else { GetReference $TestNode }
                if ($AssertNode -is [PSMapNode] -and $AssertNode.GetValue($At.Required)) { $RequiredList.Add($TestNode.Name) }
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
                                        Elaborate     = $Elaborate
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
                                if ($Accumulator -eq $false -and -not $AllowExtraNodes) { break }
                                $Accumulator = $Accumulator -and $Operand
                            }
                            elseif ($Operator -eq 'Or') {
                                $Operator = $null
                                if ($Accumulator -eq $true -and -not $AllowExtraNodes) { break }
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
                    $Violates = "The required node condition $LogicalFormula is not met"
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
                    Elaborate     = $Elaborate
                    ValidateOnly  = $ValidateOnly
                    Ordered       = $AssertNodes['Ordered']
                    CaseSensitive = $CaseSensitive
                    MatchAll      = -not $AllowExtraNodes
                    MatchedNames  = $MatchedNames
                }
                MatchNode @MatchParams
                if ($AllowExtraNodes -and $MatchedNames.Count -eq $MatchCount0) {
                    $Violates = "When extra nodes are allowed, the node $ObjectNode should be accepted"
                    break
                }
                $AssertResults[$TestNode.Name] = $MatchedNames.Count -gt $MatchCount0
            }

            if (-not $AllowExtraNodes -and $MatchedNames.Count -lt $ChildNodes.Count) {
                $Count = 0; $LastName = $Null
                $Names = foreach ($Name in $ChildNodes.Name) {
                    if ($MatchedNames.Contains($Name)) { continue }
                    if ($Count++ -lt 4) {
                        if ($ObjectNode -is [PSListNode]) { [CommandColor]$Name }
                            else { [StringColor][PSKeyExpression]::new($Name, [PSSerialize]::MaxKeyLength)}
                    }
                    else { $LastName = $Name }
                }
                $Violates = "The following nodes are not accepted: $($Names -join ', ')"
                if ($LastName) {
                    $LastName = if ($ObjectNode -is [PSListNode]) { [CommandColor]$LastName }
                        else { [StringColor][PSKeyExpression]::new($LastName, [PSSerialize]::MaxKeyLength) }
                    $Violates += " .. $LastName"
                }
            }
        }

#EndRegion Optional nodes

        if ($Violates -or $Elaborate) {
            $Output = [PSCustomObject]@{
                ObjectNode = $ObjectNode
                SchemaNode = $SchemaNode
                Valid      = -not $Violates
                Issue      = if ($Violates) { $Violates } else { 'All the child nodes are valid'}
            }
            $Output.PSTypeNames.Insert(0, 'TestResult')
            if ($Violates) { $RefInvalidNode.Value = $Output }
            if (-not $ValidateOnly -or $Elaborate) { <# Write-Output #> $Output }
        }
    }
}

process {
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    $Script:UniqueCollections = @{}
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

