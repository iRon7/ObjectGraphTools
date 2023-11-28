<#
.SYNOPSIS
    Compare Object Graph

.DESCRIPTION
    Deep compare an Object Graph

#>
function Compare-ObjectGraph {
    [CmdletBinding()] param(

        [Parameter(Mandatory=$true, ValueFromPipeLine = $true)]
        $InputObject,

        [Parameter(Mandatory=$true, Position=0)]
        $Reference,

        [Alias('Depth')][int]$MaxDepth = 10,

        [Switch]$IsEqual,

        [Switch]$MatchCase,

        [Switch]$MatchType,

        [Switch]$MatchOrder
    )
    begin {
        [PSNode]::MaxDepth = $MaxDepth
        function GetHashCode([PSNode]$Node) {
            if ($Node.Structure -eq 'Scalar') {
                $Value = $Node.Value
                if ($Null -eq $Value) { $Value =[Int]::MinValue } # $Null collides with -2147483648 (as $false with 0 and $true with 1)
                else {
                    $Value = if ($MatchCase -and $Value -isnot [ValueType]) { "$Value".ToUpper() } else { $Value }
                    if ($MatchType) { $Value = "[$($Node.Type)]$Value" }
                }
                $Value.GetHashCode()
            }
            elseif ($Node.Structure -eq 'List') { # The order of the list is ignored
                $Seed = if ($MatchType) { "[$($Node.Type)]@()" } else { '@()' }
                $HashCode = $Seed.GetHashCode()
                $Node.GetItemNodes().foreach{ $HashCode = $HashCode -bxor (GetHashCode $_) }
                $HashCode
            }
            elseif ($Node.Structure -eq 'Dictionary') {
                $Seed = if ($MatchType) { "[$($Node.Type)]@{}" } else { '@{}' }
                $HashCode = $Seed.GetHashCode()
                $Node.GetItemNodes().foreach{
                    $Name = if ($MatchCase -and $_.Value -isnot [String]) { "$($_.Value)".ToUpper() } else { $_.Value }
                    if ($MatchType) { $Name = "[$($Node.Type)]$Name" }
                    $ValueCode = GetHashCode $_
                    $HashCode = $HashCode -bxor "$Name=$ValueCode".GetHashCode()
                }
                $HashCode
            }
        }

        function CompareObject([PSNode]$ReferenceNode, [PSNode]$ObjectNode, [Switch]$IsEqual = $IsEqual) {
            if ($MatchType) {
                if ($ObjectNode.Type -ne $ReferenceNode.Type) {
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Property    = $ObjectNode.GetPathName()
                        Inequality  = 'Type'
                        Reference   = $ReferenceNode.Type
                        InputObject = $ObjectNode.Type
                    }
                }
            }
            if ($ObjectNode.Structure -ne $ReferenceNode.Structure) {
                if ($IsEqual) { return $false }
                [PSCustomObject]@{
                    Property    = $ObjectNode.GetPathName()
                    Inequality  = 'Structure'
                    Reference   = $ReferenceNode.Structure
                    InputObject = $ObjectNode.Structure
                }
            }
            elseif ($ObjectNode.Structure -eq 'Scalar') {
                $NotEqual = if ($MatchCase) { $ReferenceNode.Value -cne $ObjectNode.Value } else { $ReferenceNode.Value -cne $ObjectNode.Value }
                if ($NotEqual) { # $ReferenceNode dictates the type
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Property    = $ObjectNode.GetPathName()
                        Inequality  = 'Value'
                        Reference   = $ReferenceNode.Value
                        InputObject = $ObjectNode.Value
                    }
                }
            }
            else {
                if ($ObjectNode.get_Count() -ne $ReferenceNode.get_Count()) {
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Property    = $ObjectNode.GetPathName()
                        Inequality  = 'Size'
                        Reference   = $ReferenceNode.get_Count()
                        InputObject = $ObjectNode.get_Count()
                    }
                }
                if ($ObjectNode.Structure -eq 'List') {
                    if ($MatchOrder) {
                        $ObjectItems    = $ObjectNode.GetItemNodes()
                        $ReferenceItems = $ReferenceNode.GetItemNodes()
                        $Min = [Math]::Min($ObjectNode.get_Count(), $ReferenceNode.get_Count())
                        $Max = [Math]::Min($ObjectNode.get_Count(), $ReferenceNode.get_Count())
                        for ($Index = 0; $Index -le $Max; $Index++) {
                            if ($Index -lt $Min) {
                                $Compare = CompareObject -Reference $ReferenceItems[$Index] -Object $ObjectItems[$Index] -IsEqual:$IsEqual
                                if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }  
                            }
                            elseif ($Index -ge $ObjectNode.get_Count()) {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Property    = $ReferenceNode.GetPathName() # ($ObjectNode doesn't exist)
                                    Inequality  = 'Exists'
                                    Reference   = $true
                                    InputObject = $false
                                }
                            }
                            else {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Property    = $ObjectNode.GetPathName()
                                    Inequality  = 'Exists'
                                    Reference   = $false
                                    InputObject = $true
                                }
                            }
                        }
                    }
                    else {
                        $ObjectHashes = [System.Collections.Generic.Dictionary[Int, Object]]::new()
                        $ObjectNode.GetItemNodes().foreach{ $ObjectHashes[(GetHashCode $_)] = $_ }

                        $ReferenceHashes = [System.Collections.Generic.Dictionary[Int, Object]]::new()
                        $ReferenceNode.GetItemNodes().foreach{ $ReferenceHashes[(GetHashCode $_)] = $_ }

                        $ObjectExcept = [Linq.Enumerable]::Except([int[]]$ObjectHashes.Keys, [int[]]$ReferenceHashes.Keys)
                        if ($ObjectExcept.Count) {
                            if ($IsEqual) { return $false }
                            @($ObjectExcept).foreach{
                                [PSCustomObject]@{
                                    Property    = $ObjectHashes[$_].GetPathName()
                                    Inequality  = 'Exists'
                                    Reference   = $false
                                    InputObject = $true
                                }
                            }
                        }
                        $ReferenceExcept = [Linq.Enumerable]::Except([int[]]$ReferenceHashes.Keys, [int[]]$ObjectHashes.Keys)
                        if ($ReferenceExcept.Count) {
                            if ($IsEqual) { return $false }
                            @($ReferenceExcept).foreach{
                                [PSCustomObject]@{
                                    Property    = $ReferenceHashes[$_].GetPathName()
                                    Inequality  = 'Exists'
                                    Reference   = $true
                                    InputObject = $false
                                }
                            }
                        }
                    }
                }
                elseif ($ObjectNode.Structure -eq 'Dictionary') {
                    $Found = [HashTable]::new() # (Case sensitive)
                    $Order = if ($ObjectReference.Type -ne 'HashTable') { [HashTable]::new() }
                    $Index = 0
                    if ($Order) { $ReferenceNode.Get_Keys().foreach{ $Order[$_] = $Index++ } }
                    $Index = 0
                    foreach ($ObjectItem in $ObjectNode.GetItemNodes()) {
                        if ($ReferenceNode.Contains($ObjectItem.Key)) {
                            $ReferenceItem = $ReferenceNode.GetItemNode($ObjectItem.Key)
                            $Found[$ReferenceItem.Key] = $true
                            if ($Order -and $Order[$ReferenceItem.Key] -ne $Index) {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Property    = $ObjectNode.GetPathName()
                                    Inequality  = 'Order'
                                    Reference   = $false
                                    InputObject = $true
                                }                                
                            }
                            $Compare = CompareObject -Reference $ReferenceItem -Object $ObjectItem -IsEqual:$IsEqual
                            if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }  
                        }
                        else {
                            if ($IsEqual) { return $false }
                            [PSCustomObject]@{
                                Property    = $ObjectItem.GetPathName()
                                Inequality  = 'Exists'
                                Reference   = $false
                                InputObject = $true
                            }                            
                        }
                        $Index++
                    }
                    $ReferenceNode.get_Keys().foreach{
                        if (-not $Found.Contains($_)) {
                            if ($IsEqual) { return $false }
                            [PSCustomObject]@{
                                Property    = $ReferenceNode.GetItemNode($_).GetPathName()
                                Inequality  = 'Exists'
                                Reference   = $true
                                InputObject = $false
                            }                            
                        }
                    }
                }
            }
            if ($IsEqual) { return $true }
        }
    }
    process {
        CompareObject $Reference $InputObject
    }
}
