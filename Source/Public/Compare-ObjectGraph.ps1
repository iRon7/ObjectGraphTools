<#
.SYNOPSIS
    Compare Object Graph

.DESCRIPTION
    Deep compares two Object Graph and lists the differences between them.

.PARAMETER InputObject
    The input object that will be compared with the reference object (see: [-Reference] parameter).

    > [!NOTE]
    > Multiple input object might be provided via the pipeline.
    > The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
    > To avoid a list of (root) objects to unroll, use the **comma operator**:

        ,$InputObject | Compare-ObjectGraph $Reference.

.PARAMETER Reference
    The reference that is used to compared with the input object (see: [-InputObject] parameter).

.PARAMETER PrimaryKey
    If supplied, dictionaries (including PSCustomObject or Component Objects) in a list are matched
    based on the values of the `-PrimaryKey` supplied.

.PARAMETER IsEqual
    If set, the cmdlet will return a boolean (`$true` or `$false`).
    As soon a Discrepancy is found, the cmdlet will immediately stop comparing further properties.

.PARAMETER MatchCase
    Unless the `-MatchCase` switch is provided, string values are considered case insensitive.

    > [!NOTE]
    > Dictionary keys are compared based on the `$Reference`.
    > if the `$Reference` is an object (PSCustomObject or component object), the key or name comparison
    > is case insensitive otherwise the comparer supplied with the dictionary is used.

.PARAMETER MatchType
    Unless the `-MatchType` switch is provided, a loosely (inclusive) comparison is done where the
    `$Reference` object is leading. Meaning `$Reference -eq $InputObject`:

        '1.0' -eq 1.0 # $false
        1.0 -eq '1.0' # $true (also $false if the `-MatchType` is provided)

