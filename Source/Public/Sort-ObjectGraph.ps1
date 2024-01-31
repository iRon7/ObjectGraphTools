<#
.SYNOPSIS
    Sort object graph

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
    Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

.PARAMETER Descending
    Indicates that Sort-Object sorts the objects in descending order. The default is ascending order.

    > [!NOTE]
    > Primary keys (see: [-PrimaryKey]) will always put on top.

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded property (default: 10).
#>

function ConvertTo-SortedObjectGraph {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
        $InputObject,

        [Alias('By')][String[]]$PrimaryKey,

        [Switch]$MatchCase,

        [Switch]$Descending,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        $Primary = @{}
        if ($PSBoundParameters.ContainsKey('PrimaryKey')) {
            for($i = 0; $i -lt $PrimaryKey.Count; $i++) {
                if ($Descending) {
                    $Primary[$PrimaryKey[$i]] = [Char]254 + '#' * ($PrimaryKey.Count - $i)
                }
                else {
                    $Primary[$PrimaryKey[$i]] = ' ' + '#' * $i
                }
            }
        }

        function SortObject([PSNode]$Node, [String[]]$PrimaryKey, [Switch]$MatchCase, [Switch]$Descending, [Switch]$SortIndex) {
            if ($Node -is [PSLeafNode]) {
                $SortKey = if ($Null -eq $($Node.Value)) { [Char]27 + '$Null' } elseif ($MatchCase) { "$($Node.Value)".ToUpper() } else { "$($Node.Value)" }
                $Output = @{ $SortKey = $($Node.Value) }
            }
            elseif ($Node -is [PSListNode]) {                                           # This will convert the list to an (fixed) array
                $Items = $Node.ChildNodes.foreach{ SortObject $_ -SortIndex -PrimaryKey $PrimaryKey -MatchCase:$MatchCase -Descending:$Descending }
                $Items = $Items | Sort-Object -CaseSensitive:$MatchCase -Descending:$Descending { $_.Keys[0] }
                $String = [Collections.Generic.List[String]]::new()
                $List   = [Collections.Generic.List[Object]]::new()
                foreach ($Item in $Items) {
                    $SortKey = $Item.GetEnumerator().Name
                    $String.Add($SortKey)
                    $List.Add($Item[$SortKey])
                }
                $Name = $String -Join [Char]255
                $Output = @{ $Name = @($List) }
            }
            elseif ($Node -is [PSMapNode]) {                     # This will convert a dictionary to a PSCustomObject
                $HashTable = [HashTable]::New(0, [StringComparer]::Ordinal)
                $Node.ChildNodes.foreach{
                    $SortObject = SortObject $_ -PrimaryKey $PrimaryKey -MatchCase:$MatchCase -Descending:$Descending -SortIndex
                    $SortKey = $SortObject.GetEnumerator().Name
                    if ($Primary.Contains($_.Name)) { $Key = $Primary[$_.Name] } else { $Key = $_.Name}
                    $HashTable["$Key$([Char]255)$SortKey"] = @{ $_.Name = $SortObject[$SortKey] }
                }
                $SortedKeys = $HashTable.get_Keys() | Sort-Object -CaseSensitive:$MatchCase -Descending:$Descending
                $Properties = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
                @($SortedKeys).foreach{
                    $Item = $HashTable[$_]
                    $Name = $Item.GetEnumerator().Name
                    $Properties[$Name] = $Item[$Name]
                }
                $Name = $SortedKeys -Join [Char]255
                $Output = @{ $Name = [PSCustomObject]$Properties }          # https://github.com/PowerShell/PowerShell/issues/20753
            }
            else { Write-Error 'Should not happen' }
            if ($SortIndex) { $Output } else { $Output.get_Values() }
        }
    }

    process {
        $Node = [PSNode]::ParseInput($InputObject, $MaxDepth)
        SortObject $Node -PrimaryKey $PrimaryKey -MatchCase:$MatchCase -Descending:$Descending
    }
}

Set-Alias -Name 'Sort-ObjectGraph' -Value 'ConvertTo-SortedObjectGraph' -Scope Global
