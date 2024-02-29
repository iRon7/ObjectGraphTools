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
    [-MatchOrder]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Deep compares two Object Graph and lists the differences between them.

## Parameter

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
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-reference">**`-Reference <Object>`**</a>

The reference that is used to compared with the input object (see: [-InputObject](#-inputobject) parameter).

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-primarykey">**`-PrimaryKey <String[]>`**</a>

If supplied, dictionaries (including PSCustomObject or Component Objects) in a list are matched
based on the values of the `-PrimaryKey` supplied.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-isequal">**`-IsEqual`**</a>

If set, the cmdlet will return a boolean (`$true` or `$false`).
As soon a Discrepancy is found, the cmdlet will immediately stop comparing further properties.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchcase">**`-MatchCase`**</a>

Unless the `-MatchCase` switch is provided, string values are considered case insensitive.

> [!NOTE]
> Dictionary keys are compared based on the `$Reference`.
> if the `$Reference` is an object (PSCustomObject or component object), the key or name comparison
> is case insensitive otherwise the comparer supplied with the dictionary is used.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
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
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchorder">**`-MatchOrder`**</a>

By default, items in a list and dictionary (including properties of an PSCustomObject or Component Object)
are matched independent of the order. If the `-MatchOrder` switch is supplied the index of the concerned
item (or property) is matched.

> [!NOTE]
> A `[HashTable]` type is unordered by design and therefore, regardless the `-MatchOrder` switch, the order
> of the `[HashTable]` are always ignored.

> [!NOTE]
> Regardless of the `-MatchOrder` switch, indexed (defined by the [PrimaryKey](#primarykey) parameter) dictionaries
(including PSCustomObject or Component Objects) in a list are matched independent of the order.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-maxdepth">**`-MaxDepth <Int32>`**</a>

The maximal depth to recursively compare each embedded property (default: 10).

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[PSNode]::DefaultMaxDepth</code></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
