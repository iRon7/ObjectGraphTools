<!-- markdownlint-disable MD033 -->
# Import-ObjectGraph

Deserializes a PowerShell File or any object-graphs from PowerShell file to an object.

## Syntax

```PowerShell
Import-ObjectGraph
    -Path <String[]>
    [-ListAs <Object>]
    [-MapAs <Object>]
    [-LanguageMode <PSLanguageMode>]
    [-Encoding <Object>]
    [<CommonParameters>]
```

```PowerShell
Import-ObjectGraph
    -LiteralPath <String[]>
    [-ListAs <Object>]
    [-MapAs <Object>]
    [-LanguageMode <PSLanguageMode>]
    [-Encoding <Object>]
    [<CommonParameters>]
```

## Description

The `Import-ObjectGraph` cmdlet safely converts a PowerShell formatted expression contained by a file
to an object-graph existing of a mixture of nested arrays, hash tables and objects that contain a list
of strings and values.

## Parameters

### <a id="-path">`-Path` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">&lt;String[]&gt;</a></a>

Specifies the path to a file where `Import-ObjectGraph` imports the object-graph.
Wildcard characters are permitted.

```powershell
Name:                       -Path
Aliases:                    # None
Type:                       [String[]]
Value (default):            # Undefined
Parameter sets:             Path
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-literalpath">`-LiteralPath` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">&lt;String[]&gt;</a></a>

Specifies a path to one or more locations that contain a PowerShell the object-graph.
The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell
PowerShell not to interpret any characters as escape sequences.

```powershell
Name:                       -LiteralPath
Aliases:                    -PSPath, -LP
Type:                       [String[]]
Value (default):            # Undefined
Parameter sets:             LiteralPath
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-listas">`-ListAs` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown or
denied type initializer will be converted to the given list type.

```powershell
Name:                       -ListAs
Aliases:                    -ArrayAs
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-mapas">`-MapAs` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

If supplied, the array subexpression `@{ }` syntaxes without an type initializer or with an unknown or
denied type initializer will be converted to the given map (dictionary or object) type.

The default `MapAs` is an (ordered) `PSCustomObject` for PowerShell Data (`psd1`) files and
a (unordered) `HashTable` for any other files, which usually concerns PowerShell (`.ps1`) files that
support explicit type initiators.

```powershell
Name:                       -MapAs
Aliases:                    -DictionaryAs
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-languagemode">`-LanguageMode` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.PSLanguageMode">&lt;PSLanguageMode&gt;</a></a>

Defines which object types are allowed for the deserialization, see: [About language modes][2]

* Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,

```PowerShell
`[String]`, `[Array]` or `[HashTable]`.
```

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

```powershell
Name:                       -LanguageMode
Aliases:                    # None
Type:                       [PSLanguageMode]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-encoding">`-Encoding` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

Specifies the type of encoding for the target file. The default value is `utf8NoBOM`.

```powershell
Name:                       -Encoding
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

## Related Links

* [PowerShell Object Parser](https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md)
* [About language modes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes)
<!-- -->


[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
[2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
