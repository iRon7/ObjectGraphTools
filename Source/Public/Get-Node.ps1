Using NameSpace System.Management.Automation.Language

<#
.SYNOPSIS
    Get a node

.DESCRIPTION
    The Get-Node cmdlet gets the node at the specified property location of the supplied object graph.

.EXAMPLE
    # Parse a object graph to a node instance

    The following example parses a hash table to `[PSNode]` instance:

        @{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node

        PathName Name Depth Value
        -------- ---- ----- -----
                          0 {My, Object}

.EXAMPLE
    # select a sub node in an object graph

    The following example parses a hash table to `[PSNode]` instance and selects the second (`0` indexed)
    item in the `My` map node

        @{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node My[1]

        PathName Name Depth Value
        -------- ---- ----- -----
        My[1]       1     2     2

.EXAMPLE
    # Change the price of the **PowerShell** book:

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

    for more details, see: [PowerShell Object Parser][1] and [Extended dot notation][2]

.PARAMETER InputObject
    The concerned object graph or node.

.PARAMETER Path
    Specifies the path to a specific node in the object graph.
    The path might be either:

    * As [String] a "dot-property" selection as defined by the `Path` property a specific node.
    * A array of strings (dictionary keys or Property names) and/or integers (list indices).
    * A object (`PSNode[]`) list where each `Name` property defines the path

.PARAMETER Literal
    If Literal switch is set, all (map) nodes in the given path are considered literal.

.PARAMETER MaxDepth
    Specifies the maximum depth that an object graph might be recursively iterated before it throws an error.
    The failsafe will prevent infinitive loops for circular references as e.g. in:

        $Test = @{Guid = New-Guid}
        $Test.Parent = $Test

    The default `MaxDepth` is defined by `[PSNode]::DefaultMaxDepth = 10`.

    > [!Note]
    > The `MaxDepth` is bound to the root node of the object graph. Meaning that a descendant node
    > at depth of 3 can only recursively iterated (`10 - 3 =`) `7` times.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/XdnPath.md "Extended dot notation"
#>

function Get-Node {
    [OutputType([PSNode])]
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Get-Node.md')] param(
        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        $InputObject,

        [Parameter(ParameterSetName='Path', Position=0, ValueFromPipelineByPropertyName = $true)]
        $Path,

        [Switch]
        $Literal,

        [Int]
        $MaxDepth
    )

    begin {
        $XdnPaths = @($Path).ForEach{
            if ($_ -is [XdnPath]) { $_ }
            elseif ($literal) { [XdnPath]::new($_, $True) }
            else { [XdnPath]$_ }
        }
    }

    process {
        $Root = [PSNode]::ParseInput($InputObject, $MaxDepth)
        $Node =
            if ($XdnPaths) { $XdnPaths.ForEach{ $Root.GetNode($_) } }
            else { $Root }
        if ($ValueOnly) { $Node.Value } else { $Node }
    }
}

