<!-- markdownlint-disable MD033 -->
# Export-ObjectGraph

Serializes a PowerShell File or object-graph and exports it to a PowerShell (data) file.

## Syntax

```PowerShell
Export-ObjectGraph
    -Path <String[]>
    -InputObject <Object>
    [-LanguageMode <PSLanguageMode>]
    [-ExpandDepth <Int32> = [Int]::MaxValue]
    [-Explicit]
    [-FullTypeName]
    [-HighFidelity]
    [-ExpandSingleton]
    [-Indent <String> = '    ']
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [-Encoding <Object>]
    [<CommonParameters>]
```

```PowerShell
Export-ObjectGraph
    -LiteralPath <String[]>
    -InputObject <Object>
    [-LanguageMode <PSLanguageMode>]
    [-ExpandDepth <Int32> = [Int]::MaxValue]
    [-Explicit]
    [-FullTypeName]
    [-HighFidelity]
    [-ExpandSingleton]
    [-Indent <String> = '    ']
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [-Encoding <Object>]
    [<CommonParameters>]
```

## Description

The `Export-ObjectGraph` cmdlet converts a PowerShell (complex) object to an PowerShell expression
and exports it to a PowerShell (`.ps1`) file or a PowerShell data (`.psd1`) file.

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

```powershell
Name:                       -InputObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-path">`-Path` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">&lt;String[]&gt;</a></a>

Specifies the path to a file where `Export-ObjectGraph` exports the ObjectGraph.
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

Specifies a path to one or more locations where PowerShell should export the object-graph.
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

### <a id="-languagemode">`-LanguageMode` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.PSLanguageMode">&lt;PSLanguageMode&gt;</a></a>

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

### <a id="-expanddepth">`-ExpandDepth` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">&lt;Int32&gt;</a></a>

Defines up till what level the collections will be expanded in the output.

* A `-ExpandDepth 0` will create a single line expression.
* A `-ExpandDepth -1` will compress the single line by removing command spaces.

> [!Note]
> White spaces (as newline characters and spaces) will not be removed from the content
> of a (here) string.

```powershell
Name:                       -ExpandDepth
Aliases:                    -Expand
Type:                       [Int32]
Value (default):            [Int]::MaxValue
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-explicit">`-Explicit`</a>

By default, restricted language types initializers are suppressed.
When the `Explicit` switch is set, *all* values will be prefixed with an initializer
(as e.g. `[Long]` and `[Array]`)

> [!Note]
> The `-Explicit` switch can not be used in **restricted** language mode

```powershell
Name:                       -Explicit
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-fulltypename">`-FullTypeName`</a>

In case a value is prefixed with an initializer, the full type name of the initializer is used.

> [!Note]
> The `-FullTypename` switch can not be used in **restricted** language mode and will only be
> meaningful if the initializer is used (see also the [`-Explicit`](#-explicit) switch).

```powershell
Name:                       -FullTypeName
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-highfidelity">`-HighFidelity`</a>

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

```powershell
Name:                       -HighFidelity
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-expandsingleton">`-ExpandSingleton`</a>

(List or map) collections nodes that contain a single item will not be expanded unless this
`-ExpandSingleton` is supplied.

```powershell
Name:                       -ExpandSingleton
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-indent">`-Indent` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">&lt;String&gt;</a></a>

```powershell
Name:                       -Indent
Aliases:                    # None
Type:                       [String]
Value (default):            '    '
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-maxdepth">`-MaxDepth` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">&lt;Int32&gt;</a></a>

Specifies how many levels of contained objects are included in the PowerShell representation.
The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

```powershell
Name:                       -MaxDepth
Aliases:                    -Depth
Type:                       [Int32]
Value (default):            [PSNode]::DefaultMaxDepth
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
