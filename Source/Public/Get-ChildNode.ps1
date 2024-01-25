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
        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        $ObjectGraph,

        [switch]
        $Recurse,

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
        $LeafNode
    )
    begin {
        function iterate(
            [PSNode]$Node,
            [Switch]$Recurse   = $Recurse,
            [string[]]$Include = $Include,
            [string[]]$Exclude = $Exclude,
            [switch]$Literal   = $Literal,
            [switch]$ListChild = $ListChild,
            [switch]$LeafNode  = $LeafNode
        ) {

            foreach ($ChildNode in $Node.ChildNodes) {
                if (
                    (
                        -not $LeafNode -or $ChildNode -is [PSLeafNode]
                    ) -and
                    (
                        (
                            $ChildNode.NodeOrigin -eq 'List' -and -not ($Include -or $Exclude)
                        ) -or
                        (
                            $ChildNode.NodeOrigin -eq 'Map' -and -Not $ListChild -and
                            (
                                -not $Include -or (
                                    ($Literal -and $ChildNode.Name -in $Include) -or
                                    (-not $Literal -and $Include.foreach{ $ChildNode.Name -like $_ })
                                )
                            ) -and -not (
                                $Exclude -and (
                                    ($Literal -and $ChildNode.Name -in $Exclude) -or
                                    (-not $Literal -and $Exclude.foreach{ $ChildNode.Name -like $_ })
                                )
                            )
                        )
                    )
                ) { $ChildNode }
                if ($Recurse) { Iterate $ChildNode }
            }
        }
    }
    process {
        if ($ObjectGraph -is [PSNode]) { $Node = $ObjectGraph }
        else { $Node = [PSNode]::ParseInput($ObjectGraph) }
        Iterate $Node
    }
}