<!-- markdownlint-disable MD033 -->
# ConvertTo-Expression

Serializes an object to a PowerShell expression.

## Syntax

```PowerShell
ConvertTo-Expression
    -InputObject <Object>
    [-LanguageMode <PSLanguageMode> = 'Restricted']
    [-ExpandDepth <Int32> = [Int]::MaxValue]
    [-Explicit]
    [-FullTypeName]
    [-HighFidelity]
    [-ExpandSingleton]
    [-Indent <String> = '    ']
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

The ConvertTo-Expression cmdlet converts (serializes) an object to a PowerShell expression.
The object can be stored in a variable, (.psd1) file or any other common storage for later use or to be ported
to another system.

expressions might be restored to an object using the native Invoke-Expression cmdlet:

```PowerShell
$Object = Invoke-Expression ($Object | ConvertTo-Expression)
```

Or using the [PSNode Object Parser][1] (*under construction*).

> [!Note]
> Some object types can not be constructed from a a simple serialized expression

## Parameter

### <a id="-inputobject">**`-InputObject <Object>`**</a>

Specifies the objects to convert to a PowerShell expression. Enter a variable that contains the objects,
or type a command or expression that gets the objects. You can also pipe one or more objects to
`ConvertTo-Expression.`

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-languagemode">**`-LanguageMode <PSLanguageMode>`**</a>

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

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.PSLanguageMode">PSLanguageMode</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>'Restricted'</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-expanddepth">**`-ExpandDepth <Int32>`**</a>

Defines up till what level the collections will be expanded in the output.

* A `-ExpandDepth 0` will create a single line expression.
* A `-ExpandDepth -1` will compress the single line by removing command spaces.

> [!Note]
> White spaces (as newline characters and spaces) will not be removed from the content
> of a (here) string.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">Int32</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[Int]::MaxValue</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-explicit">**`-Explicit`**</a>

By default, restricted language types initializers are suppressed.
When the `Explicit` switch is set, *all* values will be prefixed with an initializer
(as e.g. `[Long]` and `[Array]`)

> [!Note]
> The `-Explicit` switch can not be used in **restricted** language mode

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-fulltypename">**`-FullTypeName`**</a>

In case a value is prefixed with an initializer, the full type name of the initializer is used.

> [!Note]
> The `-FullTypename` switch can not be used in **restricted** language mode and will only be
> meaningful if the initializer is used (see also the [-Explicit](#-explicit) switch).

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-highfidelity">**`-HighFidelity`**</a>

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

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-expandsingleton">**`-ExpandSingleton`**</a>

(List or map) collections nodes that contain a single item will not be expanded unless this
`-ExpandSingleton` is supplied.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-indent">**`-Indent <String>`**</a>

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">String</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>'    '</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-maxdepth">**`-MaxDepth <Int32>`**</a>

Specifies how many levels of contained objects are included in the PowerShell representation.
The default value is define by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`).

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">Int32</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[PSNode]::DefaultMaxDepth</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Inputs

Any. Each objects provided through the pipeline will converted to an expression. To concatenate all piped
objects in a single expression, use the unary comma operator,  e.g.: `,$Object | ConvertTo-Expression`

## Outputs

String[]. `ConvertTo-Expression` returns a PowerShell [String](#string) expression for each input object.

## Related Links

* 1: [PowerShell Object Parser][1]
* 2: [About language modes][2]

[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
[2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
