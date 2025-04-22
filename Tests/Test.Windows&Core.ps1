$Expression = {
    Param($TestFolder)
    Write-Host
    Write-Host "Testing with PowerShell version $($PSVersionTable.PSVersion)"
    Import-Module $TestFolder\.. -Force
    $TestFiles = Get-ChildItem -Path $TestFolder -Filter *.Tests.ps1
    foreach ($TestFile in $TestFiles) {
        Write-Host "Running $($TestFile.Name)"
        . $TestFile.FullName
    }
}.ToString()
PowerShell.exe -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"
Pwsh.exe       -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"