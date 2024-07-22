<#
.SYNOPSIS
    Sort an object graph

.DESCRIPTION
    Recursively sorts a object graph.

.PARAMETER InputObject
    The input object that will be recursively sorted.

    > [!NOTE]
    > Multiple input object might be provided via the pipeline.
    > The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
    > To avoid a list of (root) objects to unroll, use the **comma operator**:

        ,$InputObject | Sort-Object.

.PARAMETER PrimaryKey
    Any primary key defined by the [-PrimaryKey] parameter will be put on top of [-InputObject]
    independent of the (descending) sort order.

    It is allowed to supply multiple primary keys.

.PARAMETER MatchCase
    (Alias `-CaseSensitive`) Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

.PARAMETER Descending
    Indicates that Sort-Object sorts the objects in descending order. The default is ascending order.

    > [!NOTE]
    > Primary keys (see: [-PrimaryKey]) will always put on top.

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded property (default: 10).
#>

function ConvertTo-SortedObjectGraph {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Sort-ObjectGraph.md')][OutputType([Object[]])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Alias('By')][String[]]$PrimaryKey,

        [Alias('CaseSensitive')]
        [Switch]$MatchCase,

        [Switch]$Descending,

        [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
    )
    begin {
        $ObjectComparison = [ObjectComparison]0
        if ($MatchCase)  { $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'MatchCase'}
        if ($Descending) { $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'Descending'}
        # As the child nodes are sorted first, we just do a side-by-side node compare:
        $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'MatchMapOrder'

        $PSListNodeComparer = [PSListNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
        $PSMapNodeComparer = [PSMapNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }

        function SortRecurse([PSCollectionNode]$Node, [PSListNodeComparer]$PSListNodeComparer, [PSMapNodeComparer]$PSMapNodeComparer) {
            $NodeList = $Node.GetNodeList()
            for ($i = 0; $i -lt $NodeList.Count; $i++) {
                if ($NodeList[$i] -is [PSCollectionNode]) {
                    $NodeList[$i] = SortRecurse $NodeList[$i] -PSListNodeComparer $PSListNodeComparer -PSMapNodeComparer $PSMapNodeComparer
                }
            }
            if ($Node -is [PSListNode]) {
                $NodeList.Sort($PSListNodeComparer)
                if ($NodeList.Count) { $Node.Value = @($NodeList.Value) } else { $Node.Value =  @() }
            }
            else { # if ($Node -is [PSMapNode])
                $NodeList.Sort($PSMapNodeComparer)
                $Properties = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
                foreach($ChildNode in $NodeList) { $Properties[[Object]$ChildNode.Name] = $ChildNode.Value } # [Object] forces a key rather than an index (ArgumentOutOfRangeException)
                if ($Node -is [PSObjectNode]) { $Node.Value = [PSCustomObject]$Properties } else { $Node.Value = $Properties }
            }
            $Node
        }
    }

    process {
        $Node = [PSNode]::ParseInput($InputObject, $MaxDepth)
        if ($Node -is [PSCollectionNode]) {
            $Node = SortRecurse $Node -PSListNodeComparer $PSListNodeComparer -PSMapNodeComparer $PSMapNodeComparer
        }
        $Node.Value
    }
}

Set-Alias -Name 'Sort-ObjectGraph' -Value 'ConvertTo-SortedObjectGraph' -Scope Global
