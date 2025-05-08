$Expression = {
    Param($TestFolder)
    $Version = $PSVersionTable.PSVersion
    Import-Module $TestFolder\.. -Force
    Get-ChildItem -Path $TestFolder -Filter *.Tests.ps1 |
    ForEach-Object { 
        $InformationRecord = . $_.FullName *>&1
        foreach ($Message in $InformationRecord.MessageData.Message) {
            if ($Message -match '^\S*\[\+\]') {
                Write-Host -NoNewline "$Version "
                Write-Host -ForegroundColor Green $_.BaseName
            }
            elseif ($Message -match '^\S*\[-\]([^\r\n]*)') {
                Write-Host -NoNewline "$Version "
                Write-Host -ForegroundColor Red "$($_.BaseName) $($Matches[1])"
            }
        }
    }
}.ToString()
PowerShell.exe -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"
Pwsh.exe       -NoProfile -Command "& {$Expression} -TestFolder '$PSScriptRoot'"