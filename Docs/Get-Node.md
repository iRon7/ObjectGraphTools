<!-- markdownlint-disable MD033 -->
# Get-Node

Get a node

## Syntax

```PowerShell
Get-Node
    -InputObject <Object>
    [-MaxDepth <Int32>]
    [<CommonParameters>]
```

```PowerShell
Get-Node
    [-Path <Object>]
    [-Literal]
    [<CommonParameters>]
```

## Description

The Get-Node cmdlet gets the node at the specified property location of the supplied object graph.

## Examples

### Example 1: Parse a object graph to a node instance


The following example parses a hash table to `[PSNode]` instance:

```PowerShell
@{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node

PathName Name Depth Value
-------- ---- ----- -----
                  0 {My, Object}
```

### Example 2: select a sub node in an object graph


The following example parses a hash table to `[PSNode]` instance and selects the second (`0` indexed)
item in the `My` map node

```PowerShell
@{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node My[1]

PathName Name Depth Value
-------- ---- ----- -----
My[1]       1     2     2
```

### Example 3: Change the price of the **PowerShell** book:


```PowerShell
$ObjectGraph =
    @{
        BookStore = @(
            @{
                Book = @{
                    Title = 'Harry Potter'
                    Price = 29.99
                }
            },
            @{
                Book = @{
                    Title = 'Learning PowerShell'
                    Price = 39.95
                }
            }
        )
    }

($ObjectGraph | Get-Node BookStore~Title=*PowerShell*..Price).Value = 24.95
$ObjectGraph | ConvertTo-Expression
@{
    BookStore = @(
        @{
            Book = @{
                Price = 29.99
                Title = 'Harry Potter'
            }
        },
        @{
            Book = @{
                Price = 24.95
                Title = 'Learning PowerShell'
            }
        }
    )
}
```

for more details, see: [PowerShell Object Parser][1] and [Extended dot notation][2]

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

### <a id="-path">**`-Path <Object>`**</a>

Specifies the path to a specific node in the object graph.
The path might be either:

* A dot-notation (`[String]`) literal or expression (as natively used with PowerShell)
* A array of strings (dictionary keys or Property names) and/or integers (list indices)
* A `[PSNodePath]` (such as `$Node.Path`) or a `[XdnPath]` (Extended Dot-Notation) object

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-literal">**`-Literal`**</a>

If Literal switch is set, all (map) nodes in the given path are considered literal.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
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
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">Int32</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Related Links

* 1: [PowerShell Object Parser][1]
* 2: [Extended dot notation][2]

[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
[2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/XdnPath.md "Extended dot notation"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
