# using module .\..\..\..\ObjectGraphTools

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
[CmdletBinding(DefaultParameterSetName = 'ResultList', HelpUri = 'https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-ObjectGraph.md')][OutputType([String])] param(

    [Parameter(ParameterSetName = 'ValidateOnly', Mandatory = $true, ValueFromPipeLine = $True)]
    [Parameter(ParameterSetName = 'ResultList', Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Parameter(ParameterSetName = 'ValidateOnly', Mandatory = $true, Position = 0)]
    [Parameter(ParameterSetName = 'ResultList', Mandatory = $true, Position = 0)]
    $SchemaObject,

    [Parameter(ParameterSetName = 'ValidateOnly')]
    [Switch]$ValidateOnly,

    [Parameter(ParameterSetName = 'ResultList')]
    [Switch]$Elaborate,

    [Parameter(ParameterSetName = 'ValidateOnly')]
    [Parameter(ParameterSetName = 'ResultList')]
    [ValidateNotNullOrEmpty()][String]$AssertTestPrefix = 'AssertTestPrefix',

    [Parameter(ParameterSetName = 'ValidateOnly')]
    [Parameter(ParameterSetName = 'ResultList')]
    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)

begin {
    $Script:Elaborate = $Elaborate

    $Script:Yield = {
        $Name = "$Args" -replace '\W'
        $Value = Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue
        if ($Value) { "$args" }
    }

    $Script:Ordinal = @{$false = [StringComparer]::OrdinalIgnoreCase; $true = [StringComparer]::Ordinal }

    $Script:UniqueCollections = @{}

    # The maximum schema object depth is bound by the input object depth (+1 one for the leaf test definition)
    $SchemaNode = [PSNode]::ParseInput($SchemaObject, ($MaxDepth + 2)) # +2 to be safe
    $Script:AssertPrefix = if ($SchemaNode.Contains($AssertTestPrefix)) { $SchemaNode.Value[$AssertTestPrefix] } else { '@' }

    Enum ResultMode {
        Validate    # Only determines if the node is valid, if not the cmdlet is supposed to exit immediately
        Output      # Outputs the results immediately to the pipeline
        Collect     # Collects the results to match any potential node branch
    }

    Class Result {
        static [ResultMode]$Mode
        static [Bool]$Failed
        static [List[Object]]$List

        static [Bool]$Elaborate
        static [Bool]$Debug
        hidden static [Void]Initialize($ValidateOnly, $Elaborate, $Debug) {
            [Result]::Mode      = if ($ValidateOnly) { 'Validate' } else { 'Output' }
            [Result]::List      = $null
            [Result]::Failed    = $false
            [Result]::Elaborate = $Elaborate
            [Result]::Debug     = $Debug
        }
        [PSNode]$ObjectNode
        [PSNode]$SchemaNode
        hidden [Bool]$CollectStage

        Result($ObjectNode, $SchemaNode) {
            if ([Result]::Debug) {
                $Tab = ' ' * ($SchemaNode.Depth * 2)
                Write-Host "$Tab$([ParameterColor]'Caller:')" $this.GetCallerInfo() "(Mode: $([Result]::Mode))"
                Write-Host "$Tab$([ParameterColor]'ObjectNode:')" $ObjectNode.Path '=' "$ObjectNode"
                Write-Host "$Tab$([ParameterColor]'SchemaNode:')" $SchemaNode.Path '=' "$SchemaNode"
            }
            $this.ObjectNode = $ObjectNode
            $this.SchemaNode = $SchemaNode
        }

        [Object]Check([String]$Issue, [Bool]$Passed) {

            # Common test instance invocation:
            # if (($Out = $Result.Check('My issue', $Passed)) -eq $false) { return } else { $Out }

            if (-not $Passed) { [Result]::Failed = $true }

            if ([Result]::Debug) {
                $Tab = ' ' * ($this.SchemaNode.Depth * 2)
                Write-Host "$Tab$([ParameterColor]'Return:')" $this.GetCallerInfo() "(Mode: $([Result]::Mode))"
                Write-Host "$Tab$([ParameterColor]'Result:')" $Issue "($(if ($Passed) { 'Passed'} else { 'Failed' }))"
            }

            if (-Not $Issue) { return @() }
            if ([Result]::Mode -eq 'Validate' -and [Result]::Failed) { return $false }
            # if (-not [Result]::Elaborate -and ([Result]::Mode -eq 'Collect' -or $Passed)) { return @() }
            if (-not [Result]::Elaborate -and $Passed) { return @() }

            $TestResult = [PSCustomObject]@{
                ObjectNode = $this.ObjectNode
                SchemaNode = $this.SchemaNode
                Valid      = $Passed
                Issue      = $Issue
            }
            $TestResult.PSTypeNames.Insert(0, 'TestResult')
            if ([Result]::Mode -eq 'Output' -or [Result]::Elaborate) { return $TestResult }
            [Result]::List.Add($TestResult)
            return @()
        }

        hidden [String]GetCallerInfo() {
            $PSCallStack = Get-PSCallStack
            if ($PSCallStack.Count -le 2) { return ''}
            return "line $($PSCallStack[2].ScriptLineNumber): $($PSCallStack[2].InvocationInfo.Line.Trim())"
        }

        Collect() {
            if ([Result]::Mode -ne 'Output') { return } # Already in collect mode
            [Result]::Mode = 'Collect'
            [Result]::Failed = $false
            $this.CollectStage = $true
            [Result]::List = [List[Object]]::new()
        }

        [object] Complete([Bool]$Output) {
            if (-not $this.CollectStage) { return @() } # The result collection didn't start at this stage
            [Result]::Mode = 'Output'
            $this.CollectStage = $false
            $Results = [Result]::List
            [Result]::List = $null
            if ($Output) { return $Results } else { return @() }
        }
    }

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

    $Script:Asserts = @{
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
    $Asserts.Get_Keys().Foreach{ $At[$_] = "$($AssertPrefix)$_" }

    function GetReference($LeafNode) {
        # An assert node with a string value is a reference to another node
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
                    $CaseMatters = if ($RefNode) { $RefNode.CaseMatters }
                    $TestNode.Cache['TestReferences'] = [HashTable]::new($Ordinal[[Bool]$CaseMatters])
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
        }
        else { @{} }
        if ($References.Contains($LeafNode.Value)) {
            $AssertNode.Cache['TestReferences'] = $References
            $References[$LeafNode.Value]
        }
        else { SchemaError "Unknown reference: $LeafNode" $ObjectNode $LeafNode }
    }
    function TestNode (
        [PSNode]$ObjectNode,
        [PSNode]$SchemaNode,
        [Nullable[Bool]]$CaseSensitive # inherited the CaseSensitivity from the parent node if not defined
    ) {
        if ($SchemaNode -is [PSListNode] -and $SchemaNode.Count -eq 0) { return } # Allow any node

        $Result = [Result]::new($ObjectNode, $SchemaNode)
        $Violates = $null

        $AssertValue = $ObjectNode.Value

        # Separate the assert nodes from the schema subnodes
        $AssertNodes = [Ordered]@{} # $AssertNodes{<Assert Test name>] = $ChildNodes.@<Assert Test name>
        if ($SchemaNode -is [PSMapNode]) {
            $TestNodes = [List[PSNode]]::new()
            foreach ($Node in $SchemaNode.ChildNodes) {
                if ($Null -eq $Node.ParentNode.ParentNode -and $Node.Name -eq $AssertTestPrefix) { continue }
                if ($Node.Name.StartsWith($AssertPrefix)) {
                    $TestName = $Node.Name.SubString($AssertPrefix.Length)
                    if ($TestName -notin $Asserts.Keys) { SchemaError "Unknown assert: '$($Node.Name)'" $ObjectNode $SchemaNode }
                    $AssertNodes[$TestName] = $Node
                }
                else { $TestNodes.Add($Node) }
            }
        }
        elseif ($SchemaNode -is [PSListNode]) { $TestNodes = $SchemaNode.ChildNodes }
        else { $TestNodes = @() }

        if ($AssertNodes.Contains('CaseSensitive')) { $CaseSensitive = [Nullable[Bool]]$AssertNodes['CaseSensitive'] }
        $AllowExtraNodes = if ($AssertNodes.Contains('AllowExtraNodes')) { $AssertNodes['AllowExtraNodes'] }

        $MatchedNames = [HashSet[Object]]::new()
        $MatchedAsserts = $Null
        foreach ($TestName in $AssertNodes.get_Keys()) {

            #Region Node assertions

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
                if ($null -eq $FoundType -xor $Not) { $Violates = "The node $ObjectNode is $(if (!$Not) { 'not ' })of type $AssertNode" }
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
                        if ($CaseSensitive -eq $true) { $Criteria -cle $Value }
                        elseif ($CaseSensitive -eq $false) { $Criteria -ile $Value }
                        else { $Criteria -le $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is less or equal than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMinimum') {
                        $IsValid =
                        if ($CaseSensitive -eq $true) { $Criteria -clt $Value }
                        elseif ($CaseSensitive -eq $false) { $Criteria -ilt $Value }
                        else { $Criteria -lt $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is less than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMaximum') {
                        $IsValid =
                        if ($CaseSensitive -eq $true) { $Criteria -cgt $Value }
                        elseif ($CaseSensitive -eq $false) { $Criteria -igt $Value }
                        else { $Criteria -gt $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is greater than $AssertNode"
                        }
                    }
                    else {
                        # if ($TestName -eq 'Maximum') {
                        $IsValid =
                        if ($CaseSensitive -eq $true) { $Criteria -cge $Value }
                        elseif ($CaseSensitive -eq $false) { $Criteria -ige $Value }
                        else { $Criteria -ge $Value }
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
                    else {
                        # if ($TestName -eq 'MaximumLength') {
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
                $Match = $TestName.EndsWith('Match', 'OrdinalIgnoreCase')
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
                            if ($true -eq $CaseSensitive) { $Value -cmatch $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $Value -imatch $AnyCriteria }
                            else { $Value -match $AnyCriteria }
                        }
                        else {
                            # if ($TestName.EndsWith('Link', 'OrdinalIgnoreCase')) {
                            if ($true -eq $CaseSensitive) { $Value -clike $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $Value -ilike $AnyCriteria }
                            else { $Value -like $AnyCriteria }
                        }
                        if ($Found) { break }
                    }
                    $IsValid = $Found -xor $Negate
                    if (-not $IsValid) {
                        $Not = if (-not $Negate) { ' not' }
                        $Violates =
                        if ($Match) { "The $(&$Yield '(case sensitive) ')value $Value does$not match $AssertNode" }
                        else { "The $(&$Yield '(case sensitive) ')value $Value is$not like $AssertNode" }
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
                else {
                    # if ($TestName -eq 'MaximumCount') {
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
                        $Violates = "The node $ObjectNode is equal to the node: $($UniqueNode.Path)"
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

            #EndRegion Node assertions

            $Issue =
                if ($Violates -is [String]) { $Violates }
                elseif ($Criteria -eq $true) { $($Asserts[$TestName]) }
                else { "$($Asserts[$TestName] -replace 'The value ', "The value $ObjectNode ") $AssertNode" }
            if (($Out = $Result.Check($Issue, (-not $Violates))) -eq $false) { return } else { $Out }
            if ($Violates) { return }
        }

        #Region Required nodes

        if ($TestNodes.Count -and -not $AssertNodes.Contains('Type')) {
            if ($SchemaNode -is [PSListNode] -and $ObjectNode -isnot [PSListNode]) {
                $Violates = "The node $ObjectNode is not a list node"
            }
            if ($SchemaNode -is [PSMapNode] -and $ObjectNode -isnot [PSMapNode]) {
                $Violates = "The node $ObjectNode is not a map node"
            }
        }

        $LogicalFormulas = $null
        $RequiredList = [List[Object]]::new()
        if (-not $Violates) {
            $RequiredNodes = $AssertNodes['RequiredNodes']
            $CaseSensitiveNames = if ($ObjectNode -is [PSMapNode]) { $ObjectNode.CaseMatters }
            $MatchedAsserts = [HashTable]::new($Ordinal[[Bool]$CaseSensitiveNames])

            if ($RequiredNodes) { $RequiredList = [List[Object]]$RequiredNodes.Value }
            foreach ($TestNode in $TestNodes) {
                $AssertNode = if ($TestNode -is [PSCollectionNode]) { $TestNode } else { GetReference $TestNode }
                if ($AssertNode -is [PSMapNode] -and $AssertNode.GetValue($At.Required)) { $RequiredList.Add($TestNode.Name) }
            }

            $LogicalFormulas = foreach ($Requirement in $RequiredList) {
                $LogicalFormula = [LogicalFormula]$Requirement
                if ($LogicalFormula.Terms.Count -gt 1) { $Result.Collect() }
                $LogicalFormula
            }

            foreach ($LogicalFormula in $LogicalFormulas) {
                $Enumerator = $LogicalFormula.Terms.GetEnumerator()
                $Stack = [Stack]::new()
                $Stack.Push(@{
                        Enumerator  = $Enumerator
                        Accumulator = $null
                        Operator    = $null
                        Negate      = $null
                    })
                $Term, $Operand, $Accumulator = $null
                while ($Stack.Count -gt 0) {
                    # Accumulator = Accumulator <operation> Operand
                    # if ($Stack.Count -gt 20) { Throw 'Formula stack failsafe'}
                    $Pop = $Stack.Pop()
                    $Enumerator = $Pop.Enumerator
                    $Operator = $Pop.Operator
                    if ($null -eq $Operator) { $Operand = $Pop.Accumulator }
                    else { $Operand, $Accumulator = $Accumulator, $Pop.Accumulator }
                    $Negate = $Pop.Negate
                    $Compute = $null -notin $Operand, $Operator, $Accumulator
                    while ($Compute -or $Enumerator.MoveNext()) {
                        if ($Compute) { $Compute = $false }
                        else {
                            $Term = $Enumerator.Current
                            if ($Term -is [LogicalVariable]) {
                                $Name = $Term.Value
                                if (-not $MatchedAsserts.ContainsKey($Name)) {
                                    if (-not $SchemaNode.Contains($Name)) {
                                        SchemaError "Unknown test node: $Term" $ObjectNode $SchemaNode
                                    }
                                    $MatchCount0 = $MatchedNames.Count
                                    $ScanParams = @{
                                        ObjectNode    = $ObjectNode
                                        TestNode      = $SchemaNode.GetChildNode($Name)
                                        Ordered       = $AssertNodes['Ordered']
                                        CaseSensitive = $CaseSensitive
                                        MatchAll      = $false
                                        MatchedNames  = $MatchedNames
                                    }
                                    QueryChildNodes @ScanParams
                                    [Result]::Failed = $false # The (negated) formula determines the validation (not the individual tests)
                                    $MatchedAsserts[$Name] = $MatchedNames.Count -gt $MatchCount0
                                }
                                $Operand = $MatchedAsserts[$Name]
                            }
                            elseif ($Term -is [LogicalOperator]) {
                                if ($Term.Value -eq 'Not') { $Negate = -not $Negate }
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
                                $Enumerator = $Term.Terms.GetEnumerator()
                                continue
                            }
                            else { SchemaError "Unknown logical operator term: $Term" $ObjectNode $SchemaNode }
                        }
                        if ($null -ne $Operand) {
                            if ($null -eq $Accumulator -xor $null -eq $Operator) {
                                if ($Accumulator) { SchemaError "Missing operator before: $Term" $ObjectNode $SchemaNode }
                                else { SchemaError "Missing variable before: $Operator $Term" $ObjectNode $SchemaNode }
                            }
                            $Operand = $Operand -xor $Negate
                            $Negate = $null
                            if ($Operator -eq 'And') {
                                $Operator = $null
                                if ($Accumulator -eq $false -and -not $AllowExtraNodes) { break }
                                $Accumulator = $Accumulator -and $Operand
                            }
                            elseif ($Operator -eq 'Or') {
                                $Operator = $null
                                if ($Accumulator -eq $true -and -not $AllowExtraNodes) { break }
                                $Accumulator = $Accumulator -or $Operand
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
                if ($Accumulator -eq $false) {
                    $Violates = "The child node requirement $LogicalFormula is not met"
                    break
                }
            }
        }

        $Result.Complete([Bool]$Violates)
        $issue =
            if ($Violates) { $Violates }
            elseif ($LogicalFormulas) { "The child node requirement $LogicalFormulas is met" }
            else { 'There are no child node requirements' }
        if (($Out = $Result.Check($Issue, (-not $Violates))) -eq $false) { return } else { $Out }
        # if ($Violates) { return }

        #EndRegion Required nodes

        #Region Optional nodes

        if ($ObjectNode -is [PSLeafNode]) { return }
        $ChildNodes = $ObjectNode.ChildNodes
        foreach ($TestNode in $TestNodes) {
            if ($MatchedNames.Count -ge $ChildNodes.Count) { break }
            if ($MatchedAsserts.Contains($TestNode.Name)) { continue }
            $MatchCount0 = $MatchedNames.Count
            $ScanParams = @{
                ObjectNode    = $ObjectNode
                TestNode      = $TestNode
                Ordered       = $AssertNodes['Ordered']
                CaseSensitive = $CaseSensitive
                MatchAll      = -not $AllowExtraNodes
                MatchedNames  = $MatchedNames
            }
            QueryChildNodes @ScanParams
            if ($AllowExtraNodes -and $MatchedNames.Count -eq $MatchCount0) {
                $Violates = "When extra nodes are allowed, the node $ObjectNode should be accepted"
                break
            }
            $MatchedAsserts[$TestNode.Name] = $MatchedNames.Count -gt $MatchCount0
        }

        if (-not $AllowExtraNodes -and $MatchedNames.Count -lt $ChildNodes.Count) {
            [Result]::Failed = $true
            $Count = 0; $LastName = $Null
            $IsTested = $false
            $Names = foreach ($Name in $ChildNodes.Name) {
                if ($MatchedNames.Contains($Name)) { continue }
                if ($TestNodes -and $Name -in $TestNodes.Name) { $IsTested = $true }
                if ($Count++ -lt 4) {
                    if ($ObjectNode -is [PSListNode]) { [CommandColor]$Name }
                    else { [StringColor][PSKeyExpression]::new($Name) }
                }
                else { $LastName = $Name }
            }
            if ($LogicalFormulas -or -not $IsTested -or [Result]::Elaborate) {
                $Violates = "The following nodes are not accepted: $($Names -join ', ')"
                if ($LastName) {
                    $LastName = if ($ObjectNode -is [PSListNode]) { [CommandColor]$LastName }
                    else { [StringColor][PSKeyExpression]::new($LastName, [PSSerialize]::MaxKeyLength) }
                    $Violates += " .. $LastName"
                }
            }
        }

        if (-not $Violates) { return }
        if (($Out = $Result.Check($Violates, (-not $Violates))) -eq $false) { return } else { $Out }

        #EndRegion Optional nodes
    }

    function QueryChildNodes (
        [PSNode]$ObjectNode,
        [PSNode]$TestNode,
        [Switch]$Ordered,
        [Nullable[Bool]]$CaseSensitive,
        [Switch]$MatchAll,
        $MatchedNames
    ) {
        $Result = [Result]::new($ObjectNode, $SchemaNode)
        $Violates = $null
        $Name = $TestNode.Name
        $AssertNode = if ($TestNode -is [PSCollectionNode]) { $TestNode } else { GetReference $TestNode }
        $ChildNodes = $null
        if ($ObjectNode -is [PSMapNode] -and $TestNode.NodeOrigin -eq 'Map') {
            if ($ObjectNode.Contains($Name)) {
                if ($Ordered -and $ObjectNode.IndexOf($ObjectNode.ChildNodes) -ne $TestNodes.IndexOf($TestNode)) {
                    $Violates = "The node $Name is not in order"
                } else { $ChildNodes = $ObjectNode.GetChildNode($Name) }
            }
            else { $Violates = "The node $Name does not exist" }
        }
        elseif ($ObjectNode.ChildNodes.Count -eq 1) { $ChildNodes = $ObjectNode.ChildNodes[0] }
        elseif ($Ordered) {
            $NodeIndex = $TestNodes.IndexOf($TestNode)
            if ($NodeIndex -ge $ObjectNode.ChildNodes.Count) {
                $Violates = "Expected at least $($TestNodes.Count) (ordered) nodes"
            } else { $ChildNodes = $ObjectNode.ChildNodes[$NodeIndex] }
        }
        else { $ChildNodes = $ObjectNode.ChildNodes}

        if ($ChildNodes -is [PSNode]) { # There is only one child node to match
            TestNode -ObjectNode $ChildNodes -SchemaNode $AssertNode -CaseSensitive $CaseSensitive
            if ([Result]::Failed) { [Result]::Failed = $false }
            else { $null = $MatchedNames.Add($ChildNodes.Name) }
        }
        elseif ($ChildNodes) { # There are multiple child nodes to match
            $Result.Collect()
            $MatchCount0 = $MatchedNames.Count
            foreach ($ChildNode in $ChildNodes) {
                if ($MatchedNames.Contains($ChildNode.Name)) { continue }
                TestNode -ObjectNode $ChildNode -SchemaNode $AssertNode -CaseSensitive $CaseSensitive
                if ([Result]::Failed) { [Result]::Failed = $false }
                else { $null = $MatchedNames.Add($ChildNodes.Name) }
            }
            $TotalFound = $MatchedNames.Count - $MatchCount0
            $Missing = $TotalFound -eq 0 -or ($MatchAll -and $TotalFound -lt $ChildNodes.Count)
            $Result.Complete($Missing)
        }
        elseif (-not $Violates) { $Violates = "The node $ObjectNode has no child nodes" }

        if (($Out = $Result.Check($Violates, (-not $Violates))) -eq $false) { return } else { $Out }
    }
}

process {
    [Result]::Initialize($ValidateOnly, $Elaborate, ($DebugPreference -in 'Stop', 'Continue', 'Inquire')) # This cmdlet can only be invoked once in a single pipeline
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    TestNode $ObjectNode $SchemaNode
    if ($ValidateOnly) { -not [Result]::Failed }
}
