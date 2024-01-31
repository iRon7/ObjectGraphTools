. $PSScriptRoot\Source\Private\Use-ClassAccessors.ps1
. $PSScriptRoot\Source\Classes\ObjectParser.ps1
. $PSScriptRoot\Source\Public\Compare-ObjectGraph.ps1
. $PSScriptRoot\Source\Public\Copy-ObjectGraph.ps1
. $PSScriptRoot\Source\Public\Get-ChildNode.ps1
. $PSScriptRoot\Source\Public\Get-Node.ps1
. $PSScriptRoot\Source\Public\Get-NodeWhere.ps1
. $PSScriptRoot\Source\Public\Merge-ObjectGraph.ps1
. $PSScriptRoot\Source\Public\Sort-ObjectGraph.ps1

$Parameters = @{
    Function = 'Compare-ObjectGraph', 'Copy-ObjectGraph', 'Get-ChildNode', 'Get-Node', 'Get-NodeWhere', 'Merge-ObjectGraph', 'ConvertTo-SortedObjectGraph'
    Alias    = 'Where-NodeValue', 'Sort-ObjectGraph'
}
Export-ModuleMember @Parameters
