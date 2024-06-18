<#
.SYNOPSIS
    Deserializes a PowerShell File or any object-graphs from PowerShell file to an object.

.DESCRIPTION
    The `Import-ObjectGraph` cmdlet safely converts a PowerShell formatted expression contained by a file
    to an object-graph existing of a mixture of nested arrays, hashtables and objects that contain a list
    of strings and values.

.PARAMETER Path
    Specifies the path to a file where `Import-ObjectGraph` imports the object-graph.
    Wildcard characters are permitted.

.PARAMETER LiteralPath
    Specifies a path to one or more locations that contain a PowerShell the object-graph.
    The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
    If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell
    PowerShell not to interpret any characters as escape sequences.

.PARAMETER LanguageMode
    Defines which object types are allowed for the deserialization, see: [About language modes][2]

    * Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,
      `[String]`, `[Array]` or `[HashTable]`.
    * Any variable that is not `$True`, `$False` or `$Null` will be converted to a literal string, e.g. `$Test`.

    The default `LanguageMode` is `Restricted` for PowerShell Data (`psd1`) files and `Constrained` for any
    other files, which usually concerns PowerShell (`.ps1`) files.

    > [!Caution]
    >
    > In full language mode, `ConvertTo-Expression` permits all type initializers. Cmdlets, functions,
    > CIM commands, and workflows will *not* be invoked by the `ConvertFrom-Expression` cmdlet.
    >
    > Take reasonable precautions when using the `Invoke-Expression -LanguageMode Full` command in scripts.
    > Verify that the class types in the expression are safe before instantiating them. In general, it is
    > best to design your configuration expressions with restricted or constrained classes, rather than
    > allowing full freeform expressions.

.PARAMETER ListAs
    If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown or
    denied type initializer will be converted to the given list type.

.PARAMETER MapAs
    If supplied, the array subexpression `@{ }` syntaxes without an type initializer or with an unknown or
    denied type initializer will be converted to the given map (dictionary or object) type.

    The default `MapAs` is an (ordered) `PSCustomObject` for PowerShell Data (`psd1`) files and
    a (unordered) `HashTable` for any other files, which usually concerns PowerShell (`.ps1`) files that
    support explicit type initiators.

.PARAMETER Encoding
    Specifies the type of encoding for the target file. The default value is `utf8NoBOM`.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"
#>

function Import-ObjectGraph {
    [CmdletBinding(DefaultParameterSetName='Path', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Import-ObjectGraph.md')]
    param(
        [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Path,

        [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath','LP')]
        [string[]]
        $LiteralPath,

        [ValidateNotNull()]$ListAs,

        [ValidateNotNull()]$MapAs,

        [ValidateScript({ $_ -ne 'NoLanguage' })]
        [System.Management.Automation.PSLanguageMode]$LanguageMode,

        [ValidateNotNullOrEmpty()]$Encoding
    )

    begin {
        $Extension = if ($Path) { [System.IO.Path]::GetExtension($Path) } else { [System.IO.Path]::GetExtension($LiteralPath) }
        if (-not $PSBoundParameters.ContainsKey('LanguageMode')) {
            $PSBoundParameters['LanguageMode'] = if ($Extension -eq '.psd1') { 'Restricted' } else { 'Constrained' }
        }
        if (-not $PSBoundParameters.ContainsKey('MapAs') -and $Extension -eq '.psd1') {
            $PSBoundParameters['MapAs'] = 'PSCustomObject'
        }

        $FromExpressionParameters = 'ListAs', 'MapAs', 'LanguageMode'
        $FromExpressionArguments = @{}
        $FromExpressionParameters.where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $FromExpressionArguments[$_] = $PSBoundParameters[$_] }
        $FromExpressionContext = $ExecutionContext.InvokeCommand.GetCommand('ObjectGraphTools\ConvertFrom-Expression', [System.Management.Automation.CommandTypes]::Cmdlet)
        $FromExpressionPipeline = { & $FromExpressionContext @FromExpressionArguments }.GetSteppablePipeline()
        $FromExpressionPipeline.Begin($True)

        $GetContentArguments = @{}
        @('Path', 'LiteralPath', 'Encoding').where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $GetContentArguments[$_] = $PSBoundParameters[$_] }
    }

    process {
        $Expression = Get-Content @GetContentArguments -Raw
        $FromExpressionPipeline.Process($Expression)
    }

    end {
        $FromExpressionPipeline.End()
    }
}

