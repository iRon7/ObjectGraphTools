$PublicFolder = Join-Path  'Source\Public'
$PSScripts = Get-ChildItem -Path $PublicFolder -Filter *.ps1

$Functions = 
    foreach ($PSScript in $PSScripts){
        $PSScript.Name
        . $PSScript.FullName
    }

# Export only the SSO functions 
Export-ModuleMember -Function $Functions
