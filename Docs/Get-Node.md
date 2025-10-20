<!-- markdownlint-disable MD033 -->
# Get-Node

Get a node

## Syntax

```PowerShell
Get-Node
    [-Path <Object>]
    [-Literal]
    -InputObject <Object>
    [-ValueOnly]
    [-Unique]
    [-MaxDepth <Int32>]
    [<CommonParameters>]
```

## Description

The Get-Node cmdlet gets the node at the specified property location of the supplied object graph.

## Examples

### <a id="example-1"><a id="example-parse-a-object-graph-to-a-node-instance">Example 1: Parse a object graph to a node instance</a></a>


The following example parses a hash table to `[PSNode]` instance:

```PowerShell
@{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node

PathName Name Depth Value
-------- ---- ----- -----
                    0 {My, Object}
```

### <a id="example-2"><a id="example-select-a-sub-node-in-an-object-graph">Example 2: select a sub node in an object graph</a></a>


The following example parses a hash table to `[PSNode]` instance and selects the second (`0` indexed)
item in the `My` map node

```PowerShell
@{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node My[1]

PathName Name Depth Value
-------- ---- ----- -----
My[1]       1     2     2
```

### <a id="example-3"><a id="example-change-the-price-of-the-powershell-book">Example 3: Change the price of the **PowerShell** book:</a></a>


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

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The concerned object graph or node.

```powershell
Name:                       -InputObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-path">`-Path` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

Specifies the path to a specific node in the object graph.
The path might be either:

* A dot-notation (`[String]`) literal or expression (as natively used with PowerShell)
* A array of strings (dictionary keys or Property names) and/or integers (list indices)
* A `[PSNodePath]` (such as `$Node.Path`) or a `[XdnPath]` (Extended Dot-Notation) object

```powershell
Name:                       -Path
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             Path
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-literal">`-Literal`</a>

If Literal switch is set, all (map) nodes in the given path are considered literal.

```powershell
Name:                       -Literal
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             Path
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-valueonly">`-ValueOnly`</a>

returns the value of the node instead of the node itself.

```powershell
Name:                       -ValueOnly
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-unique">`-Unique`</a>

Specifies that if a subset of the nodes has identical properties and values,
only a single node of the subset should be selected.

```powershell
Name:                       -Unique
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-maxdepth">`-MaxDepth` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">&lt;Int32&gt;</a></a>

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

```powershell
Name:                       -MaxDepth
Aliases:                    # None
Type:                       [Int32]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

## Related Links

* [PowerShell Object Parser](https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md)
* [Extended dot notation](https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Xdn.md)
<!-- -->


[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
[2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Xdn.md "Extended dot notation"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
