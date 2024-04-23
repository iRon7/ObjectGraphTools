<!-- markdownlint-disable MD033 -->
# Import-ObjectGraph

Deserializes a PowerShell File or any object-graphs from PowerShell file to an object.

## Syntax

```PowerShell
Import-ObjectGraph
    -Path <String[]>
    [<CommonParameters>]
```

```PowerShell
Import-ObjectGraph
    -LiteralPath <String[]>
    [<CommonParameters>]
```

```PowerShell
Import-ObjectGraph
    [-ArrayAs <Object>]
    [-HashTableAs <Object>]
    [-LanguageMode <PSLanguageMode>]
    [-Encoding <Object>]
    [<CommonParameters>]
```

## Description

The `Import-ObjectGraph` cmdlet safely converts a PowerShell formatted expression contained by a file
to an object-graph existing of a mixture of nested arrays, hashtables and objects that contain a list
of strings and values.

## Parameter

### <a id="-path">**`-Path <String[]>`**</a>

Specifies the path to a file where `Import-ObjectGraph` imports the object-graph.
Wildcard characters are permitted.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">String[]</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-literalpath">**`-LiteralPath <String[]>`**</a>

Specifies a path to one or more locations that contain a PowerShell the object-graph.
The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell
PowerShell not to interpret any characters as escape sequences.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">String[]</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-arrayas">**`-ArrayAs <Object>`**</a>

If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown or
denied type initializer will be converted to the given list type.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-hashtableas">**`-HashTableAs <Object>`**</a>

If supplied, the array subexpression `@{ }` syntaxes without an type initializer or with an unknown or
denied type initializer will be converted to the given map (dictionary or object) type.

The default `HashTableAs` is an (ordered) `PSCustomObject` for PowerShell Data (`psd1`) files and
a (unordered) `HashTable` for any other files, which usually concerns PowerShell (`.ps1`) files that
support explicit type initiators.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-languagemode">**`-LanguageMode <PSLanguageMode>`**</a>

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

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.PSLanguageMode">PSLanguageMode</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-encoding">**`-Encoding <Object>`**</a>

Specifies the type of encoding for the target file. The default value is `utf8NoBOM`.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Related Links

* 1: [PowerShell Object Parser][1]
* 2: [About language modes][2]

[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
[2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
