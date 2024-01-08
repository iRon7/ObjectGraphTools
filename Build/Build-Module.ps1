$ModuleRoot = Get-Item $PSScriptRoot\..

$SourceFolder = Join-Path $ModuleRoot 'Source'

$Functions = [Collections.Generic.List[String]]::new()
$Aliases   = [Collections.Generic.List[String]]::new()
$Classes   = [Collections.Generic.List[String]]::new()

$PSScripts = Get-ChildItem -Path $SourceFolder -Filter *.ps1 -Recurse
$PSM1 = @(
    $PSScripts.foreach{
        $SubPath = $_.FullName.SubString($ModuleRoot.FullName.Length)
        ". ""`$PSScriptRoot$SubPath"""
        . $_.FullName
        if ($_.Directory.Name -eq 'Public') {
            $Command = Get-Command $_.BaseName
            if ($Command -is [System.Management.Automation.AliasInfo]){ $Command = $Command.ResolvedCommand }
            if ($Command) {
                $Functions.Add($Command.Name)
                Get-Alias -Definition $Command.Name  -ErrorAction SilentlyContinue | ForEach-Object { $Aliases.Add($_.Name) }
            }
            else {
                Write-Error "Expected the script $RelativePath to contain a function or alias with the same name: $($_.BaseName)"
            }
        }
        elseif ($_.Directory.Name -eq 'Classes') {
            $Classes.Add(".$SubPath")
        }
    }
    if ($Functions.Count) {
@"

`$Parameters = @{
    Function = $(@($Functions).foreach{ "'$_'" } -Join ', ')
    Alias    = $(@($Aliases).foreach{ "'$_'" }   -Join ', ')
}
Export-ModuleMember @Parameters
"@
    }
    else {
        Write-Error "No source functions found"
    }
)

$PSM1 | Set-Content $ModuleRoot\ObjectGraphTools.psm1

function UpdateSetting([string]$DataExpression, [string]$Name, [string]$ValueExpression) {
    $Ast = [System.Management.Automation.Language.Parser]::ParseInput($DataExpression, [ref]$Null, [ref]$Null)
    $ValueExtent = $Ast.EndBlock.Statements.PipelineElements.Expression.KeyValuePairs.where{ $_.Item1.Value -eq $Name }.Item2.Extent
    if ($ValueExtent) {
        $DataExpression.SubString(0, $ValueExtent.StartOffset) + $ValueExpression + $DataExpression.SubString($ValueExtent.EndOffset)
    }
    else {
        Write-Error "No setting found with name $Name"
    }
}

$PSD1 = Import-PowerShellDataFile -LiteralPath $ModuleRoot\ObjectGraphTools.psd1

$UpdatePSD1 = $Null
$PSGalleryModule = Find-Module -Name ObjectGraphTools -Repository PSGallery -ErrorAction SilentlyContinue
if (-Not $PSGalleryModule) {
    Write-Error 'Could not find PowerShell Gallery module: ObjectGraphTools'
}
elseif ($PSD1.ModuleVersion -le $PSGalleryModule.Version) {
    $Version = [Version]::new($PSGalleryModule.Version.Major, $PSGalleryModule.Version.Minor, $PSGalleryModule.Version.Build + 1)
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'ModuleVersion' "'$Version'"
}
if ($PSD1.ScriptsToProcess | Compare-Object $Classes) {
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw -LiteralPath $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'ScriptsToProcess' "@($(@($Classes).foreach{ "'$_'" } -Join ', '))"
}
if ($PSD1.FunctionsToExport | Compare-Object $Functions) {
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw -LiteralPath $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'FunctionsToExport' "@($(@($Functions).foreach{ "'$_'" } -Join ', '))"
}
if ($PSD1.AliasesToExport | Compare-Object $Aliases) {
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw -LiteralPath $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'AliasesToExport' "@($(@($Aliases).foreach{ "'$_'" } -Join ', '))"
}
if ($UpdatePSD1) { $UpdatePSD1 | Set-Content -LiteralPath $ModuleRoot\ObjectGraphTools.psd1}
