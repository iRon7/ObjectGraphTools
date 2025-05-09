using module .\..\..\..\ObjectGraphTools

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

enum ObjectCompareMode {
    Equals  # https://learn.microsoft.com/dotnet/api/system.object.equals
    Compare # https://learn.microsoft.com/dotnet/api/system.string.compareto
    Report  # Returns a report with discrepancies
}

[Flags()] enum ObjectComparison { MatchCase = 1; MatchType = 2; IgnoreListOrder = 4; MatchMapOrder = 8; Descending = 128 }

class ObjectComparer {

    # Report properties (column names)
    [String]$Name1 = 'Reference'
    [String]$Name2 = 'InputObject'
    [String]$Issue = 'Discrepancy'

    [String[]]$PrimaryKey
    [ObjectComparison]$ObjectComparison

    [Collections.Generic.List[Object]]$Differences

    ObjectComparer () {}
    ObjectComparer ([String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey }
    ObjectComparer ([ObjectComparison]$ObjectComparison) { $this.ObjectComparison = $ObjectComparison }
    ObjectComparer ([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    ObjectComparer ([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }

    [bool] IsEqual ($Object1, $Object2) { return $this.Compare($Object1, $Object2, 'Equals') }
    [int] Compare  ($Object1, $Object2) { return $this.Compare($Object1, $Object2, 'Compare') }
    [Object] Report ($Object1, $Object2) {
        $this.Differences = [Collections.Generic.List[Object]]::new()
        $null = $this.Compare($Object1, $Object2, 'Report')
        return $this.Differences
    }

    [Object] Compare($Object1, $Object2, [ObjectCompareMode]$Mode) {
        if ($Object1 -is [PSNode]) { $Node1 = $Object1 } else { $Node1 = [PSNode]::ParseInput($Object1) }
        if ($Object2 -is [PSNode]) { $Node2 = $Object2 } else { $Node2 = [PSNode]::ParseInput($Object2) }
        return $this.CompareRecurse($Node1, $Node2, $Mode)
    }

    hidden [Object] CompareRecurse([PSNode]$Node1, [PSNode]$Node2, [ObjectCompareMode]$Mode) {
        $Comparison = $this.ObjectComparison
        $MatchCase = $Comparison -band 'MatchCase'
        $EqualType = $true

        if ($Mode -ne 'Compare') { # $Mode -ne 'Compare'
            if ($MatchCase -and $Node1.ValueType -ne $Node2.ValueType) {
                if ($Mode -eq 'Equals') { return $false } else { # if ($Mode -eq 'Report')
                    $this.Differences.Add([PSCustomObject]@{
                        Path        = $Node2.Path
                        $this.Issue = 'Type'
                        $this.Name1 = $Node1.ValueType
                        $this.Name2 = $Node2.ValueType
                    })
                }
            }
            if ($Node1 -is [PSCollectionNode] -and $Node2 -is [PSCollectionNode] -and $Node1.Count -ne $Node2.Count) {
                if ($Mode -eq 'Equals') { return $false } else { # if ($Mode -eq 'Report')
                    $this.Differences.Add([PSCustomObject]@{
                        Path        = $Node2.Path
                        $this.Issue = 'Size'
                        $this.Name1 = $Node1.Count
                        $this.Name2 = $Node2.Count
                    })
                }
            }
        }

        if ($Node1 -is [PSLeafNode] -and $Node2 -is [PSLeafNode]) {
            $Eq = if ($MatchCase) { $Node1.Value -ceq $Node2.Value } else { $Node1.Value -eq $Node2.Value }
            Switch ($Mode) {
                Equals    { return $Eq }
                Compare {
                    if ($Eq) { return 1 - $EqualType } # different types results in 1 (-gt)
                    else {
                        $Greater = if ($MatchCase) { $Node1.Value -cgt $Node2.Value } else { $Node1.Value -gt $Node2.Value }
                        if ($Greater -xor $Comparison -band 'Descending') { return 1 } else { return -1 }
                    }
                }
                default {
                    if (-not $Eq) {
                        $this.Differences.Add([PSCustomObject]@{
                            Path        = $Node2.Path
                            $this.Issue = 'Value'
                            $this.Name1 = $Node1.Value
                            $this.Name2 = $Node2.Value
                        })
                    }
                }
            }
        }
        elseif ($Node1 -is [PSListNode] -and $Node2 -is [PSListNode]) {
            $MatchOrder = -not ($Comparison -band 'IgnoreListOrder')
            # if ($Node1.GetHashCode($MatchCase) -eq $Node2.GetHashCode($MatchCase)) {
            #     if ($Mode -eq 'Equals') { return $true } else { return 0 } # Report mode doesn't care about the output
            # }
            $Items1 = $Node1.ChildNodes
            $Items2 = $Node2.ChildNodes
            if (-not $Items1 -and -not $Items2) {
                if ($Mode -eq 'Equals') { return $true } elseif ($Mode -eq 'Compare') { return 0 } else { return @() }
            }
            if ($Items1.Count) { $Indices1 = [Collections.Generic.List[Int]]$Items1.Name } else { $Indices1 = @() }
            if ($Items2.Count) { $Indices2 = [Collections.Generic.List[Int]]$Items2.Name } else { $Indices2 = @() }
            if ($this.PrimaryKey) {
                $Maps2 = [Collections.Generic.List[Int]]$Items2.where{ $_ -is [PSMapNode] }.Name
                if ($Maps2.Count) {
                    $Maps1 = [Collections.Generic.List[Int]]$Items1.where{ $_ -is [PSMapNode] }.Name
                    if ($Maps1.Count) {
                        foreach ($Key in $this.PrimaryKey) {
                            foreach($Index2 in @($Maps2)) {
                                $Item2 = $Items2[$Index2]
                                foreach ($Index1 in $Maps1) {
                                    $Item1 = $Items1[$Index1]
                                    if ($Item1.GetValue($Key) -eq $Item2.GetValue($Key)) {
                                        if ($this.CompareRecurse($Item1, $Item2, 'Equals')) {
                                            $null = $Maps2.Remove($Index2)
                                            $Null = $Maps1.Remove($Index1)
                                            $null = $Indices2.Remove($Index2)
                                            $Null = $Indices1.Remove($Index1)
                                            break # Only match the first primary key
                                        }
                                    }
                                }
                            }
                        }
                        # in case of any single maps leftover without primary keys
                        if($Maps2.Count -eq 1 -and $Maps1.Count -eq 1) {
                            $Item2 = $Items2[$Maps2[0]]
                            $Item1 = $Items1[$Maps1[0]]
                            $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                            Switch ($Mode) {
                                Equals  { if (-not $Compare) { return $Compare } }
                                Compare { if ($Compare)      { return $Compare } }
                                Default {
                                    $Maps2.Clear()
                                    $Maps1.Clear()
                                    $null = $Indices2.Remove($Maps2[0])
                                    $Null = $Indices1.Remove($Maps1[0])
                                }
                            }
                        }
                    }
                }
            }
            if (-not $MatchOrder) { # remove the equal nodes from the lists
                foreach($Index2 in @($Indices2)) {
                    $Item2 = $Items2[$Index2]
                    foreach ($Index1 in $Indices1) {
                        $Item1 = $Items1[$Index1]
                        if ($this.CompareRecurse($Item1, $Item2, 'Equals')) {
                            $null = $Indices2.Remove($Index2)
                            $Null = $Indices1.Remove($Index1)
                            break # Only match a single node
                        }
                    }
                }
            }
            for ($i = 0; $i -lt [math]::max($Indices2.Count, $Indices1.Count); $i++) {
                $Index1 = if ($i -lt $Indices1.Count) { $Indices1[$i] }
                $Index2 = if ($i -lt $Indices2.Count) { $Indices2[$i] }
                $Item1  = if ($Null -ne $Index1) { $Items1[$Index1] }
                $Item2  = if ($Null -ne $Index2) { $Items2[$Index2] }
                if ($Null -eq $Item1) {
                    Switch ($Mode) {
                        Equals  { return $false }
                        Compare { return -1 } # None existing items can't be ordered
                        default {
                            $this.Differences.Add([PSCustomObject]@{
                                Path        = $Node2.Path + "[$Index2]"
                                $this.Issue = 'Exists'
                                $this.Name1 = $Null
                                $this.Name2 = if ($Item2 -is [PSLeafNode]) { "$($Item2.Value)" } else { "[$($Item2.ValueType)]" }
                            })
                        }
                    }
                }
                elseif ($Null -eq $Item2) {
                    Switch ($Mode) {
                        Equals  { return $false }
                        Compare { return 1 } # None existing items can't be ordered
                        default {
                            $this.Differences.Add([PSCustomObject]@{
                                Path        = $Node1.Path + "[$Index1]"
                                $this.Issue = 'Exists'
                                $this.Name1 = if ($Item1 -is [PSLeafNode]) { "$($Item1.Value)" } else { "[$($Item1.ValueType)]" }
                                $this.Name2 = $Null
                            })
                        }
                    }
                }
                else {
                    $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                    if (($Mode -eq 'Equals' -and -not $Compare) -or ($Mode -eq 'Compare' -and $Compare)) { return $Compare }
                }
            }
            if ($Mode -eq 'Equals') { return $true } elseif ($Mode -eq 'Compare') { return 0 } else { return @() }
        }
        elseif ($Node1 -is [PSMapNode] -and $Node2 -is [PSMapNode]) {
            $Items1 = $Node1.ChildNodes
            $Items2 = $Node2.ChildNodes
            if (-not $Items1 -and -not $Items2) {
                if ($Mode -eq 'Equals') { return $true } elseif ($Mode -eq 'Compare') { return 0 } else { return @() }
            }
            $MatchOrder = [Bool]($Comparison -band 'MatchMapOrder')
            if ($MatchOrder -and $Node1._Value -isnot [HashTable] -and $Node2._Value -isnot [HashTable]) {
                $Index = 0
                foreach ($Item1 in $Items1) {
                    if ($Index -lt $Items2.Count) { $Item2 = $Items2[$Index++] } else { break }
                    $EqualName = if ($MatchCase) { $Item1.Name -ceq $Item2.Name } else { $Item1.Name -eq $Item2.Name }
                    if ($EqualName) {
                        $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                        if (($Mode -eq 'Equals' -and -not $Compare) -or ($Mode -eq 'Compare' -and $Compare)) { return $Compare }
                    }
                    else {
                        Switch ($Mode) {
                            Equals  { return $false }
                            Compare {} # The order depends on the child name and value
                            default {
                                $this.Differences.Add([PSCustomObject]@{
                                    Path        = $Item1.Path
                                    $this.Issue = 'Name'
                                    $this.Name1 = $Item1.Name
                                    $this.Name2 = $Item2.Name
                                })
                            }
                        }
                    }
                }
            }
            else {
                $Found = [HashTable]::new() # (Case sensitive)
                foreach ($Item2 in $Items2) {
                    if ($Node1.Contains($Item2.Name)) {
                        $Item1 = $Node1.GetChildNode($Item2.Name) # Left defines the comparer
                        $Found[$Item1.Name] = $true
                        $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                        if (($Mode -eq 'Equals' -and -not $Compare) -or ($Mode -eq 'Compare' -and $Compare)) { return $Compare }
                    }
                    else {
                        Switch ($Mode) {
                            Equals  { return $false }
                            Compare { return -1 }
                            default {
                                $this.Differences.Add([PSCustomObject]@{
                                    Path        = $Item2.Path
                                    $this.Issue = 'Exists'
                                    $this.Name1 = $false
                                    $this.Name2 = $true
                                })
                            }
                        }
                    }
                }
                foreach ($Name in $Node1.Names) {
                    if (-not $Found.Contains($Name)) {
                        Switch ($Mode) {
                            Equals  { return $false }
                            Compare { return 1 }
                            default {
                                $this.Differences.Add([PSCustomObject]@{
                                    Path        = $Node1.GetChildNode($Name).Path
                                    $this.Issue = 'Exists'
                                    $this.Name1 = $true
                                    $this.Name2 = $false
                                })
                            }
                        }
                    }
                }
            }
            if ($Mode -eq 'Equals') { return $true } elseif ($Mode -eq 'Compare') { return 0 } else { return @() }
        }
        else { # Different structure
            Switch ($Mode) {
                Equals  { return $false }
                Compare { # Structure order: PSLeafNode - PSListNode - PSMapNode (can't be reversed)
                    if ($Node1 -is [PSLeafNode] -or $Node2 -isnot [PSMapNode] ) { return -1 } else { return 1 }
                }
                default {
                    $this.Differences.Add([PSCustomObject]@{
                        Path        = $Node1.Path
                        $this.Issue = 'Structure'
                        $this.Name1 = $Node1.ValueType.Name
                        $this.Name2 = $Node2.ValueType.Name
                    })
                }
            }
        }
        if ($Mode -eq 'Equals')  { throw 'Equals comparison should have returned boolean.' }
        if ($Mode -eq 'Compare') { throw 'Compare comparison should have returned integer.' }
        return @()
    }
}

class PSListNodeComparer : ObjectComparer, IComparer[Object] { # https://github.com/PowerShell/PowerShell/issues/23959
    PSListNodeComparer () {}
    PSListNodeComparer ([String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey }
    PSListNodeComparer ([ObjectComparison]$ObjectComparison) { $this.ObjectComparison = $ObjectComparison }
    PSListNodeComparer ([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    PSListNodeComparer ([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    [int] Compare ([Object]$Node1, [Object]$Node2) { return $this.CompareRecurse($Node1, $Node2, 'Compare') }
}

class PSMapNodeComparer : IComparer[Object] {
    [String[]]$PrimaryKey
    [ObjectComparison]$ObjectComparison

    PSMapNodeComparer () {}
    PSMapNodeComparer ([String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey }
    PSMapNodeComparer ([ObjectComparison]$ObjectComparison) { $this.ObjectComparison = $ObjectComparison }
    PSMapNodeComparer ([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    PSMapNodeComparer ([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    [int] Compare ([Object]$Node1, [Object]$Node2) {
        $Comparison = $this.ObjectComparison
        $MatchCase = $Comparison -band 'MatchCase'
        $Equal = if ($MatchCase) { $Node1.Name -ceq $Node2.Name } else { $Node1.Name -eq $Node2.Name }
        if ($Equal) { return 0 }
        else {
            if ($this.PrimaryKey) {                                           # Primary keys take always priority
                if ($this.PrimaryKey -eq $Node1.Name) { return -1 }
                if ($this.PrimaryKey -eq $Node2.Name) { return 1 }
            }
            $Greater = if ($MatchCase) { $Node1.Name -cgt $Node2.Name } else { $Node1.Name -gt $Node2.Name }
            if ($Greater -xor $Comparison -band 'Descending') { return 1 } else { return -1 }
        }
    }
}
