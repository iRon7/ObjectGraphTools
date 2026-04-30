Get-ChildItem $PSScriptRoot\..\Source\Cmdlets\*.ps1 | ForEach-Object {
    Write-Host $_
    Get-MarkdownHelp $_ | Out-File $PSScriptRoot\..\Docs\$($_.BaseName).md
}