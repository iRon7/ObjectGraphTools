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

        [String[]]$PrimaryKey,
        
        [Switch]$MatchCase,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        function SortObject($Object, [Int]$Depth = $MaxDepth, [Switch]$SortKey) {
            $PSObject = [PSInterface]::new($Object) 
            if ($PSObject.Structure -eq 'Scalar' -or $Depth -le 0) {
                if ($Depth -le 0) { Write-Warning "The maximum depth of $MaxDepth has been reached." }
                $Key = if ($Null -eq $Object) { [Char]27 + '$Null' } elseif ($MatchCase) { "$Object".ToUpper() } else { "$Object" }
                $Output = @{ $Key = $Object }
            }
            elseif ($PSObject.Structure -eq 'List') {
                $Items = foreach ($Item in $Object) { SortObject $Item ($Depth - 1) -SortKey }
                $Items = $Items | Sort-Object { $_.Keys[0] }
                $String = [Collections.Generic.List[String]]::new()
                $Object = [Collections.Generic.List[Object]]::new()
                foreach ($Item in $Items) {
                    $Key = $Item.get_Keys()[0]
                    $String.Add($Key)
                    $Object.Add($Item[$Key][0])
                }
                $Name = $String -Join [Char]255
                $Output = @{ $Name = @($Object) }                                           # This will convert the list to an (fixed) array
            }
            elseif ($PSObject.Structure -eq 'Dictionary') {
                $Properties = [Ordered]@{}
                $String = [Collections.Generic.List[String]]::new()
                $Order = $PSObject.get_Keys() | Sort-Object { if ($_ -in $PrimaryKey) { [Char]27 + "$_" } else { $_ } }
                foreach ($Index in $Order) {
                    $Item = SortObject $PSObject.Get($Index) ($Depth - 1) -SortKey
                    $Key = $Item.get_Keys()[0]
                    $Sort =
                        if ($MatchCase) { "$Index".ToUpper() + [Char]255 + $Key } 
                        else { "$Index" + [Char]255 + $Key }
                    $String.Add($Sort)
                    $Properties[$Index] = $Item[$Key][0]
                }
                $Name = $String -Join [Char]255
                $Output = @{ $Name = [PSCustomObject]$Properties }                          # This will convert a dicitionary to a PSCustomObject
            }
            else { Write-Error 'Should not happen'}

            Write-Debug "$('  ' * ($MaxDepth - $Depth)) Sortkey: $($Output.get_Keys())"
            if ($SortKey) { $Output } else { $Output.get_Values() }
        }
    }
    process {
        SortObject $InputObject $MaxDepth
    }
}