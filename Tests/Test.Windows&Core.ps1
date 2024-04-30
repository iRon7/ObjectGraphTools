Import-Module $PSScriptRoot\.. -Force

$Expression = {
    Param($TestFolder)
    Write-Host
    Write-Host "Testing with PowerShell version $($PSVersionTable.PSVersion)"
    # $ProjectFolder = (Get-Item $TestFolder).Parent.Parent.FullName
    # [Environment]::SetEnvironmentVariable('PSModulePath', ($ProjectFolder, $Env:PSModulePath -Join ';'), 'Process')
    # Import-Module ObjectGraphTools
    Import-Module $TestFolder\.. -Force
    Invoke-Pester $TestFolder
}.ToString()
PowerShell.exe -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"
Pwsh.exe       -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"