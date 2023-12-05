<!-- markdownlint-disable MD033 -->
# Sort-ObjectGraph

Sort object graph

## Syntax

```JavaScript
    -InputObject <Object>
    [-PrimaryKey <String[]>]
    [-MatchCase]
    [-Descending]
    [-MaxDepth <Int32> = 10]
    [<CommonParameters>]
```

## Description

Recursively sorts a object graph.

## Parameter

### <a id="-inputobject">**`-InputObject <Object>`**</a>

The input object that will be recursively sorted.

> [!NOTE]
> Multiple input object might be provided via the pipeline.
> The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
> To avoid a list of (root) objects to unroll, use the **comma operator**:

```PowerShell
,$InputObject | Sort-Object.
```

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-primarykey">**`-PrimaryKey <String[]>`**</a>

Any primary key defined by the [-PrimaryKey](#-primarykey) parameter will be put on top of [-InputObject](#-inputobject)
independent of the (descending) sort order.

It is allowed to supply multiple primary keys.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchcase">**`-MatchCase`**</a>

Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-descending">**`-Descending`**</a>

Indicates that Sort-Object sorts the objects in descending order. The default is ascending order.

> [!NOTE]
> Primary keys (see: [-PrimaryKey](#-primarykey)) will always put on top.

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
