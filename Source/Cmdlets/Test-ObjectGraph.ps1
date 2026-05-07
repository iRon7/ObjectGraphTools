using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Collections.Specialized

<#
.SYNOPSIS
Tests the properties of an object-graph.

.DESCRIPTION
Tests an object-graph against a schema object by verifying that the properties of the object-graph
meet the constrains defined in the schema object.

The schema object has the following major features:

* Independent of the object notation (as e.g. [Json (JavaScript Object Notation)][2] or [PowerShell Data Files][3])
* Each test node is at the same level as the input node being validated
* Complex node Conditions (as mutual exclusive nodes) might be selected using a logical formula

.EXAMPLE
#Test whether a `$Person` object meats the schema Conditions.

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

If set, the cmdlet will return the test result object for all nodes, even if they are valid
or ruled out in a possible list node branch selection.

.PARAMETER AssertPrefix

The prefix used to identify the Assert nodes in the schema object. By default, the prefix is `@`.

.PARAMETER MaxDepth

The Maximum depth to recursively test each embedded node.
The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/SchemaObject.md "Schema object definitions"
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ContainsOptionalTests', Justification = 'https://github.com/PowerShell/PSScriptAnalyzer/issues/1163')]
[Alias('Test-Object', 'tso')]
[CmdletBinding(DefaultParameterSetName = 'ResultList', HelpUri = 'https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-ObjectGraph.md')][OutputType([String])]
param(
    [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Parameter(Mandatory = $true, Position = 0)]
    $SchemaObject,

    [Parameter(ParameterSetName = 'ValidateOnly')]
    [Switch]$ValidateOnly,

    [Parameter(ParameterSetName = 'ResultList')]
    [Switch]$Elaborate,

    [ValidateNotNullOrEmpty()][String]$AssertPrefixNodeName = 'AssertPrefix',

    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)

