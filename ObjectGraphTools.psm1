. "$PSScriptRoot\Source\Classes\ObjectParser.ps1"
. "$PSScriptRoot\Source\Public\Compare-ObjectGraph.ps1"
. "$PSScriptRoot\Source\Public\Copy-ObjectGraph.ps1"
. "$PSScriptRoot\Source\Public\Merge-ObjectGraph.ps1"
. "$PSScriptRoot\Source\Public\Sort-ObjectGraph.ps1"

$Parameters = @{
    Function = 'Compare-ObjectGraph', 'Copy-ObjectGraph', 'Merge-ObjectGraph', 'ConvertTo-SortedObjectGraph'
    Alias    = 'Sort-ObjectGraph'
}
Export-ModuleMember @Parameters
