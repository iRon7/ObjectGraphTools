<!-- markdownlint-disable MD033 -->
# Compare-ObjectGraph

Compare Object Graph

## Syntax

```PowerShell
Compare-ObjectGraph
    -InputObject <Object>
    -Reference <Object>
    [-PrimaryKey <String[]>]
    [-IsEqual]
    [-MatchCase]
    [-MatchType]
    [-IgnoreListOrder]
    [-MatchMapOrder]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Deep compares two Object Graph and lists the differences between them.

## Parameters

### <a id="-inputobject">**`-InputObject <Object>`**</a>

The input object that will be compared with the reference object (see: [-Reference](#-reference) parameter).

> [!NOTE]
> Multiple input object might be provided via the pipeline.
> The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
> To avoid a list of (root) objects to unroll, use the **comma operator**:

```PowerShell
,$InputObject | Compare-ObjectGraph $Reference.
```

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-reference">**`-Reference <Object>`**</a>

The reference that is used to compared with the input object (see: [-InputObject](#-inputobject) parameter).

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-primarykey">**`-PrimaryKey <String[]>`**</a>

If supplied, dictionaries (including PSCustomObject or Component Objects) in a list are matched
based on the values of the `-PrimaryKey` supplied.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">String[]</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-isequal">**`-IsEqual`**</a>

If set, the cmdlet will return a boolean (`$true` or `$false`).
As soon a Discrepancy is found, the cmdlet will immediately stop comparing further properties.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchcase">**`-MatchCase`**</a>

Unless the `-MatchCase` switch is provided, string values are considered case insensitive.

> [!NOTE]
> Dictionary keys are compared based on the `$Reference`.
> if the `$Reference` is an object (PSCustomObject or component object), the key or name comparison
> is case insensitive otherwise the comparer supplied with the dictionary is used.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchtype">**`-MatchType`**</a>

Unless the `-MatchType` switch is provided, a loosely (inclusive) comparison is done where the
`$Reference` object is leading. Meaning `$Reference -eq $InputObject`:

```PowerShell
'1.0' -eq 1.0 # $false
1.0 -eq '1.0' # $true (also $false if the `-MatchType` is provided)
```

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ignorelistorder">**`-IgnoreListOrder`**</a>

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchmaporder">**`-MatchMapOrder`**</a>

By default, items in dictionary (including properties of an PSCustomObject or Component Object) are
matched by their key name (independent of the order).
If the `-MatchMapOrder` switch is supplied, each entry is also validated by the position.

> [!NOTE]
> A `[HashTable]` type is unordered by design and therefore, regardless the `-MatchMapOrder` switch,
the order of the `[HashTable]` (defined by the `$Reference`) are always ignored.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-maxdepth">**`-MaxDepth <Int32>`**</a>

The maximal depth to recursively compare each embedded property (default: 10).

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">Int32</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[PSNode]::DefaultMaxDepth</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
