$Expression = {
    Param($TestFolder)
    Import-Module $TestFolder\.. -Force
    Invoke-Pester $TestFolder
}.ToString()
PowerShell.exe -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"
Pwsh.exe       -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"