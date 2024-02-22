Using NameSpace System.Management.Automation.Language

<#
.SYNOPSIS
    Gets the child nodes of an object-graph

.DESCRIPTION
    Gets the items and child items in one or more specified locations of an object-graph

.EXAMPLE
        # Select all leaf nodes in a object graph

    Given the following object graph:

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

    The following example will receive all leaf nodes:

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

.EXAMPLE
        # update a property

    The following example selects all child nodes named `Comment` at a depth of `3`.
    Than filters the one that has an `Index` sibling with the value `2` and eventually
    sets the value (of the `Comment` node) to: 'Two to the Loo'.

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

    See the [PowerShell Object Parser][1] For details on the `[PSNode]` properties and methods.

.PARAMETER InputObject
    The concerned object graph or node.

.PARAMETER Path
    Specifies the path to a specific node in the object graph.
    The path might be either:

    * As [String] a "dot-property" selection as defined by the `PathName` property a specific node.
    * A array of strings (dictionary keys or Property names) and/or Integers (list indices).
    * A object (`PSNode[]`) list where each `Name` property defines the path

.PARAMETER Recurse
    Recursively iterates through all embedded property objects (nodes) to get the selected nodes.
    The maximum depth of of a specific node that might be retrieved is define by the `MaxDepth`
    of the (root) node. To change the maximum depth the (root) node needs to be loaded first, e.g.:

        Get-Node <InputObject> -Depth 20 | Get-ChildNode ...

    (See also: [`Get-Node`][2])

    > [!NOTE]
    > If the [AtDepth] parameter is supplied, the object graph is recursively searched anyways
    > for the selected nodes up till the deepest given `AtDepth` value.

.PARAMETER AtDepth
    When defined, only returns nodes at the given depth(s).

    > [!NOTE]
    > The nodes below the `MaxDepth` can not be retrieved.

.PARAMETER ListChild
    Returns only nodes derived from a **list node**.

.PARAMETER Include
    Returns only nodes derived from a **map node** including only the ones specified by one or more
    string patterns defined by this parameter. Wildcard characters are permitted.

    > [!NOTE]
    > The [-Include] and [-Exclude] parameters can be used together. However, the exclusions are applied
    > after the inclusions, which can affect the final output.

.PARAMETER Exclude
    Returns only nodes derived from a **map node** excluding the ones specified by one or more
    string patterns defined by this parameter. Wildcard characters are permitted.

    > [!NOTE]
    > The [-Include] and [-Exclude] parameters can be used together. However, the exclusions are applied
    > after the inclusions, which can affect the final output.

.PARAMETER Literal
    The values of the [-Include] - and [-Exclude] parameters are used exactly as it is typed.
    No characters are interpreted as wildcards.

.PARAMETER Leaf
    Only return leaf nodes. Leaf nodes are nodes at the end of a branch and do not have any child nodes.
    You can use the [-Recurse] parameter with the [-Leaf] parameter.

.PARAMETER IncludeSelf
    Includes the current node with the returned child nodes.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Get-Node.md "Get-Node"
#>

function Get-ChildNode {
    [OutputType([PSNode[]])]
    [CmdletBinding(DefaultParameterSetName='ListChild')] param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeLine = $true)]
        $InputObject,

        [ValidateNotNull()]
        $Path,

        [switch]
        $Recurse,

        [ValidateRange(0, [int]::MaxValue)]
        [int[]]
        $AtDepth,

        [Parameter(ParameterSetName='ListChild')]
        [switch]
        $ListChild,

        [Parameter(ParameterSetName='MapChild')]
        [string[]]
        $Include,

        [Parameter(ParameterSetName='MapChild')]
        [string[]]
        $Exclude,

        [Parameter(ParameterSetName='MapChild')]
        [switch]
        $Literal,

        [switch]
        $Leaf,

        [Alias('Self')][switch]
        $IncludeSelf
    )

    process {
        $Self = [PSNode]::ParseInput($InputObject, $MaxDepth)

        if ($PSBoundParameters.ContainsKey('Path')) { $Self = $Self.GetNode($Path) }
        $SearchDepth = if ($PSBoundParameters.ContainsKey('AtDepth')) {
            [System.Linq.Enumerable]::Max($AtDepth) - $Node.Depth - 1
        } elseif ($Recurse) { -1 } else { 0 }
        $Nodes = $Self.GetNodes($SearchDepth)
        if ($IncludeSelf) {
            $ChildNodes = $Nodes
            $Nodes = [Collections.Generic.List[PSNode]]$Self
            $Nodes.AddRange($ChildNodes)
        }
        foreach ($Node in $Nodes) {
            if (
                (
                    -not $PSBoundParameters.ContainsKey('AtDepth') -or $Node.Depth -in $AtDepth
                ) -and
                (
                    -not $Leaf -or $Node -is [PSLeafNode]
                ) -and
                (
                    $Node.NodeOrigin -eq 'Root' -or
                    (
                        $Node.NodeOrigin -eq 'List' -and -not ($Include -or $Exclude)
                    ) -or
                    (
                        $Node.NodeOrigin -eq 'Map' -and -Not $ListChild -and
                        (
                            -not $Include -or (
                                ($Literal -and $Node.Name -in $Include) -or
                                (-not $Literal -and $Include.where({ $Node.Name -like $_ }, 'first'))
                            )
                        ) -and -not (
                            $Exclude -and (
                                ($Literal -and $Node.Name -in $Exclude) -or
                                (-not $Literal -and $Exclude.where({ $Node.Name -like $_ }, 'first'))
                            )
                        )
                    )
                )
            ) { $Node }
        }
    }
}