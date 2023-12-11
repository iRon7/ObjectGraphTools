<!-- markdownlint-disable MD033 -->
# Compare-ObjectGraph

Compare Object Graph

## Syntax

```JavaScript
    -InputObject <Object>
    -Reference <Object>
    [-IsEqual]
    [-MatchCase]
    [-MatchType]
    [-MatchObjectOrder]
    [-IgnoreArrayOrder]
    [-IgnoreListOrder]
    [-IgnoreDictionaryOrder]
    [-IgnorePropertyOrder]
    [-MaxDepth <Int32> = 10]
    [<CommonParameters>]
```

## Description

Recursively compares two Object Graph and lists the differences between them.

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

### <a id="-matchobjectorder">**`-MatchObjectOrder`**</a>

Whether a list (or array) is treated as ordered is defined by the `$Reference`.
Unless the `-MatchObjectOrder` switch is provided, the order of an object array (`@(...)` aka `Object[]`)
is presumed unordered. This means that `Compare-ObjectGraph` cmdlet will try to match each item of an
`$InputObject` list which each item in the `$Reference` list.

If there is a single discrepancy on each side, the properties will be compared deeper, otherwise a
list with different items will be returned.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ignorearrayorder">**`-IgnoreArrayOrder`**</a>

Whether a list (or array) is treated as ordered is defined by the `$Reference`.
Unless the `-IgnoreArrayOrder` switch is provided, the order of an array (e.g. `[String[]]('a', b', 'c')`,
excluding an object array, see: [-MatchObjectOrder](#-matchobjectorder)), is presumed ordered.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ignorelistorder">**`-IgnoreListOrder`**</a>

Whether a list is treated as ordered is defined by the `$Reference`.
Unless the `-IgnoreListOrder` switch is provided, the order of a list
(e.g. `[Collections.Generic.List[Int]](1, 2, 3)`), is presumed ordered.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ignoredictionaryorder">**`-IgnoreDictionaryOrder`**</a>

Whether a dictionary is treated as ordered is defined by the `$Reference`.
Unless the `-IgnoreDictionaryOrder` switch is provided, the order of a dictionary is presumed ordered.

> [!WARNING]
> A `[HashTable]` type is unordered by design and therefore the order of a `$Reference` hash table
> in always ignored

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ignorepropertyorder">**`-IgnorePropertyOrder`**</a>

Whether the properties are treated as ordered is defined by the `$Reference`.
Unless the `-IgnorePropertyOrder` switch is provided, the property order is presumed ordered.

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
<tr><td>Default value:</td><td><code>10</code></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>
