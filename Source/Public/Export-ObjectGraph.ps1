<#
.SYNOPSIS
    Serializes a PowerShell File or object-graph and exports it to a PowerShell (data) file.

.DESCRIPTION
    The `Export-ObjectGraph` cmdlet converts a PowerShell (complex) object to an PowerShell expression
    and exports it to a PowerShell (`.ps1`) file or a PowerShell data (`.psd1`) file.

.PARAMETER Path
    Specifies the path to a file where `Export-ObjectGraph` exports the ObjectGraph.
    Wildcard characters are permitted.

.PARAMETER LiteralPath
    Specifies a path to one or more locations where PowerShell should export the object-graph.
    The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
    If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell
    PowerShell not to interpret any characters as escape sequences.

.PARAMETER LanguageMode
    Defines which object types are allowed for the serialization, see: [About language modes][2]
    If a specific type isn't allowed in the given language mode, it will be substituted by:

    * **`$Null`** in case of a null value
    * **`$False`** in case of a boolean false
    * **`$True`** in case of a boolean true
    * **A number** in case of a primitive value
    * **A string** in case of a string or any other **leaf** node
    * `@(...)` for an array (**list** node)
    * `@{...}` for any dictionary, PSCustomObject or Component (aka **map** node)

    See the [PSNode Object Parser][1] for a detailed definition on node types.

.PARAMETER ExpandDepth
    Defines up till what level the collections will be expanded in the output.

    * A `-ExpandDepth 0` will create a single line expression.
    * A `-ExpandDepth -1` will compress the single line by removing command spaces.

    > [!Note]
    > White spaces (as newline characters and spaces) will not be removed from the content
    > of a (here) string.

.PARAMETER Explicit
    By default, restricted language types initializers are suppressed.
    When the `Explicit` switch is set, *all* values will be prefixed with an initializer
    (as e.g. `[Long]` and `[Array]`)

    > [!Note]
    > The `-Explicit` switch can not be used in **restricted** language mode

.PARAMETER FullTypeName
    In case a value is prefixed with an initializer, the full type name of the initializer is used.

    > [!Note]
    > The `-FullTypename` switch can not be used in **restricted** language mode and will only be
    > meaningful if the initializer is used (see also the [-Explicit] switch).

.PARAMETER HighFidelity
    If the `-HighFidelity` switch is supplied, all nested object properties will be serialized.

    By default the fidelity of an object expression will end if:

    1) the (embedded) object is a leaf node (see: [PSNode Object Parser][1])
    2) the (embedded) object expression is able to round trip.

    An object is able to roundtrip if the resulted expression of the object itself or one of
    its properties (prefixed with the type initializer) can be used to rebuild the object.

    The advantage of the default fidelity is that the resulted expression round trips (aka the
    object might be rebuild from the expression), the disadvantage is that information hold by
    less significant properties is lost (as e.g. timezone information in a `DateTime]` object).

    The advantage of the high fidelity switch is that all the information of the underlying
    properties is shown, yet any constrained or full object type will likely fail to rebuild
    due to constructor limitations such as readonly property.

    > [!Note]
    > Objects properties of type `[Reflection.MemberInfo]` are always excluded.

.PARAMETER ExpandSingleton
    (List or map) collections nodes that contain a single item will not be expanded unless this
    `-ExpandSingleton` is supplied.

.PARAMETER IndentSize
    Specifies indent used for the nested properties.

.PARAMETER MaxDepth
    Specifies how many levels of contained objects are included in the PowerShell representation.
    The default value is define by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`).

.PARAMETER Encoding
    Specifies the type of encoding for the target file. The default value is `utf8NoBOM`.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"
#>

function Export-ObjectGraph {
    [CmdletBinding(DefaultParameterSetName='Path', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Export-ObjectGraph.md')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Path,

        [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath','LP')]
        [string[]]
        $LiteralPath,

        [ValidateScript({ $_ -ne 'NoLanguage' })]
        [System.Management.Automation.PSLanguageMode]$LanguageMode,

        [Alias('Expand')][Int]$ExpandDepth = [Int]::MaxValue,

        [Switch]$Explicit,

        [Switch]$FullTypeName,

        [Switch]$HighFidelity,

        [Switch]$ExpandSingleton,

        [String]$Indent = '    ',

        [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth,

        [ValidateNotNullOrEmpty()]$Encoding
    )

    begin {
        $Extension = if ($Path) { [System.IO.Path]::GetExtension($Path) } else { [System.IO.Path]::GetExtension($LiteralPath) }
        if (-not $PSBoundParameters.ContainsKey('LanguageMode')) {
            $PSBoundParameters['LanguageMode'] = if ($Extension -eq '.psd1') { 'Restricted' } else { 'Constrained' }
        }

        $ToExpressionParameters = 'LanguageMode', 'ExpandDepth', 'Explicit', 'FullTypeName', '$HighFidelity', 'ExpandSingleton', 'Indent', 'MaxDepth'
        $ToExpressionArguments = @{}
        $ToExpressionParameters.where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $ToExpressionArguments[$_] = $PSBoundParameters[$_] }
        $ToExpressionContext = $ExecutionContext.InvokeCommand.GetCommand('ObjectGraphTools\ConvertTo-Expression', [System.Management.Automation.CommandTypes]::Cmdlet)
        $ToExpressionPipeline = { & $ToExpressionContext @ToExpressionArguments }.GetSteppablePipeline()
        $ToExpressionPipeline.Begin($True)

        $SetContentArguments = @{}
        @('Path', 'LiteralPath', 'Encoding').where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $SetContentArguments[$_] = $PSBoundParameters[$_] }
    }

    process {
        $Expression = $ToExpressionPipeline.Process($InputObject)
        Set-Content @SetContentArguments -Value $Expression
    }

    end {
        $ToExpressionPipeline.End()
    }
}

