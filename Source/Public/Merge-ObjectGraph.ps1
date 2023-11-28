<#
.SYNOPSIS
    Merges two object graphs into one

.DESCRIPTION
    Merges two object graphs into one
    
#>

function Merge-ObjectGraph {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Scope = "Function", Justification = 'False positive')]
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory=$true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(Mandatory=$true, Position=0)]
        $Template,

        [String[]]$PrimaryKey,

        [Switch]$MatchCase,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        [PSNode]::MaxDepth = $MaxDepth
        function MergeObject ([PSNode]$TemplateNode, [PSNode]$ObjectNode) {
            if ($ObjectNode.Structure -ne $TemplateNode.Structure) { return $ObjectNode.Value }
            elseif ($ObjectNode.Structure -eq 'Scalar')        { return $ObjectNode.Value }
            elseif ($ObjectNode.Structure -eq 'List') {
                $FoundIndices = [System.Collections.Generic.HashSet[int]]::new()
                $Type = if ($ObjectNode.Value.IsFixedSize) { [Collections.Generic.List[PSObject]] } else { $ObjectNode.Value.GetType() }
                $Output = New-Object -TypeName $Type
                $TemplateItems = $TemplateNode.GetItemNodes()
                foreach($ObjectItem in $ObjectNode.GetItemNodes()) {
                    $FoundNode = $False
                    foreach ($TemplateItem in $TemplateItems) {
                        if ($ObjectItem.Structure -eq $TemplateItem.Structure) {
                            if ($ObjectItem.Structure -eq 'Scalar') {
                                $Equal = if ($MatchCase) { $TemplateItem.Value -ceq $ObjectItem.Value } 
                                         else            { $TemplateItem.Value -eq  $ObjectItem.Value }
                                if ($Equal) {
                                    $Output.Add($ObjectItem.Value)
                                    $FoundNode = $True
                                    $Null = $FoundIndices.Add($TemplateItem.Index)
                                }
                            }
                            elseif ($ObjectItem.Structure -eq 'Dictionary') {
                                foreach ($Key in $PrimaryKey) {
                                    if (-not $TemplateItem.Contains($Key) -or -not $ObjectItem.Contains($Key)) { continue }
                                    if ($TemplateItem.Get($Key) -eq $ObjectItem.Get($Key)) {
                                        $Item = MergeObject -Template $TemplateItem -Object $ObjectItem
                                        $Output.Add($Item)
                                        $FoundNode = $True
                                        $Null = $FoundIndices.Add($TemplateItem.Index)
                                    }
                                }                                        
                            }
                        }
                    }
                    if (-not $FoundNode) { $Output.Add($ObjectItem.Value) }
                }
                foreach ($TemplateItem in $TemplateItems) {
                    if (-not $FoundIndices.Contains($TemplateItem.Index)) { $Output.Add($TemplateItem.Value) }
                }
                if ($ObjectNode.Value.IsFixedSize) { $Output = @($Output) }
                ,$Output
            }
            elseif ($ObjectNode.Structure -eq 'Dictionary') {
                $PSNode = $ObjectNode.Renew()                                                   # The $InputObject defines the dictionary (or PSCustomObject) type
                foreach ($ObjectItem in $ObjectNode.GetItemNodes()) {                                  # The $InputObject order takes president
                    if ($TemplateNode.Contains($ObjectItem.Key)) {
                        $Value = MergeObject -Template $TemplateNode.GetItemNode($ObjectItem.Key) -Object $ObjectItem
                    }
                    else { $Value = $ObjectNode.Value }
                    $PSNode.Set($ObjectItem.Key, $Value)
                }
                foreach ($Key in $TemplateNode.get_Keys()) {
                    if (-not $PSNode.Contains($Key)) { $PSNode.Set($Key, $TemplateNode.Get($Key)) }
                }
                $PSNode.Value
            }
        }
    }
    process {
        MergeObject $Template $InputObject $MaxDepth
    }
}
