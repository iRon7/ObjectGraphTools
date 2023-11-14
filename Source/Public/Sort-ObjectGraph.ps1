enum Construction { Undefined; Scalar; List; Dictionary; Component; Custom }
function Sort-ObjectGraph {
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseApprovedVerbs", "")]
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory=$true, ValueFromPipeLine = $True)]
        $InputObject,

        [String[]]$PrimaryKey,
        
        [Switch]$MatchCase,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        function SortObject($Object, [Int]$Depth = $MaxDepth, [Switch]$SortKey) {
            if ($Depth -le 0) {
                Write-Warning "The maximum depth of $MaxDepth has been reached."
                $PSObject = [PSInterface]::new("$Object")
            }
            else { $PSObject = [PSInterface]::new($Object) }
            if ($PSObject.Structure -eq 'List') {
                $Items = foreach ($Item in $Object) { SortObject $Item ($Depth - 1) -SortKey }
                $Items = $Items | Sort-Object { $_.Keys[0] }
                $String = [Collections.Generic.List[String]]::new()
                $Object = [Collections.Generic.List[Object]]::new()
                foreach ($Item in $Items) {
                    $Key = $Item.Keys[0]
                    $String.Add($Key)
                    $Object.Add($Item[$Key][0])
                }
                $Name = $String -Join [Char]255
                $Output = @{ $Name = @($Object) }                                           # This will convert the list to an (fixed) array
            }
            elseif ($PSObject.Structure -eq 'Dictionary') {
                $Properties = [Ordered]@{}
                $String = [Collections.Generic.List[String]]::new()
                $Order = $PSObject.get_Keys() | Sort-Object { if ($_ -in $PrimaryKey) { [Char]9 + "$_" } else { $_ } }
                foreach ($Index in $Order) {
                    $Item = SortObject $PSObject.Get($Index) ($Depth - 1) -SortKey
                    $Key = $Item.Keys[0]
                    $SortKey = if ($MatchCase) { "$Index".ToUpper() } else { "$Index" }
                    $SortKey = $SortKey + [Char]255 + $Key
                    $String.Add($SortKey)
                    $Properties[$Index] = $Item[$Key][0]
                }
                $Name = $String -Join [Char]255
                $Output = @{ $Name = [PSCustomObject]$Properties }                          # This will convert a dicitionary to a PSCustomObject
            }
            else {
                $Key = if ($MatchCase) { "$Object".ToUpper() } else { "$Object" }
                $Output = @{ $Key = $Object }
            }
            if ($SortKey) { $Output } else { $Output.get_Values() }
        }
    }
    process {
        SortObject $InputObject $MaxDepth
    }
}