.PARAMETER MatchOrder
    By default, items in a list and dictionary (including properties of an PSCustomObject or Component Object)
    are matched independent of the order. If the `-MatchOrder` switch is supplied the index of the concerned
    item (or property) is matched.

    > [!NOTE]
    > A `[HashTable]` type is unordered by design and therefore, regardless the `-MatchOrder` switch, the order
    > of the `[HashTable]` are always ignored.

    > [!NOTE]
    > Regardless of the `-MatchOrder` switch, indexed (defined by the [PrimaryKey] parameter) dictionaries
    (including PSCustomObject or Component Objects) in a list are matched independent of the order.

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded property (default: 10).
#>
function Compare-ObjectGraph {
    [CmdletBinding()] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        $InputObject,

        [Parameter(Mandatory = $true, Position=0)]
        $Reference,

        [String[]]$PrimaryKey,

        [Switch]$IsEqual,

        [Switch]$MatchCase,

        [Switch]$MatchType,

        [Switch]$MatchOrder,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        function CompareObject(
            [PSNode]$ReferenceNode,
            [PSNode]$ObjectNode,
            [String[]]$PrimaryKey = $PrimaryKey,
            [Switch]$IsEqual      = $IsEqual,
            [Switch]$MatchCase    = $MatchCase,
            [Switch]$MatchType    = $MatchType,
            [Switch]$MatchOrder   = $MatchOrder
        ) {
            if ($MatchType) {
                if ($ObjectNode.ValueType -ne $ReferenceNode.ValueType) {
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Path        = $ObjectNode.PathName
                        Discrepancy = 'Type'
                        InputObject = $ObjectNode.ValueType
                        Reference   = $ReferenceNode.ValueType
                    }
                }
            }
            if ($ObjectNode -is [PSCollectionNode] -and $ReferenceNode -is [PSCollectionNode]) {
                if ($ObjectNode.Count -ne $ReferenceNode.Count) {
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Path        = $ObjectNode.PathName
                        Discrepancy = 'Size'
                        InputObject = $ObjectNode.Count
                        Reference   = $ReferenceNode.Count
                    }
                }
            }
            if ($ObjectNode -is [PSLeafNode] -and $ReferenceNode -is [PSLeafNode]) {
                $NotEqual = if ($MatchCase) { $ReferenceNode.Value -cne $ObjectNode.Value } else { $ReferenceNode.Value -ne $ObjectNode.Value }
                if ($NotEqual) { # $ReferenceNode dictates the type
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Path        = $ObjectNode.PathName
                        Discrepancy = 'Value'
                        InputObject = $ObjectNode.Value
                        Reference   = $ReferenceNode.Value
                    }
                }
            }
            elseif ($ObjectNode -is [PSListNode] -and $ReferenceNode -is [PSListNode]) {
                $ObjectItems      = $ObjectNode.ChildNodes
                $ReferenceItems   = $ReferenceNode.ChildNodes
                if ($ObjectItems.Count)    { $ObjectIndices    = [Collections.Generic.List[Int]]$ObjectItems.Name } else { $ObjectIndices      = @() }
                if ($ReferenceItems.Count) { $ReferenceIndices = [Collections.Generic.List[Int]]$ReferenceItems.Name } else { $ReferenceIndices = @() }
                if ($PrimaryKey) {
                    $ObjectDictionaries = [Collections.Generic.List[Int]]$ObjectItems.where{ $_ -is [PSMapNode] }.Name
                    if ($ObjectDictionaries.Count) {
                        $ReferenceDictionaries = [Collections.Generic.List[Int]]$ReferenceItems.where{ $_ -is [PSMapNode] }.Name
                        if ($ReferenceDictionaries.Count) {
                            foreach ($Key in $PrimaryKey) {
                                foreach($ObjectIndex in @($ObjectDictionaries)) {
                                    $ObjectItem = $ObjectItems[$ObjectIndex]
                                    foreach ($ReferenceIndex in $ReferenceDictionaries) {
                                        $ReferenceItem = $ReferenceItems[$ReferenceIndex]
                                        if ($ReferenceItem.GetItem($Key) -eq $ObjectItem.GetItem($Key)) {
                                            if (CompareObject -Reference $ReferenceItem -Object $ObjectItem -IsEqual) {
                                                $null = $ObjectDictionaries.Remove($ObjectIndex)
                                                $Null = $ReferenceDictionaries.Remove($ReferenceIndex)
                                                $null = $ObjectIndices.Remove($ObjectIndex)
                                                $Null = $ReferenceIndices.Remove($ReferenceIndex)
                                                break # Only match a single node
                                            }
                                        }
                                    }
                                }
                                foreach ($Key in $PrimaryKey) { # in case of any single leftovers where the key value doesn't match
                                    if($ObjectDictionaries.Count -eq 1 -and $ReferenceDictionaries.Count -eq 1) {
                                        $ObjectItem    = $ObjectItems[$ObjectDictionaries[0]]
                                        $ReferenceItem = $ReferenceItems[$ReferenceDictionaries[0]]
                                        $Compare = CompareObject -Reference $ReferenceItem -Object $ObjectItem
                                        if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }
                                        $ObjectDictionaries.Clear()
                                        $ReferenceDictionaries.Clear()
                                        $null = $ObjectIndices.Remove($ObjectDictionaries[0])
                                        $Null = $ReferenceIndices.Remove($ReferenceDictionaries[0])
                                    }
                                }
                            }
                        }
                    }
                }
                foreach($ObjectIndex in @($ObjectIndices)) {
                    $ObjectItem = $ObjectItems[$ObjectIndex]
                    foreach ($ReferenceIndex in $ReferenceIndices) {
                        $ReferenceItem = $ReferenceItems[$ReferenceIndex]
                        if (CompareObject -Reference $ReferenceItem -Object $ObjectItem -IsEqual) {
                            if ($MatchOrder -and $ObjectItem.Name -ne $ReferenceItem.Name) {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Path        = $ReferenceNode.PathName
                                    Discrepancy = 'Index'
                                    InputObject = $ObjectItem.Name
                                    Reference   = $ReferenceItem.Name
                                }
                            }
                            $null = $ObjectIndices.Remove($ObjectIndex)
                            $Null = $ReferenceIndices.Remove($ReferenceIndex)
                            break # Only match a single node
                        }
                    }
                }
                for ($i = 0; $i -lt [math]::max($ObjectIndices.Count, $ReferenceIndices.Count); $i++) {
                    $ObjectIndex    = if ($i -lt $ObjectIndices.Count)    { $ObjectIndices[$i] }
                    $ReferenceIndex = if ($i -lt $ReferenceIndices.Count) { $ReferenceIndices[$i] }
                    $ObjectItem     = if ($Null -ne $ObjectIndex)    { $ObjectItems[$ObjectIndex] }
                    $ReferenceItem  = if ($Null -ne $ReferenceIndex) { $ReferenceItems[$ReferenceIndex] }
                    if ($Null -eq $ObjectItem) {            # if ($IsEqual) { never happens as the size already differs
                        [PSCustomObject]@{
                            Path        = $ReferenceNode.PathName + "[$ReferenceIndex]"
                            Discrepancy = 'Value'
                            InputObject = $Null
                            Reference   = if ($ReferenceItem -eq 'Scalar') { $ReferenceItem.Value } else { "[$($ReferenceItem.ValueType)]" }
                        }
                    }
                    elseif ($Null -eq $ReferenceItem) {     # if ($IsEqual) { never happens as the size already differs
                        [PSCustomObject]@{
                            Path        = $ObjectNode.PathName + "[$ObjectIndex]"
                            Discrepancy = 'Value'
                            InputObject = if ($ObjectItem -eq 'Scalar') { $ObjectItem.Value } else { "[$($ObjectItem.ValueType)]" }
                            Reference   = $Null
                        }
                    }
                    else {
                        $Compare = CompareObject -Reference $ReferenceItem -Object $ObjectItem
                        if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }
                    }
                }
            }
            elseif ($ObjectNode -is [PSMapNode] -and $ReferenceNode -is [PSMapNode]) {
                $Found = [HashTable]::new() # (Case sensitive)
                $Order = if ($MatchOrder -and $ReferenceNode.ValueType.Name -ne 'HashTable') { [HashTable]::new() }
                $Index = 0
                if ($Order) { $ReferenceNode.Names.foreach{ $Order[$_] = $Index++ } }
                $Index = 0
                foreach ($ObjectItem in $ObjectNode.ChildNodes) {
                    if ($ReferenceNode.Contains($ObjectItem.Name)) {
                        $ReferenceItem = $ReferenceNode.GetChildNode($ObjectItem.Name)
                        $Found[$ReferenceItem.Name] = $true
                        if ($Order -and $Order[$ReferenceItem.Name] -ne $Index) {
                            if ($IsEqual) { return $false }
                            [PSCustomObject]@{
                                Path        = $ObjectItem.PathName
                                Discrepancy = 'Index'
                                InputObject = $Index
                                Reference   = $Order[$ReferenceItem.Name]
                            }
                        }
                        $Compare = CompareObject -Reference $ReferenceItem -Object $ObjectItem
                        if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }
                    }
                    else {
                        if ($IsEqual) { return $false }
                        [PSCustomObject]@{
                            Path        = $ObjectItem.PathName
                            Discrepancy = 'Exists'
                            InputObject = $true
                            Reference   = $false
                        }
                    }
                    $Index++
                }
                $ReferenceNode.Names.foreach{
                    if (-not $Found.Contains($_)) {
                        if ($IsEqual) { return $false }
                        [PSCustomObject]@{
                            Path        = $ReferenceNode.GetChildNode($_).PathName
                            Discrepancy = 'Exists'
                            InputObject = $false
                            Reference   = $true
                        }
                    }
                }
            }
            else {
                if ($IsEqual) { return $false }
                [PSCustomObject]@{
                    Path        = $ObjectNode.PathName
                    Discrepancy = 'Structure'
                    InputObject = $ObjectNode.ValueType.Name
                    Reference   = $ReferenceNode.ValueType.Name
                }
            }            if ($IsEqual) { return $true }
        }
        $ReferenceNode = [PSNode]::ParseInput($Reference, $MaxDepth)
    }
    process {
        $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
        $Arguments = @{
            ReferenceNode = $ReferenceNode
            ObjectNode    = $ObjectNode
            PrimaryKey    = $PrimaryKey
            IsEqual       = $IsEqual
            MatchCase     = $MatchCase
            MatchType     = $MatchType
            MatchOrder    = $MatchOrder
        }
        CompareObject @Arguments
    }
}
