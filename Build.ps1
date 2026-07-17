#requires -module PSMBuilder

$Params = @{
    ModulePath   = "$PSScriptRoot\ObjectGraphTools.psm1"
    SourceFolder = "$PSScriptRoot\Source"
}

Build-Module @Params -Verbose

