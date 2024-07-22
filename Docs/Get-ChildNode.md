<!-- markdownlint-disable MD033 -->
# Get-ChildNode

Gets the child nodes of an object-graph

## Syntax

```PowerShell
Get-ChildNode
    -InputObject <Object>
    [-Recurse]
    [-AtDepth <Int32[]>]
    [-Leaf]
    [-IncludeSelf]
    [<CommonParameters>]
```

```PowerShell
Get-ChildNode
    [-ListChild]
    [<CommonParameters>]
```

```PowerShell
Get-ChildNode
    [-Include <String[]>]
    [-Exclude <String[]>]
    [-Literal]
    [<CommonParameters>]
```

## Description

Gets the (unique) nodes and child nodes in one or more specified locations of an object-graph
The returned nodes are unique even if the provide list of input parent nodes have an overlap.

## Examples

### Example 1: Select all leaf nodes in a object graph


Given the following object graph:

```PowerShell
$Object = @{
    Comment = 'Sample ObjectGraph'
    Data = @(
        @{
            Index = 1
            Name = 'One'
            Comment = 'First item'
        }
        @{
            Index = 2
            Name = 'Two'
            Comment = 'Second item'
        }
        @{
            Index = 3
            Name = 'Three'
            Comment = 'Third item'
        }
    )
}
```

The following example will receive all leaf nodes:

```PowerShell
$Object | Get-ChildNode -Recurse -Leaf

PathName         Name    Depth Value
--------         ----    ----- -----
.Data[0].Comment Comment     3 First item
.Data[0].Name    Name        3 One
.Data[0].Index   Index       3 1
.Data[1].Comment Comment     3 Second item
.Data[1].Name    Name        3 Two
.Data[1].Index   Index       3 2
.Data[2].Comment Comment     3 Third item
.Data[2].Name    Name        3 Three
.Data[2].Index   Index       3 3
.Comment         Comment     1 Sample ObjectGraph
```

### Example 2: update a property


The following example selects all child nodes named `Comment` at a depth of `3`.
Than filters the one that has an `Index` sibling with the value `2` and eventually
sets the value (of the `Comment` node) to: 'Two to the Loo'.

```PowerShell
$Object | Get-ChildNode -AtDepth 3 -Include Comment |
    Where-Object { $_.ParentNode.GetChildNode('Index').Value -eq 2 } |
    ForEach-Object { $_.Value = 'Two to the Loo' }

ConvertTo-Expression $Object

@{
    Data =
        @{
            Comment = 'First item'
            Name = 'One'
            Index = 1
        },
        @{
            Comment = 'Two to the Loo'
            Name = 'Two'
            Index = 2
        },
        @{
            Comment = 'Third item'
            Name = 'Three'
            Index = 3
        }
    Comment = 'Sample ObjectGraph'
}
```

See the [PowerShell Object Parser][1] For details on the `[PSNode]` properties and methods.

## Parameters

### <a id="-inputobject">**`-InputObject <Object>`**</a>

The concerned object graph or node.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-recurse">**`-Recurse`**</a>

Recursively iterates through all embedded property objects (nodes) to get the selected nodes.
The maximum depth of of a specific node that might be retrieved is define by the `MaxDepth`
of the (root) node. To change the maximum depth the (root) node needs to be loaded first, e.g.:

```PowerShell
Get-Node <InputObject> -Depth 20 | Get-ChildNode ...
```

(See also: [`Get-Node`][2])

> [!NOTE]
> If the [AtDepth](#atdepth) parameter is supplied, the object graph is recursively searched anyways
> for the selected nodes up till the deepest given `AtDepth` value.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-atdepth">**`-AtDepth <Int32[]>`**</a>

When defined, only returns nodes at the given depth(s).

> [!NOTE]
> The nodes below the `MaxDepth` can not be retrieved.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32[]">Int32[]</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-listchild">**`-ListChild`**</a>

Returns the closest nodes derived from a **list node**.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-include">**`-Include <String[]>`**</a>

Returns only nodes derived from a **map node** including only the ones specified by one or more
string patterns defined by this parameter. Wildcard characters are permitted.

> [!NOTE]
> The [-Include](#-include) and [-Exclude](#-exclude) parameters can be used together. However, the exclusions are applied
> after the inclusions, which can affect the final output.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">String[]</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-exclude">**`-Exclude <String[]>`**</a>

Returns only nodes derived from a **map node** excluding the ones specified by one or more
string patterns defined by this parameter. Wildcard characters are permitted.

> [!NOTE]
> The [-Include](#-include) and [-Exclude](#-exclude) parameters can be used together. However, the exclusions are applied
> after the inclusions, which can affect the final output.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">String[]</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-literal">**`-Literal`**</a>

The values of the [-Include](#-include) - and [-Exclude](#-exclude) parameters are used exactly as it is typed.
No characters are interpreted as wildcards.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-leaf">**`-Leaf`**</a>

Only return leaf nodes. Leaf nodes are nodes at the end of a branch and do not have any child nodes.
You can use the [-Recurse](#-recurse) parameter with the [-Leaf](#-leaf) parameter.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-includeself">**`-IncludeSelf`**</a>

Includes the current node with the returned child nodes.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Related Links

* 1: [PowerShell Object Parser][1]
* 2: [Get-Node][2]

[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
[2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Get-Node.md "Get-Node"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
