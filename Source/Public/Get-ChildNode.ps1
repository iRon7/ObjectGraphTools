Using NameSpace System.Management.Automation.Language

<#
.SYNOPSIS
    Gets the child nodes of an object-graph

.DESCRIPTION
    Gets the child nodes of an object-graph

#>

function Get-ChildNode {
    [OutputType([PSNode[]])]
    [CmdletBinding(DefaultParameterSetName='ListChild')] param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeLine = $true)]
        $ObjectGraph,

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
        if ($ObjectGraph -is [PSNode]) { $Self = $ObjectGraph }
        else { $Self = [PSNode]::ParseInput($ObjectGraph) }
        if ($PSBoundParameters.ContainsKey('Path')) { $Self = $Self.GetDescendentNode($Path) }
        $SearchDepth = if ($PSBoundParameters.ContainsKey('AtDepth')) {
            [System.Linq.Enumerable]::Max($AtDepth) - $Node.Depth - 1
        } elseif ($Recurse) { -1 } else { 0 }
        $Nodes = $Self.GetDescendentNodes($SearchDepth)
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
                                (-not $Literal -and $Include.foreach{ $Node.Name -like $_ })
                            )
                        ) -and -not (
                            $Exclude -and (
                                ($Literal -and $Node.Name -in $Exclude) -or
                                (-not $Literal -and $Exclude.foreach{ $Node.Name -like $_ })
                            )
                        )
                    )
                )
            ) { $Node }
        }
    }
}