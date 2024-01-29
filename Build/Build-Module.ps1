$ModuleRoot = Get-Item $PSScriptRoot\..

$SourceFolder = Join-Path $ModuleRoot 'Source'

$PSModule  = [Collections.Generic.List[String]]::new()
$ToProcess = [Collections.Generic.List[String]]::new()
$Functions = [Collections.Generic.List[String]]::new()
$Aliases   = [Collections.Generic.List[String]]::new()

Get-ChildItem -Path $SourceFolder\Private -Filter *.ps1 | Foreach-Object {
    . $_.FullName
    $TrailingPath = $_.FullName.SubString($ModuleRoot.FullName.Length)
    $PSModule.Add(". `$PSScriptRoot$TrailingPath")
    $ToProcess.Add(".$TrailingPath")
}

Get-ChildItem -Path $SourceFolder\Classes -Filter *.ps1 | Foreach-Object {
    . $_.FullName
    $TrailingPath = $_.FullName.SubString($ModuleRoot.FullName.Length)
    $PSModule.Add(". `$PSScriptRoot$TrailingPath")
    $ToProcess.Add(".$TrailingPath")
}

Get-ChildItem -Path $SourceFolder\Public -Filter *.ps1 | Foreach-Object {
    . $_.FullName
    $TrailingPath = $_.FullName.SubString($ModuleRoot.FullName.Length)
    $PSModule.Add(". `$PSScriptRoot$TrailingPath")
    $Command = Get-Command $_.BaseName
    if ($Command -is [System.Management.Automation.AliasInfo]){ $Command = $Command.ResolvedCommand }
    if ($Command) {
        $Functions.Add($Command.Name)
        Get-Alias -Definition $Command.Name -ErrorAction SilentlyContinue | ForEach-Object { $Aliases.Add($_.Name) }
    }
    else {
        Write-Error "Expected the script $RelativePath to contain a function or alias with the same name: $($_.BaseName)"
    }
}

if ($Functions.Count) {
    $PSModule.Add("
`$Parameters = @{
    Function = $(@($Functions).foreach{ "'$_'" } -Join ', ')
    Alias    = $(@($Aliases).foreach{ "'$_'" }   -Join ', ')
}
Export-ModuleMember @Parameters")
}
else {
    Write-Error "No source functions found"
}

$PSModule | Set-Content $ModuleRoot\ObjectGraphTools.psm1

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
if (Compare-Object $ToProcess $PSD1.ScriptsToProcess) {
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw -LiteralPath $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'ScriptsToProcess' "@($(@($ToProcess).foreach{ "'$_'" } -Join ', '))"
}
if (Compare-Object $Functions $PSD1.FunctionsToExport) {
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw -LiteralPath $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'FunctionsToExport' "@($(@($Functions).foreach{ "'$_'" } -Join ', '))"
}
if (Compare-Object $Aliases $PSD1.AliasesToExport) {
    if (-not $UpdatePSD1) { $UpdatePSD1 = Get-Content -Raw -LiteralPath $ModuleRoot\ObjectGraphTools.psd1 }
    $UpdatePSD1 = UpdateSetting $UpdatePSD1 'AliasesToExport' "@($(@($Aliases).foreach{ "'$_'" } -Join ', '))"
}
if ($UpdatePSD1) { $UpdatePSD1 | Set-Content -LiteralPath $ModuleRoot\ObjectGraphTools.psd1}
