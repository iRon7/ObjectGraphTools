<#
.SYNOPSIS
    Merges two object graphs into one

.DESCRIPTION
    Recursively merges two object graphs into a new object graph.

.PARAMETER InputObject
    The input object that will be merged with the template object (see: [-Template] parameter).

    > [!NOTE]
    > Multiple input object might be provided via the pipeline.
    > The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
    > To avoid a list of (root) objects to unroll, use the **comma operator**:

        ,$InputObject | Compare-ObjectGraph $Template.

.PARAMETER Template
    The template that is used to merge with the input object (see: [-InputObject] parameter).

.PARAMETER PrimaryKey
    In case of a list of dictionaries or PowerShell objects, the PowerShell key is used to
    link the items or properties: if the PrimaryKey exists on both the [-Template] and the
    [-InputObject] and the values are equal, the dictionary or PowerShell object will be merged.
    Otherwise (if the key can't be found or the values differ), the complete dictionary or
    PowerShell object will be added to the list.

    It is allowed to supply multiple primary keys where each primary key will be used to
    check the relation between the [-Template] and the [-InputObject].

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded property (default: 10).
#>

function Merge-ObjectGraph {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Scope = "Function", Justification = 'False positive')]
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(Mandatory = $true, Position=0)]
        $Template,

        [String[]]$PrimaryKey,

        [Switch]$MatchCase,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        function MergeObject ([PSNode]$TemplateNode, [PSNode]$ObjectNode, [String[]]$PrimaryKey, [Switch]$MatchCase) {
            if ($ObjectNode -is [PSListNode] -and $TemplateNode -is [PSListNode]) {
                $FoundIndices = [System.Collections.Generic.HashSet[int]]::new()
                $Type = if ($ObjectNode.Value.IsFixedSize) { [Collections.Generic.List[PSObject]] } else { $ObjectNode.Value.GetType() }
                $Output = New-Object -TypeName $Type
                $ObjectItems   = $ObjectNode.ChildNodes
                $TemplateItems = $TemplateNode.ChildNodes
                foreach($ObjectItem in $ObjectItems) {
                    $FoundNode = $False
                    foreach ($TemplateItem in $TemplateItems) {
                        if ($ObjectItem -is [PSLeafNode] -and $TemplateItem  -is [PSLeafNode]) {
                            $Equal = if ($MatchCase) { $TemplateItem.Value -ceq $ObjectItem.Value }
                                     else            { $TemplateItem.Value -eq  $ObjectItem.Value }
                            if ($Equal) {
                                $Output.Add($ObjectItem.Value)
                                $FoundNode = $True
                                $Null = $FoundIndices.Add($TemplateItem.Name)
                            }
                        }
                        elseif ($ObjectItem -is [PSMapNode] -and $TemplateItem -is [PSMapNode]) {
                            foreach ($Key in $PrimaryKey) {
                                if (-not $TemplateItem.Contains($Key) -or -not $ObjectItem.Contains($Key)) { continue }
                                if ($TemplateItem.GetChildNode($Key).Value -eq $ObjectItem.GetChildNode($Key).Value) {
                                    $Item = MergeObject -Template $TemplateItem -Object $ObjectItem -PrimaryKey $PrimaryKey -MatchCase $MatchCase
                                    $Output.Add($Item)
                                    $FoundNode = $True
                                    $Null = $FoundIndices.Add($TemplateItem.Name)
                                }
                            }
                        }
                    }
                    if (-not $FoundNode) { $Output.Add($ObjectItem.Value) }
                }
                foreach ($TemplateItem in $TemplateItems) {
                    if (-not $FoundIndices.Contains($TemplateItem.Name)) { $Output.Add($TemplateItem.Value) }
                }
                if ($ObjectNode.Value.IsFixedSize) { $Output = @($Output) }
                ,$Output
            }
            elseif ($ObjectNode -is [PSMapNode] -and $TemplateNode -is [PSMapNode]) {
                if ($ObjectNode -is [PSDictionaryNode]) { $Dictionary = New-Object -TypeName $ObjectNode.ValueType }     # The $InputObject defines the map type
                else { $Dictionary = [System.Collections.Specialized.OrderedDictionary]::new() }
                foreach ($ObjectItem in $ObjectNode.ChildNodes) {
                    if ($TemplateNode.Contains($ObjectItem.Name)) {                                                  # The $InputObject defines the comparer
                        $Value = MergeObject -Template $TemplateNode.GetChildNode($ObjectItem.Name) -Object $ObjectItem -PrimaryKey $PrimaryKey -MatchCase $MatchCase
                    }
                    else { $Value = $ObjectItem.Value }
                    $Dictionary.Add($ObjectItem.Name, $Value)
                }
                foreach ($Key in $TemplateNode.Names) {
                    if (-not $Dictionary.Contains($Key)) { $Dictionary.Add($Key, $TemplateNode.GetChildNode($Key).Value) }
                }
                if ($ObjectNode -is [PSDictionaryNode]) { $Dictionary } else { [PSCustomObject]$Dictionary }
            }
            else { return $ObjectNode.Value }
        }
        $TemplateNode = [PSNode]::ParseInput($Template, $MaxDepth)
    }
    process {
        $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
        MergeObject $TemplateNode $ObjectNode -PrimaryKey $PrimaryKey -MatchCase $MatchCase
    }
}
