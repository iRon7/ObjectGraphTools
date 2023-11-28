$SourceFolder = Join-Path $PSScriptRoot 'Source'
$Scripts = Get-ChildItem -Path $SourceFolder -Filter *.ps1 -Recurse

$Functions = $Scripts.foreach{
        . $_.FullName
        if ($_.Directory.Name -eq 'Public') { $_.BaseName }
    }

Export-ModuleMember -Function $Functions
