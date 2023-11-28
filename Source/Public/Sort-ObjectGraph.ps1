<#
.SYNOPSIS
    Sort object graph

.DESCRIPTION
    Sort object graph
    
#>

function Sort-ObjectGraph {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory=$true, ValueFromPipeLine = $True)]
        $InputObject,

        [Alias('By')][String[]]$PrimaryKey,
        
        [Switch]$MatchCase,

        [Switch]$Descending,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        [PSNode]::MaxDepth = $MaxDepth
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

        function SortObject([PSNode]$Node, [Switch]$SortIndex) {
            if ($Node.Structure -eq 'Scalar') {
                $SortKey = if ($Null -eq $($Node.Value)) { [Char]27 + '$Null' } elseif ($MatchCase) { "$($Node.Value)".ToUpper() } else { "$($Node.Value)" }
                $Output = @{ $SortKey = $($Node.Value) }
            }
            elseif ($Node.Structure -eq 'List') {                                           # This will convert the list to an (fixed) array
                $Items = $Node.GetItemNodes().foreach{ SortObject $_ -SortIndex }
                $Items = $Items | Sort-Object -CaseSensitive:$MatchCase -Descending:$Descending { $_.Keys[0] }
                $String = [Collections.Generic.List[String]]::new()
                $List   = [Collections.Generic.List[Object]]::new()
                foreach ($Item in $Items) {
                    $SortKey = $Item.GetEnumerator().Name
                    $String.Add($SortKey)
                    $List.Add($Item[$SortKey][0])
                }
                $Name = $String -Join [Char]255
                $Output = @{ $Name = @($List) }
            }
            elseif ($Node.Structure -eq 'Dictionary') {                     # This will convert a dicitionary to a PSCustomObject
                $HashTable = [HashTable]::New(0, [StringComparer]::Ordinal)
                $Node.GetItemNodes().foreach{
                    $SortObject = SortObject $_ -SortIndex
                    $SortKey = $SortObject.GetEnumerator().Name
                    if ($Primary.Contains($_.Key)) { $Key = $Primary[$_.Key] } else { $Key = $_.Key}
                    $HashTable["$Key$([Char]255)$SortKey"] = @{ $_.Key = $SortObject[$SortKey] }
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
        SortObject $InputObject $MaxDepth
    }
}
