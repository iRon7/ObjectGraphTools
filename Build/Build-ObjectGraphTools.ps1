# . .\Build\Build-Module.ps1 -ModulePath .\ObjectGraphTools.psm1 -SourceFolder .\Source

$Params = @{
    ModulePath   = "$PSScriptRoot\..\ObjectGraphTools.psm1"
    SourceFolder = "$PSScriptRoot\..\Source"
}

. $PSScriptRoot\Build-Module.ps1 @Params -Verbose

# Remove-Module ObjectGraphTools -Force -ErrorAction SilentlyContinue
# Import-Module ObjectGraphTools -Force -ErrorAction SilentlyContinue
