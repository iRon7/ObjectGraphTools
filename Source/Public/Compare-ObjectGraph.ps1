<#
.SYNOPSIS
    Compare Object Graph

.DESCRIPTION
    Deep compares two Object Graph and lists the differences between them.

.PARAMETER InputObject
    The input object that will be compared with the reference object (see: [-Reference] parameter).

    > [!NOTE]
    > Multiple input object might be provided via the pipeline.
    > The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
    > To avoid a list of (root) objects to unroll, use the **comma operator**:

        ,$InputObject | Compare-ObjectGraph $Reference.

.PARAMETER Reference
    The reference that is used to compared with the input object (see: [-InputObject] parameter).

.PARAMETER PrimaryKey
    If supplied, dictionaries (including PSCustomObject or Component Objects) in a list are matched
    based on the values of the `-PrimaryKey` supplied.

.PARAMETER IsEqual
    If set, the cmdlet will return a boolean (`$true` or `$false`).
    As soon a Discrepancy is found, the cmdlet will immediately stop comparing further properties.

.PARAMETER MatchCase
    Unless the `-MatchCase` switch is provided, string values are considered case insensitive.

    > [!NOTE]
    > Dictionary keys are compared based on the `$Reference`.
    > if the `$Reference` is an object (PSCustomObject or component object), the key or name comparison
    > is case insensitive otherwise the comparer supplied with the dictionary is used.

.PARAMETER MatchType
    Unless the `-MatchType` switch is provided, a loosely (inclusive) comparison is done where the
    `$Reference` object is leading. Meaning `$Reference -eq $InputObject`:

        '1.0' -eq 1.0 # $false
        1.0 -eq '1.0' # $true (also $false if the `-MatchType` is provided)

.PARAMETER IgnoreLisOrder
    By default, items in a list are matched independent of the order (meaning by index position).
    If the `-IgnoreListOrder` switch is supplied, any list in the `$InputObject` is searched for a match
    with the reference.

    > [!NOTE]
    > Regardless the list order, any dictionary lists are matched by the primary key (if supplied) first.

.PARAMETER MatchMapOrder
    By default, items in dictionary (including properties of an PSCustomObject or Component Object) are
    matched by their key name (independent of the order).
    If the `-MatchMapOrder` switch is supplied, each entry is also validated by the position.

    > [!NOTE]
    > A `[HashTable]` type is unordered by design and therefore, regardless the `-MatchMapOrder` switch,
    the order of the `[HashTable]` (defined by the `$Reference`) are always ignored.

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded property (default: 10).
#>
function Compare-ObjectGraph {
    [CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Compare-ObjectGraph.md')] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        $InputObject,

        [Parameter(Mandatory = $true, Position=0)]
        $Reference,

        [String[]]$PrimaryKey,

        [Switch]$IsEqual,

        [Switch]$MatchCase,

        [Switch]$MatchType,

        [Switch]$IgnoreListOrder,

        [Switch]$MatchMapOrder,

        [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
    )
    begin {
        $ObjectComparison = [ObjectComparison]0
        [ObjectComparison].GetEnumNames().foreach{
            if ($PSBoundParameters.ContainsKey($_) -and $PSBoundParameters[$_]) {
                $ObjectComparison = $ObjectComparison -bor [ObjectComparison]$_
            }
        }

        $ObjectComparer = [ObjectComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
        $Node1 = [PSNode]::ParseInput($Reference, $MaxDepth)
    }
    process {
        $Node2 = [PSNode]::ParseInput($InputObject, $MaxDepth)
        if ($IsEqual) { $ObjectComparer.IsEqual($Node1, $Node2) }
        else { $ObjectComparer.Report($Node1, $Node2) }
    }
}
