<!-- markdownlint-disable MD033 -->
# ConvertFrom-Expression

Deserializes a PowerShell expression to an object.

## Syntax

```PowerShell
ConvertFrom-Expression
    -InputObject <String>
    [-LanguageMode <PSLanguageMode> = 'Restricted']
    [<CommonParameters>]
```

## Description

The `ConvertFrom-Expression` cmdlet converts a PowerShell formatted expression to an object-graph existing of
a mixture of nested arrays, hashtables and objects that contain a list of strings and values.

## Parameter

### <a id="-inputobject">**`-InputObject <String>`**</a>

Specifies the PowerShell expressions to convert to objects. Enter a variable that contains the string,
or type a command or expression that gets the string. You can also pipe a string to ConvertFrom-Expression.

The **InputObject** parameter is required, but its value can be an empty string.
The **InputObject** value can't be `$null` or an empty string.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">String</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
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

> [!Caution]
>
> In full language mode the concerned string will simply be invoke using [`Invoke-Expression`](https://go.microsoft.com/fwlink/?LinkID=2097030).
>
> Take reasonable precautions when using the Invoke-Expression cmdlet in scripts. When using
> `-LanguageMode Full` to run a command that the user enters, verify that the command is safe to run
> before running it. In general, it is best to design your script with predefined input options,
> rather than allowing freeform input.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.PSLanguageMode">PSLanguageMode</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>'Restricted'</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
