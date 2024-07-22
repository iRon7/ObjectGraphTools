<!-- markdownlint-disable MD033 -->
# ConvertTo-SortedObjectGraph

Sort object graph

## Syntax

```PowerShell
ConvertTo-SortedObjectGraph
    -InputObject <Object>
    [-PrimaryKey <String[]>]
    [-MatchCase]
    [-Descending]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Recursively sorts a object graph.

## Parameters

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
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-primarykey">**`-PrimaryKey <String[]>`**</a>

Any primary key defined by the [-PrimaryKey](#-primarykey) parameter will be put on top of [-InputObject](#-inputobject)
independent of the (descending) sort order.

It is allowed to supply multiple primary keys.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">String[]</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-matchcase">**`-MatchCase`**</a>

(Alias `-CaseSensitive`) Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-descending">**`-Descending`**</a>

Indicates that Sort-Object sorts the objects in descending order. The default is ascending order.

> [!NOTE]
> Primary keys (see: [-PrimaryKey](#-primarykey)) will always put on top.

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
