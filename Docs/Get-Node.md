<!-- markdownlint-disable MD033 -->
# Get-Node

Get a node

## Syntax

```PowerShell
Get-Node
    -InputObject <Object>
    [-Path <Object>]
    [-MaxDepth <Int32>]
    [<CommonParameters>]
```

## Description

The Get-Node cmdlet gets the node at the specified property location of the supplied object graph.

## Examples

### Example 1: Parse a object graph to a node instance

```

The following example parses a hash table to `[PSNode]` instance:

```PowerShell
Get-Node @{ 'My' = 1, 2, 3; 'Object' = 'Graph' }

PathName Name Depth Value
-------- ---- ----- -----
                  0 {My, Object}
```

### Example 2: select a sub node in an object graph

```

The following example parses a hash table to `[PSNode]` instance and selects the second (`0` indexed)
item in the `My` map node

```PowerShell
'.My[1]' | Get-Node @{ 'My' = 1, 2, 3; 'Object' = 'Graph' }

PathName Name Depth Value
-------- ---- ----- -----
.My[1]      1     2     2
```

## Parameter

### <a id="-inputobject">**`-InputObject <Object>`**</a>

The concerned object graph or node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-path">**`-Path <Object>`**</a>

Specifies the path to a specific node in the object graph.
The path might be either:

* As [String](#string) a "dot-property" selection as defined by the `PathName` property a specific node.
* A array of strings (dictionary keys or Property names) and/or Integers (list indices).
* A object (`PSNode[]`) list where each `Name` property defines the path

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-maxdepth">**`-MaxDepth <Int32>`**</a>

Specifies the maximum depth that an object graph might be recursively iterated before it throws an error.
The failsafe will prevent infinitive loops for circular references as e.g. in:

```PowerShell
$Test = @{Guid = New-Guid}
$Test.Parent = $Test
```

The default `MaxDepth` is defined by `[PSNode]::DefaultMaxDepth = 10`.

> [!Note]
> The `MaxDepth` is bound to the root node of the object graph. Meaning that a descendant node
> at depth of 3 can only recursively iterated (`10 - 3 =`) `7` times.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
