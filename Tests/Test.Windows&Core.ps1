$Expression = {
    Param($TestFolder)
    Write-Host
    Write-Host "Testing with PowerShell version $($PSVersionTable.PSVersion)"
    Import-Module $TestFolder\.. -Force
    Invoke-Pester $TestFolder
}.ToString()
PowerShell.exe -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"
Pwsh.exe       -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"