begin {

    $Script:UniqueCollections = @{}

    # The maximum schema object depth is bound by the input object depth (+1 one for the leaf test definition)
    $SchemaNode = [PSNode]::ParseInput($SchemaObject, ($MaxDepth + 2)) # +2 to be safe
    $Script:AssertPrefix = if ($SchemaNode.Contains($AssertPrefixNodeName)) { $SchemaNode.Value[$AssertPrefixNodeName] } else { '@' }

    class CheckBox {
        [Nullable[Bool]]$NullableBool

        CheckBox([Nullable[Bool]]$NullableBool) { $this.NullableBool = $NullableBool }

        [string] ToString() {
            return $(
                switch ($this.NullableBool) {
                    $null { [CommandColor][InverseColor]'[?]' }
                    $false { [ErrorColor][InverseColor]'[X]' }
                    $true { [VariableColor][InverseColor]'[V]' }
                }
            )
        }
    }

    class Permutations : IEnumerator {
        # This class enumerates all permutations of $n elements that Permutation over $i containers

        [int[]] $Element
        [List[int][]] $Container

        Permutations([int]$ElementCount, [int]$ContainerCount) {
            $this.Element = [int[]]::new($ElementCount)
            $this.Container = [List[int][]]::new($ContainerCount)
        }

        [object]get_Current() {
            if ($null -eq $this.Container[0]) { return @() }
            return $this.Container
        }

        [bool] MoveNext() {
            if ($this.Element.Count -eq 0 -or $this.Container.Count -eq 0) { return $false }
            if ($null -eq $this.Container[0]) {
                # First iteration
                $this.Container[0] = [List[int]] (0..($this.Element.Count - 1))
                for ($i = 1; $i -lt $this.Container.Count; $i++) { $this.Container[$i] = [List[int]]::new() }
                return $true
            }
            $n = 0
            while ($n -lt $this.Element.Count) {
                $i = $this.Element[$n] # Container index
                if (-not $this.Container[$i].Remove($n)) { throw "Container $i ($($this.Container[$i])) doesn't contain $n." }
                $Carry = ++$i -ge $this.Container.Count
                if ($Carry) { $i = 0 }
                $this.Element[$n] = $i
                $this.Container[$i].Add($n)
                if (-not $Carry) { return $true }
                $n++
            }
            $this.Reset()
            return $false
        }

        [List[int][]] Copy() {
            $Copy = [List[int][]]::new($this.Container.Count)
            for ($i = 0; $i -lt $this.Container.Count; $i++) {
                $Copy[$i] = [List[int]]::new($this.Container[$i])
            }
            return $Copy
        }

        [void] Reset() {
            $this.Element.Clear()
            $this.Container.Clear()
        }

        [void] Dispose() {}
    }

    class Permutation : Permutations , IEnumerator[int] {
        Permutation([int]$ElementCount, [int]$ContainerCount) : base($ElementCount, $ContainerCount) {}
        [Int]get_Current() { return $this }
        [string]ToString() {
            return $(
                foreach ($Indices in $this.Container) {
                    $Indices -join ','
                }
            ) -join '|'
        }
    }

    class TestStage {
        static [Bool]$Debug

        [PSNode]$ObjectNode
        [Bool]$Report
        [Bool]$Elaborate
        [Int]$Depth
        [TestStage]$ParentStage
        [Bool]$Passed = $true
        [Nullable[Bool]]$CaseSensitive
        [Int]$FailCount
        [List[Object]]$Results

        TestStage([PSNode]$ObjectNode, [Bool]$Elaborate, [Bool]$Report, [int]$Depth) {
            if ($Elaborate -and -not $Report) { throw "Can't elaborate in validate-only mode" }
            $this.ObjectNode = $ObjectNode
            $this.Elaborate = $Elaborate
            $this.Report = $Report
            $this.Depth = $Depth
            if ([TestStage]::Debug) { $this.WriteDebug($null, $null) }
        }

        [TestStage]Create([PSNode]$Node, [bool]$Scan) {
            $TestStage = [TestStage]::new($Node, $this.Elaborate, $this.Report, ($this.Depth + 1))
            $TestStage.ParentStage = $this.ParentStage
            $TestStage.CaseSensitive = $this.CaseSensitive
            if (-not $this.Report) { return $TestStage } # Validate mode: output no results
            # if ($this.Elaborate) { return $TestStage } # Elaborate mode: output all results
            if ($Scan) { $TestStage.Results = [List[Object]]::new() } # (Re)start scan stage
            elseif ($this.Results -is [IList]) { $TestStage.Results = $this.Results } # Add scan results to parent
            return $TestStage
        }

        hidden WriteDebug($TestNode, [String]$Issue) {
            $Indent = ' ' * ($this.Depth * 2)
            $Line = (Get-PSCallStack).Where({ $_.Command }, 'First').ScriptLineNumber
            $Prompt = if ($this.Report) { 'Report' } else { 'Validate' }
            if ($null -ne $this.Results) { $Prompt += '(Scan)' }
            $Node = $this.ObjectNode
            if ($TestNode -is [PSNode]) {
                Write-Host "$Indent$($Line):$Prompt>$($Node)?$($TestNode.Name)=$TestNode" ([CheckBox]$this.passed) $Issue
            }
            elseif ($Issue) {
                Write-Host "$Indent$($Line):$Prompt>$($Node.Path)=$Issue"
            }
            else {
                Write-Host "$Indent$($Line):$Prompt>$($Node.Path)=$Node"
            }
        }

        [Object]Check([PSNode]$TestNode, [String]$Issue, [Bool]$Passed) {
            if (-not $Passed) {
                $this.Passed = $false
                $this.FailCount++
            }
            if ([TestStage]::Debug) { $this.WriteDebug($TestNode, $Issue) }
            if (-not $this.Elaborate -and ($Passed -or -not $this.Report)) { return @() }
            $Result = [PSCustomObject]@{
                ObjectNode = $this.ObjectNode
                SchemaNode = $TestNode
                Valid      = $Passed
                Issue      = $Issue
            }
            $Result.PSTypeNames.Insert(0, 'TestResult')
            if ($null -eq $this.Results) { return $Result }
            $this.Results.Add($Result)
            return @() # return nothing (enumerable null)
        }

        [Object]AddResults ([List[Object]]$Results) {
            if (-not $Results) { return @() }
            if ($null -eq $this.Results) { return $Results }
            $this.Results.AddRange($Results)
            return @()
        }

        hidden [String]GroupDesignate($Stages, $TestIndex, $Permutation) {
            return $(
                if ($Permutation[$TestIndex].Count -eq 0) { [CheckBox]::new($false) }
                else {
                    foreach ($NodeIndex in $Permutation[$TestIndex]) {
                        $Check = if ($Stages[$NodeIndex] -and $Stages[$NodeIndex].ContainsKey($TestIndex)) {
                            $Stages[$NodeIndex][$TestIndex].Passed
                        }
                        "$($this.ObjectNode.ChildNodes[$NodeIndex])$([CheckBox]::new($Check))"
                    }
                }
            ) -join ','
        }

        [iDictionary]GetDesignates ($Stages, $SubTests, $Permutation, $TestPassed) {
            $Dictionary = [Dictionary[String, String]]::new()
            for ($TestIndex = 0; $TestIndex -lt $Permutation.Count; $TestIndex++) {
                $Name = $SubTests[$TestIndex].Name
                $Dictionary[$Name] = [CheckBox]::new($TestPassed[$TestIndex]).ToString() + '=' +
                $this.GroupDesignate($Stages, $TestIndex, $Permutation)
            }
            return $Dictionary
        }

        [iList]ListDesignates ($Stages, $SubTests, $Permutation, $TestPassed) {
            return @(
                for ($TestIndex = 0; $TestIndex -lt $Permutation.Count; $TestIndex++) {
                    if ($TestPassed.ContainsKey($TestIndex)) { continue }
                    $SubTests[$TestIndex].Name +
                    [CheckBox]::new($TestPassed[$TestIndex]).ToString() + '=' +
                    $this.GroupDesignate($Stages, $TestIndex, $Permutation)
                }
            )
        }

        [String]Casing() { if ($this.CaseSensitive) { return '(case sensitive) ' } else { return '' } }
    }

    [TestStage]::Debug = $DebugPreference -in 'Stop', 'Continue', 'Inquire'

    function StopError($Exception, $Id = 'TestNode', $Category = [ErrorCategory]::SyntaxError, $Object) {
        if ($Exception -is [ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new($Exception, $Id, $Category, $Object))
    }

    function SchemaError($Message, $SchemaNode) {
        $Exception = [ArgumentException]"$([String]$SchemaNode) $Message"
        StopError -Exception $Exception -Id 'SchemaError' -Category InvalidOperation -Object $SchemaNode
    }

    $Script:Asserts = @{
        Description      = 'Describes the test node'
        References       = 'Contains a list of Assert references'
        CaseSensitive    = 'The (descendant) nodes are considered case sensitive'
        Unique           = '_ObjectValue_ is unique'

        Ordered          = 'The nodes are in order'
        AnyName          = 'Any map name is allowed'
        Requires         = 'The node requirement is met'

        Optional         = 'The map node is optional'
        Count            = 'The list node exists _SchemaValue_ times'
        MinimumCount     = 'The list node exists at least _SchemaValue_ times'
        MaximumCount     = 'The list node exists at most _SchemaValue_ times'

        Type             = '_ObjectValue_ is of type _SchemaValue_'
        NotType          = '_ObjectValue_ is not type _SchemaValue_'

        Minimum          = '_ObjectValue_ is greater than or equal to _SchemaValue_'
        ExclusiveMinimum = '_ObjectValue_ is greater than _SchemaValue_'
        ExclusiveMaximum = '_ObjectValue_ is less than _SchemaValue_'
        Maximum          = '_ObjectValue_ is less than or equal to _SchemaValue_'

        MinimumLength    = '_ObjectValue_ length is greater than or equal to _SchemaValue_'
        Length           = '_ObjectValue_ length is equal to _SchemaValue_'
        MaximumLength    = '_ObjectValue_ length is less than or equal to _SchemaValue_'

        Like             = '_ObjectValue_ is like _SchemaValue_'
        Match            = '_ObjectValue_ matches _SchemaValue_'
        NotLike          = '_ObjectValue_ is not like _SchemaValue_'
        NotMatch         = '_ObjectValue_ not matches _SchemaValue_'
    }

    $At = @{}
    $Asserts.Get_Keys().Foreach{ $At[$_] = "$($Script:AssertPrefix)$_" }

    function GetLink($LeafNode) {
        # A test node with a string value is a reference to another node
        # described in a ancestor @Reference map node
        $ParentNode = $LeafNode.ParentNode
        if (-not $ParentNode.Cache.ContainsKey('@References')) {
            $Stack = [Stack]::new()
            while ($ParentNode -and -not $ParentNode.Cache.ContainsKey('@References')) {
                $Stack.Push($ParentNode)
                $ParentNode = $ParentNode.ParentNode
            }
            $References = if ($ParentNode -and $ParentNode.Cache.ContainsKey('@References')) { $ParentNode.Cache['@References'] } else { @{} }
            while ($Stack.Count) {
                $ParentNode = $Stack.Pop()
                if ($ParentNode.Contains($At.References)) {
                    $Inherit = $References
                    $RefNode = $ParentNode.GetChildNode($At.References)
                    if ($RefNode -is [PSMapNode]) {
                        $Ordinal = if ($RefNode.CaseMatters) { [StringComparer]::Ordinal } else { [StringComparer]::OrdinalIgnoreCase }
                        $References = [HashTable]::new($Ordinal)
                        foreach ($Node in $RefNode.ChildNodes) { $References[$Node.Name] = $Node }
                    }
                    else { SchemaError "The reference node should be a map node" $RefNode }
                    foreach ($Key in $Inherit.get_Keys()) {
                        if (-not $References.ContainsKey($Key)) { $References[$Key] = $Inherit[$Key] }
                    }
                }
                $ParentNode.Cache['@References'] = $References
            }
        }
        $Reference = $ParentNode.Cache['@References'][$LeafNode.Value]
        if ($Reference) { $Reference } else { SchemaError "Unknown reference: $LeafNode" $LeafNode }
    }

    function TestNode (
        [TestStage]$TestStage,
        [PSCollectionNode]$SchemaNode
    ) {
        $ObjectNode = $TestStage.ObjectNode
        if ($ObjectNode -is [PSLeafNode]) { $SubNodes = @() } else { $SubNodes = $ObjectNode.ChildNodes }
        if ($SchemaNode -is [PSListNode] -and $SchemaNode.Count -eq 0) { return } # @() = Allow any node, @{} = Deny any node

        $AssertValue = $ObjectNode.Value

        # Separate the assert nodes from the schema subnodes
        $ExtraTest, $Condition, $Ordered, $CaseMatters, $Ordinal = $null
        $CaseMatters = if ($ObjectNode -is [PSMapNode]) { $ObjectNode.CaseMatters }
        $Ordinal = if ($CaseMatters) { [StringComparer]::Ordinal } else { [StringComparer]::OrdinalIgnoreCase }
        $SubTests = [OrderedDictionary]::new($Ordinal)
        $AssertNodes = [Ordered]@{} # $AssertNodes[<Assert Test name>] = $SubNodes.@<Assert Test name>
        if ($SchemaNode -is [PSMapNode]) {
            foreach ($Node in $SchemaNode.ChildNodes) {
                if ($Null -eq $Node.ParentNode.ParentNode -and $Node.Name -eq $AssertPrefixNodeName) { continue }
                if ($Node.Name -is [String] -and $Node.Name.StartsWith($Script:AssertPrefix)) {
                    $TestName = $Node.Name.SubString($Script:AssertPrefix.Length)
                    if ($TestName -notin $Asserts.Keys) { SchemaError "Unknown Assert: '$TestName'" $SchemaNode }
                    $AssertNodes[$TestName] = $Node
                }
                else {
                    $SubTests[[Object]$Node.Name] = if ($Node -is [PSLeafNode]) { GetLink $Node } else { $Node }
                }
            }
        }
        elseif ($SchemaNode -is [PSListNode]) {
            foreach ($Node in $SchemaNode.ChildNodes) { $SubTests[[Object]$Node.Name] = $Node }
        }

        if ($AssertNodes.Contains('CaseSensitive')) { $TestStage.CaseSensitive = $AssertNodes['CaseSensitive'] }

        $LeafTest = $false
        foreach ($TestName in $AssertNodes.get_Keys()) {

            $TestNode = $AssertNodes[$TestName]
            $TestValue = $TestNode.Value

            #Region Node Asserts

            if ($TestName -in 'Description', 'References', 'Optional', 'Count', 'MinimumCount', 'MaximumCount') {
                continue
            }
            elseif ($TestName -eq 'CaseSensitive') {
                if ($null -ne $TestValue -and $TestValue -isnot [Bool]) {
                    SchemaError "The case sensitivity value should be a boolean: $TestValue" $SchemaNode
                }
                continue
            }
            elseif ($TestName -eq 'Ordered') {
                if ($TestValue -is [Bool]) { $Ordered = [Bool]$TestValue }
                else { SchemaError "The ordered assert should be a boolean" $SchemaNode }
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $TestStage.Check($TestNode, "The $ObjectNode is not a collection node", $false)
                }
                continue
            }
            elseif ($TestName -eq 'AnyName') {
                $ExtraTest = $TestNode
                if (-not $SubTests) { [OrderedDictionary]::new() }
                continue
            }
            elseif ($TestName -eq 'Requires') {
                if ($Ordered) { SchemaError "A ordered collection cannot have a Requires assert" $SchemaNode }
                if ($ObjectNode -is [PSCollectionNode]) {
                    $Condition = [LogicalFormula]::new()
                    $TestValue.foreach{ $Condition.And([LogicalFormula]$_) } # 'a or b', 'c or d' --> 'a or b and (c or d)'
                }
                else { $TestStage.Check($TestNode, "The node $ObjectNode is not a collection node", $false) }
                continue
            }
            elseif ($TestName -in 'Type', 'notType') {
                $TypeName = $null
                $FoundType = foreach ($TypeName in $TestValue) {
                    if ($TypeName -in $null, 'Null', 'Void') {
                        if ($null -eq $AssertValue) { $true; break }
                    }
                    else {
                        $Type = if ($TypeName -is [Type]) { $TypeName } else { $TypeName -as [Type] }
                        if (-not $Type) { SchemaError "Unknown type: $TypeName" $TypeName }
                        if ($ObjectNode -is $Type -or $AssertValue -is $Type) { $true; break }
                    }
                }
                $Not = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                if ($null -eq $FoundType -xor $Not) {
                    $DisplayType = $([TypeColor][PSSerialize]::new($TypeName, [PSLanguageMode]'NoLanguage'))
                    $TestStage.Check($TestNode, "$($ObjectNode.DisplayValue) is $(if (!$Not) { 'not ' })of type $DisplayType", $false)
                }
            }
            elseif ($TestName -in 'Minimum', 'ExclusiveMinimum', 'ExclusiveMaximum', 'Maximum') {
                $LeafTest = $true
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                if (-not $ValueNodes) { $TestStage.Check($TestNode, "The node $ObjectNode is empty", $false) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $TestStage.Check($TestNode, "The $ObjectNode is not a string or value type", $false)
                    }
                    elseif ($TestName -eq 'Minimum') {
                        $IsValid =
                        if ($TestStage.CaseSensitive -eq $true) { $TestValue -cle $Value }
                        elseif ($TestStage.CaseSensitive -eq $false) { $TestValue -ile $Value }
                        else { $TestValue -le $Value }
                        if (-not $IsValid) {
                            $TestStage.Check($TestNode, "The value $($ObjectNode.DisplayValue) is $($TestStage.Casing())less or equal than $TestValue", $false)
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMinimum') {
                        $IsValid =
                        if ($TestStage.CaseSensitive -eq $true) { $TestValue -clt $Value }
                        elseif ($TestStage.CaseSensitive -eq $false) { $TestValue -ilt $Value }
                        else { $TestValue -lt $Value }
                        if (-not $IsValid) {
                            $TestStage.Check($TestNode, "The value $($ObjectNode.DisplayValue) is $($TestStage.Casing())less than $TestValue", $false)
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMaximum') {
                        $IsValid =
                        if ($TestStage.CaseSensitive -eq $true) { $TestValue -cgt $Value }
                        elseif ($TestStage.CaseSensitive -eq $false) { $TestValue -igt $Value }
                        else { $TestValue -gt $Value }
                        if (-not $IsValid) {
                            $TestStage.Check($TestNode, "The value $($ObjectNode.DisplayValue) is $($TestStage.Casing())greater than $TestValue", $false)
                        }
                    }
                    else {
                        # if ($TestName -eq 'Maximum') {
                        $IsValid =
                        if ($TestStage.CaseSensitive -eq $true) { $TestValue -cge $Value }
                        elseif ($TestStage.CaseSensitive -eq $false) { $TestValue -ige $Value }
                        else { $TestValue -ge $Value }
                        if (-not $IsValid) {
                            $TestStage.Check($TestNode, "The value $($ObjectNode.DisplayValue) is $($TestStage.Casing())greater or equal than $TestValue)", $false)
                        }
                    }
                    if (-not $TestStage.Passed) { break }
                }
            }
            elseif ($TestName -in 'MinimumLength', 'Length', 'MaximumLength') {
                $LeafTest = $true
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                if (-not $ValueNodes) { $TestStage.Check($TestNode, "The node $ObjectNode is empty", $false) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $TestStage.Check($TestNode, "The $ObjectNode is not a string or value type", $false)
                        break
                    }
                    $Length = "$Value".Length
                    if ($TestName -eq 'MinimumLength') {
                        if ($Length -lt $TestValue) {
                            $TestStage.Check($TestNode, "The string length of $($ObjectNode.DisplayValue) ($Length) is less than $TestValue", $false)
                        }
                    }
                    elseif ($TestName -eq 'Length') {
                        if ($Length -ne $TestValue) {
                            $TestStage.Check($TestNode, "The string length of $($ObjectNode.DisplayValue) ($Length) is not equal to $TestValue", $false)
                        }
                    }
                    else {
                        # if ($TestName -eq 'MaximumLength') {
                        if ($Length -gt $TestValue) {
                            $TestStage.Check($TestNode, "The string length of $($ObjectNode.DisplayValue) ($Length) is greater than $TestValue", $false)
                        }
                    }
                    if (-not $TestStage.Passed) { break }
                }
            }

            elseif ($TestName -in 'Like', 'NotLike', 'Match', 'NotMatch') {
                $LeafTest = $true
                $Negate = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                $Match = $TestName.EndsWith('Match', 'OrdinalIgnoreCase')
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                if (-not $ValueNodes) { $TestStage.Check($TestNode, "The node $ObjectNode is empty", $false) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $TestStage.Check($TestNode, "$ObjectNode is not a string or value type", $false)
                        break
                    }
                    $Found = $false
                    $Criteria = $null
                    foreach ($Criteria in $TestValue) {
                        $Found = if ($Match) {
                            if ($true -eq $TestStage.CaseSensitive) { $Value -cmatch $Criteria }
                            elseif ($false -eq $TestStage.CaseSensitive) { $Value -imatch $Criteria }
                            else { $Value -match $Criteria }
                        }
                        else {
                            if ($true -eq $TestStage.CaseSensitive) { $Value -clike $Criteria }
                            elseif ($false -eq $TestStage.CaseSensitive) { $Value -ilike $Criteria }
                            else { $Value -like $Criteria }
                        }
                        if ($Found) { break }
                    }
                    $IsValid = $Found -xor $Negate
                    if (-not $IsValid) {
                        $Not = if (-not $Negate) { ' not' }
                        $DisplayCriteria = $([TypeColor][PSSerialize]::new($Criteria, [PSLanguageMode]'NoLanguage'))
                        if ($Match) { $TestStage.Check($TestNode, "The value $($ObjectNode.DisplayValue) does$not $($TestStage.Casing())match $DisplayCriteria", $false) }
                        else { $TestStage.Check($TestNode, "The value $($ObjectNode.DisplayValue) is$not $($TestStage.Casing())like $DisplayCriteria", $false) }
                    }
                }
            }
            elseif ($TestName -eq 'Unique') {
                if (-not $TestValue) { continue }
                if (-not $ObjectNode.ParentNode) {
                    SchemaError "The unique Assert can't be used on a root node" $SchemaNode
                }
                if ($TestValue -eq $true) { $UniqueCollection = $ObjectNode.ParentNode.ChildNodes }
                elseif ($TestValue -is [String]) {
                    if (-not $Script:UniqueCollections.Contains($TestValue)) {
                        $Script:UniqueCollections[$TestValue] = [List[PSNode]]::new()
                    }
                    $UniqueCollection = $Script:UniqueCollections[$TestValue]
                }
                else { SchemaError "The unique assert value should be a boolean or a string" $SchemaNode }
                $ObjectComparer = [ObjectComparer]::new([ObjectComparison][Int][Bool]$TestStage.CaseSensitive)
                foreach ($UniqueNode in $UniqueCollection) {
                    if ([object]::ReferenceEquals($ObjectNode, $UniqueNode)) { continue } # Self
                    if ($ObjectComparer.IsEqual($ObjectNode, $UniqueNode)) {
                        $TestStage.Check($TestNode, "The $($ObjectNode.DisplayValue) is equal to the node: $($UniqueNode.Path)", $false)
                        break
                    }
                }
                if ($TestValue -is [String]) { $UniqueCollection.Add($ObjectNode) }
            }
            else { SchemaError "Unhandled Assert: $TestName" $TestNode }

            #EndRegion Node Asserts

            if (-not $TestStage.Passed) { return } # Already issued
            if ([TestStage]::Debug -or $TestStage.Elaborate) {
                $Issue = $Asserts[$TestName] -replace '\b_ObjectValue_\b', $ObjectNode.DisplayValue -replace '\b_SchemaValue_\b', $TestNode.DisplayValue
                $TestStage.Check($TestNode, $Issue, $true)
            }
        }

        if ($LeafTest) { return } # No child nodes to test

        #Region SubTests

        if (-not $SubTests.Count) {
            if ($Condition) { SchemaError "Expected a test node for each requirement" $SchemaNode }
            if (-not $SubNodes) { return }
        }
        $FailCount = $TestStage.FailCount
        $CaseMatters = if ($ObjectNode -is [PSMapNode]) { $ObjectNode.CaseMatters }
        $Ordinal = if ($CaseMatters) { [StringComparer]::Ordinal } else { [StringComparer]::OrdinalIgnoreCase }

        $Required = if ($null -eq $Condition) { [LogicalFormula]::new() }
        $RequiredNames = [HashSet[String]]::new($Ordinal)
        if ($Condition) { $Condition.Find({ $Args[0] -is [LogicalVariable] }, $true).foreach{ $null = $RequiredNames.Add($_.Value) } }

        $ContainsOptionalTests = $false
        $TestIndices = [Dictionary[string, int]]::new($Ordinal)
        $MinimumCount = [Dictionary[int, int]]::new()
        $MaximumCount = [Dictionary[int, int]]::new()
        $TestIndex = 0
        foreach ($TestName in $SubTests.get_Keys()) {
            #$TestName is the reference name, $SubTest.Name is the actual name of the test
            $SubTest = $SubTests[$TestIndex]
            $TestIndices[$SubTest.Name] = $TestIndex
            $Optional = $SubTest.GetValue($At.Optional, $null)
            $Count = $SubTest.GetValue($At.Count, $null)
            $Minimum = $SubTest.GetValue($At.MinimumCount, $null)
            $Maximum = $SubTest.GetValue($At.MaximumCount, $null)
            if ($Optional -and ($Count -or $Minimum)) {
                SchemaError "The Optional (for maps) and (Minimum)Count (for lists) asserts are mutual exclusive" $SubTest
            }
            elseif ($Count -and ($Minimum -or $Maximum)) {
                SchemaError "The count and MinimumCount/MaximumCount asserts are mutual exclusive" $SubTest
            }
            if ($null -ne $Optional) {
                if ($null -ne ($Bool = $Optional -as [Bool])) {
                    $MinimumCount[$TestIndex] = 1 - $Bool
                }
                else { SchemaError "The Optional assert should be a boolean type" $SubTest }
            }
            if ($null -ne $Count) {
                if ($null -ne ($Int = $Count -as [UInt32])) {
                    $MinimumCount[$TestIndex] = $int
                    $MaximumCount[$TestIndex] = $int
                }
                else { SchemaError "The MinimumCount assert should be a positive integer type" $SubTest }
            }
            if ($null -ne $Minimum) {
                if ($null -ne ($Int = $Minimum -as [UInt32])) {
                    $MinimumCount[$TestIndex] = $int
                }
                else { SchemaError "The MinimumCount assert should be a positive integer type" $SubTest }
            }
            if ($null -ne $Maximum) {
                if ($null -ne ($Int = $Maximum -as [UInt32])) {
                    $MaximumCount[$TestIndex] = $int
                }
                else { SchemaError "The MaximumCount assert should be a positive integer type" $SubTest }
            }
            if ($MinimumCount.ContainsKey($TestIndex)) {
                if ($MinimumCount[$TestIndex]) {
                    if ($Required) { $Required.And($TestName) }
                    elseif ($RequiredNames.Add($TestName)) { $Condition.And($TestName) }
                }
                elseif ($Condition) { SchemaError "Required tests cannot be optional" $SubTest }
            }
            elseif ($Required) {
                $MinimumCount[$TestIndex] = 1
                if ($RequiredNames.Add($TestName)) { $Required.And($TestName) }
            }
            elseif ($Condition) { $MinimumCount[$TestIndex] = 1 }

            if ($MinimumCount.ContainsKey($TestIndex)) {
                $ContainsOptionalTests = $MinimumCount[$TestIndex] -eq 1
            }
            else { $MinimumCount[$TestIndex] = 0 }
            $TestIndex++
        }
        if ($Condition) { $Required = $Condition }
        # else { $Required.Find({ $Args[0] -is [LogicalVariable] }, $true).foreach{ $null = $RequiredNames.Add($_.Value) } }
        if ($Ordered) {
            if ($SubNodes.Count -lt $SubTests.Count) {
                $TestStage.Check($SchemaNode, "There are less than $($SubTests.Count) (ordered) child nodes", $false)
                return
            }
            elseif ($SubNodes.Count -gt $SubTests.Count -and -not $ExtraTest) {
                $TestStage.Check($SchemaNode, "There are more than $($SubTests.Count) (ordered) child nodes", $false)
                return
            }
            if ($ObjectNode -is [PSMapNode] -and $SchemaNode -is [PSMapNode]) {
                for ($Index = 0; $Index -lt $SubTests.Count; $Index++) {
                    $NodeName = $SubNodes[$Index].Name
                    $TestName = $SubTests[$Index].Name
                    $EqualName = if ($CaseMatters) { $TestName -ceq $NodeName } else { $TestName -ieq $NodeName }
                    if (-not $EqualName) {
                        $TestStage.Check($SchemaNode, "Node #$Index ($([PSSerialize]$SubNodes[$Index].Name)) is not $([PSSerialize]$Name)", $false)
                        return
                    }
                }
            }
            for ($Index = 0; $Index -lt $SubTests.Count; $Index++) {
                $SubNode = $SubNodes[$Index]
                $SubTest = $SubTests[$Index]
                $ChildStage = $TestStage.Create($SubNode, $false)
                TestNode $ChildStage $SubTest
                if (-not $ChildStage.Passed) { $TestStage.Passed = $false }
                # if (-not $ChildStage.Passed -and -not $TestStage.Report) { return }
            }
            while ($Index -lt $SubNodes.Count) { # Test the rest of the sub nodes against the $ExtraTest
                $SubNode = $SubNodes[$Index]
                $ChildStage = $TestStage.Create($SubNode, $false)
                TestNode $ChildStage $ExtraTest
                if (-not $ChildStage.Passed) { $TestStage.Passed = $false }
                # if (-not $ChildStage.Passed -and -not $TestStage.Report) { return }
                $Index++
            }
            return
        }
        elseif ($ObjectNode -is [PSMapNode] -and $SchemaNode -is [PSMapNode]) {
            if ($SubNodes.Count -gt $SubTests.Count -and -not $ExtraTest) {
                foreach ($ChildNode in $SubNodes) {
                    if ($SubTests.Contains($ChildNode.Name)) { continue }
                    $TestStage.Check($SchemaNode, "Node $([PSSerialize]$ChildNode.Name) is denied", $false)
                }
                return
            }
            if ($SubNodes) { $Names = $SubNodes.Name } else { $Names = @() }
            if ($Required.Terms -and -not $Required.Evaluate($Names)) {
                $TestStage.Check($SchemaNode, "The requirement { $Required } is not met", $false)
                return
            }
            foreach ($ChildNode in $SubNodes) {
                if ($SubTests.Contains($ChildNode.Name)) { $SubTest = $SubTests[[Object]$ChildNode.Name] }
                elseif ($ExtraTest) { $SubTest = $ExtraTest }
                else {
                    $TestStage.Check($SchemaNode, "Node $([PSSerialize]$ChildNode.Name) is denied", $false)
                    continue
                }
                $ChildStage = $TestStage.Create($ChildNode, $false)
                TestNode $ChildStage $SubTest
                if (-not $ChildStage.Passed) { $TestStage.Passed = $false }
            }
            return
        }
        # (unordered) $ObjectNode -is [PSListNode] -or $SchemaNode -is [PSListNode]
        if ($ExtraTest) { $SubTests[[Object]'@AnyName'] = $ExtraTest } # The ExtraTest is just an optional test for a list
        if ($SubTests.count -eq 1 -and $Required.Terms.count -le 1) {
            # Single test (no scanning required)
            $SubTest = $SubTests[0]
            if ($SubNodes.Count -lt $MinimumCount[0]) {
                $TestStage.Check($SubTest, "The node $ObjectNode contains less than $($MinimumCount[0]) child nodes", $false)
                return
            }
            if ($MaximumCount.ContainsKey(0) -and $SubNodes.Count -gt $MaximumCount[0]) {
                $TestStage.Check($SubTest, "The node $ObjectNode contains more than $($MaximumCount[0]) child nodes", $false)
                return
            }
            foreach ($ChildNode in $SubNodes) {
                $ChildStage = $TestStage.Create($ChildNode, $false)
                TestNode $ChildStage $SubTest
                $TestStage.Passed = $ChildStage.Passed
                if (-not $ChildStage.Passed -and -not $TestStage.Report) { return } # Validate only
            }
            return
        }
        $Stages = [Object[]]::new($SubNodes.Count)
        $TestStage.Passed = $false
        $Best = $null
        $TestPassed = $null
        foreach ($Permutation in [Permutation]::new($SubNodes.Count, $SubTests.Count)) {
            $Score = 0
            $TestPassed = [Dictionary[Int, Bool]]::new()
            $UsedNodes = [HashSet[Int]]::new()
            $RequiredPassed = if ($Required.Terms) {
                $Required.Evaluate({
                        $TestIndex = $TestIndices[$_]
                        if ($null -eq $TestIndex) { return $true } # Might happen at maxdepth
                        $SubTest = $SubTests[$TestIndex]
                        $Indices = $Permutation[$TestIndex]
                        $OutsideBounds = if ($Indices.Count -lt $MinimumCount[$TestIndex]) {
                            $Indices.Count - $MinimumCount[$TestIndex]
                        }
                        elseif ($MaximumCount.ContainsKey($TestIndex) -and $Indices.Count -gt $MaximumCount[$TestIndex]) {
                            $MaximumCount[$TestIndex] - $Indices.Count
                        }
                        if ($OutsideBounds) {
                            $Score -= $OutsideBounds
                            if (-not $TestStage.Report) { return $false } # Validate only
                            # if (-not $TestPassed.ContainsKey($TestIndex)) { return $false }
                            foreach ($NodeIndex in $Indices) {
                                # Add score based on what is known
                                if (-not $Stages[$NodeIndex]) { continue }
                                if (-not $Stages[$NodeIndex].ContainsKey($TestIndex)) { continue }
                                $Stage = $Stages[$NodeIndex][$TestIndex]
                                if ($Stage.Passed) { $Score++ } else { $Score -= 2 + $Stage.FailCount }
                            }
                            return $false
                        }
                        if (-not $TestPassed.ContainsKey($TestIndex)) {
                            $TestPassed[$TestIndex] = $false # $MaximumCount[$TestIndex] -eq 0
                        }
                        foreach ($NodeIndex in $Indices) {
                            # A logical variable might refer to multiple child nodes
                            if (-not $Stages[$NodeIndex]) { $Stages[$NodeIndex] = [Dictionary[int, TestStage]]::new() }
                            if (-not $Stages[$NodeIndex].ContainsKey($TestIndex)) {
                                $ChildNode = $SubNodes[$NodeIndex]
                                $Stages[$NodeIndex][$TestIndex] = $TestStage.Create($ChildNode, $true)
                                TestNode $Stages[$NodeIndex][$TestIndex] $SubTest
                            }
                            $Stage = $Stages[$NodeIndex][$TestIndex]
                            if ($Stage.Passed) { $Score++ } else { $Score -= 2 + $Stage.FailCount; return $false } # All child nodes need to fulfill the test
                            $null = $UsedNodes.Add($NodeIndex)

                        }
                        $Score += 1 + $Indices.Count
                        $TestPassed[$TestIndex] = $true
                        return $true
                    })
            }
            else { $true }
            $NodesLeft = $SubNodes.Count - $UsedNodes.Count
            $TestsLeft = $SubTests.Count - $TestPassed.Count
            $OptionalPassed = if (-not $RequiredPassed) { $false }
                elseif ($null -eq $Condition) { $null }
                elseif ($TestPassed.Count -eq 0) { $false }
                elseif ($NodesLeft -and $TestsLeft) { $null } # else: one or both are zero
                elseif (-not $NodesLeft) { $true }
                elseif (-not $ContainsOptionalTests) { $false }
                elseif (-not $TestsLeft) { $false }
            # Write-Host 123 $Condition $TestPassed $NodesLeft $TestsLeft $OptionalPassed
            # $TestOptional = if ($RequiredPassed -and $NodesLeft) {
            #     if ($TestsLeft) { $ContainsOptionalTests } else { $RequiredPassed = $false }
            # }
            # $OptionalPassed = $null
            # if ($TestOptional) {
            if ($null -eq $OptionalPassed) {
                for ($TestIndex = 0; $TestIndex -lt $SubTests.Count; $TestIndex++) {
                    if ($TestPassed.ContainsKey($TestIndex)) { continue }
                    if ($MinimumCount[$TestIndex]) { continue } # not optional (handled in condition evaluation)
                    $Indices = $Permutation[$TestIndex]
                    if ($MaximumCount.ContainsKey($TestIndex) -and $Indices.Count -gt $MaximumCount[$TestIndex]) {
                        $Score -= $Indices.Count - $MaximumCount[$TestIndex]
                        # if (-not $TestStage.Report) { break } # Validate only
                        foreach ($NodeIndex in $Indices) {
                            # Add score based on what is known
                            if (-not $Stages[$NodeIndex]) { continue }
                            if (-not $Stages[$NodeIndex].ContainsKey($TestIndex)) { continue }
                            $Stage = $Stages[$NodeIndex][$TestIndex]
                            if ($Stage.Passed) { $Score++ } else { $Score -= 2 + $Stage.FailCount }
                        }
                        $OptionalPassed = $false
                        break
                    }
                    foreach ($NodeIndex in $Indices) {
                        if (-not $Stages[$NodeIndex]) { $Stages[$NodeIndex] = [Dictionary[int, TestStage]]::new() }
                        if (-not $Stages[$NodeIndex].ContainsKey($TestIndex)) {
                            $ChildNode = $SubNodes[$NodeIndex]
                            $Stages[$NodeIndex][$TestIndex] = $TestStage.Create($ChildNode, $true)
                            TestNode $Stages[$NodeIndex][$TestIndex] $SubTests[$TestIndex]                                           # $SubTest ???
                        }
                        $Stage = $Stages[$NodeIndex][$TestIndex]
                        $OptionalPassed = $Stage.Passed
                        if ($OptionalPassed) { $Score++ } else { $Score -= 2 + $Stage.FailCount; break } # All (optional) child nodes need to fulfill the test
                    }
                    if ($OptionalPassed -eq $false) { break }
                    $Score += 1 + $Indices.Count
                }
            }
            else { $Score -= $NodesLeft }
            if ($null -eq $OptionalPassed) { $OptionalPassed = $true }

            if ([TestStage]::Debug) {
                $Better = if (-not $Best -or $Score -gt $Best['Score']) { '(best)' }
                $Designates = $TestStage.GetDesignates($Stages, $SubTests, $Permutation, $TestPassed)
                $TestStage.WriteDebug($null, "$([ParameterColor]'Required')$([CheckBox]::new($RequiredPassed)):$($Required.ToString($Designates)) $([ParameterColor]""Score:$Score $Better"")")
                if ($TestsLeft -and $NodesLeft) {
                    $Designates = $TestStage.ListDesignates($Stages, $SubTests, $Permutation, $TestPassed) -join ','
                    $TestStage.WriteDebug($null, "$([ParameterColor]'Optional')$([CheckBox]::new($OptionalPassed)):$Designates")
                }
            }
            $TestStage.Passed = $RequiredPassed -and $OptionalPassed
            # $TestStage.Passed = $RequiredPassed -and $OptionalPassed
            if ($TestStage.Passed) { break }
            if (-not $Best -or $Score -gt $Best['Score']) {
                # Capture the highest score with the least amount of issues
                if (-not $Best) { $Best = @{} }
                $Best['Score'] = $Score
                $Best['TestPassed'] = [Dictionary[Int, Bool]]::new($TestPassed)
                $Best['Permutation'] = $foreach.Copy()
            }
        }
        # if ([TestStage]::Debug) {
        #     $ScoreFail = [ParameterColor]"(Score:$($Best['Score']))"
        #     $Designates = $TestStage.GetDesignates($Stages, $SubTests, $Best['Permutation'], $Best['TestPassed'])
        #     $TestStage.WriteDebug($null, "Selected$([CheckBox]::new($RequiredPassed)):$($Required.ToString($Designates)) $ScoreFail")
        # }
        if (-not $TestPassed) { $TestStage.Passed = -not $Required.Terms -and $SubTests.Count } # In case of no permutations
        if ($TestStage.Elaborate) {
            for ($NodeIndex = 0; $NodeIndex -lt $SubNodes.Count; $NodeIndex++) {
                if (-not $Stages[$NodeIndex]) { continue }
                foreach ($Stage in $Stages[$NodeIndex].get_Values()) {
                    $TestStage.AddResults($Stage.Results)
                }
            }
        }
        elseif ($TestStage.Passed) { return }
        elseif ($Best) {
            $Permutation = $Best['Permutation']
            for ($TestIndex = 0; $TestIndex -lt $Permutation.Count; $TestIndex++) {
                $Indices = $Permutation[$TestIndex]
                if ($Indices.Count -lt $MinimumCount[$TestIndex]) {
                    if ($MinimumCount[$TestIndex] -eq 1) {
                        $TestStage.Check($SchemaNode, "The requirement $([LogicalVariable]$SubTests[$TestIndex].Name) is missing", $false)
                    }
                    else {
                        $TestStage.Check($SchemaNode, "$([LogicalVariable]$SubTests[$TestIndex].Name) occurred less than $($MinimumCount[$TestIndex]) times", $false)
                    }
                }
                if ($MaximumCount.ContainsKey($TestIndex) -and $Indices.Count -gt $MaximumCount[$TestIndex]) {
                    $TestStage.Check($SchemaNode, "$([LogicalVariable]$SubTests[$TestIndex].Name) occurred more than $($MaximumCount[$TestIndex]) times", $false)
                }
                foreach ($NodeIndex in $Indices) {
                    if ($null -eq $Stages[$NodeIndex] -or $null -eq $Stages[$NodeIndex][$TestIndex]) { continue }
                    $Results = $Stages[$NodeIndex][$TestIndex].Results
                    if (-not $Results -or $Results.Count -eq 0) { continue }
                    $TestStage.AddResults($Results)
                    $TestStage.FailCount += $Results.Count
                }
            }
        }

        if (-not $TestStage.Passed -and $FailCount -eq $TestStage.FailCount) {
            # Presumably concerns a negative requirement
            # $Not = if ($TestStage.Passed) { ' not' }
            $TestStage.Check($SchemaNode, "$ObjectNode is not accepted", $TestStage.Passed)
            # if (-not $Best) {
            #     $TestStage.Check($SchemaNode, "$ObjectNode nodes did$Not pass", $TestStage.Passed)
            # }
            # elseif ($Best['TestPassed'].Count) {
            #     foreach ($TestIndex in $Best['TestPassed'].get_Keys()) {
            #         if ($Best['TestPassed'][$TestIndex]) { continue }
            #         $TestStage.Check($SchemaNode, "The requirement $([LogicalVariable]$SubTests[$TestIndex].Name) has$Not met", $false)
            #     }
            # }
            # else {
            #     for ($NodeIndex = 0; $NodeIndex -lt $SubNodes.Count; $NodeIndex++) {
            #         if ($UsedNodes.Contains($NodeIndex)) { continue }
            #         $TestStage.Check($SchemaNode, "$($SubNodes[$NodeIndex]) is$Not accepted", $false)
            #     }
            # }
        }
        #EndRegion SubTests
    }
}

process {
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    $TestStage = [TestStage]::new($ObjectNode, $Elaborate, (-not $ValidateOnly), 0)
    TestNode $TestStage $SchemaNode
    if ($ValidateOnly) { $TestStage.Passed }
}
