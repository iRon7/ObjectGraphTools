using module ..\..\ObjectGraphTools
Get-ChildItem $PSScriptRoot\..\Source\Public\*.ps1 | ForEach-Object {
    Write-Host $_
    Get-MarkdownHelp $_ | Out-File -Encoding ASCII $PSScriptRoot\..\Docs\$($_.BaseName).md
}