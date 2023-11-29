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
        function CompareObject([PSNode]$ReferenceNode, [PSNode]$ObjectNode, [Switch]$IsEqual = $IsEqual) {
            if ($MatchType) {
                if ($ObjectNode.Type -ne $ReferenceNode.Type) {
                    if ($IsEqual) { return $false }
                    [PSCustomObject]@{
                        Path        = $ObjectNode.GetPathName()
                        Inequality  = 'Type'
                        Reference   = $ReferenceNode.Type
                        InputObject = $ObjectNode.Type
                    }
                }
            }
            if ($ObjectNode.Structure -ne $ReferenceNode.Structure) {
                if ($IsEqual) { return $false }
                [PSCustomObject]@{
                    Path        = $ObjectNode.GetPathName()
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
                        Path        = $ObjectNode.GetPathName()
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
                        Path        = $ObjectNode.GetPathName()
                        Inequality  = 'Size'
                        Reference   = $ReferenceNode.get_Count()
                        InputObject = $ObjectNode.get_Count()
                    }
                }
                if ($ObjectNode.Structure -eq 'List') {
                    $ObjectItems    = $ObjectNode.GetItemNodes()
                    $ReferenceItems = $ReferenceNode.GetItemNodes()
                    if ($MatchOrder) {
                        $Min = [Math]::Min($ObjectNode.get_Count(), $ReferenceNode.get_Count())
                        $Max = [Math]::Max($ObjectNode.get_Count(), $ReferenceNode.get_Count())
                        for ($Index = 0; $Index -lt $Max; $Index++) {
                            if ($Index -lt $Min) {
                                $Compare = CompareObject -Reference $ReferenceItems[$Index] -Object $ObjectItems[$Index] -IsEqual:$IsEqual
                                if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }  
                            }
                            elseif ($Index -ge $ObjectNode.get_Count()) {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Path        = $ReferenceNode.GetPathName() # ($ObjectNode doesn't exist)
                                    Inequality  = 'Exists'
                                    Reference   = $true
                                    InputObject = $false
                                }
                            }
                            else {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Path        = $ObjectNode.GetPathName()
                                    Inequality  = 'Exists'
                                    Reference   = $false
                                    InputObject = $true
                                }
                            }
                        }
                    }
                    else {
                        $ObjectLinks    = [System.Collections.Generic.HashSet[int]]::new()
                        $ReferenceLinks = [System.Collections.Generic.HashSet[int]]::new()
                        foreach($ObjectItem in $ObjectItems) {
                            $Found = $Null
                            foreach($ReferenceItem in $ReferenceItems) {
                                if (-Not $ReferenceLinks.Contains($ReferenceItem.Index)) {
                                    $Found = CompareObject -Reference $ReferenceItem -Object $ObjectItem -IsEqual
                                    if ($Found) {
                                        $Null = $ReferenceLinks.Add($ReferenceItem.Index)
                                        break
                                    }
                                }
                            }
                            if ($Found) {
                                $Null = $ObjectLinks.Add($ObjectItem.Index)
                                continue
                            }                            
                        }
                        for ($Index = 0; $Index -lt $ReferenceNode.get_Count(); $Index ++) {
                            if (-not $ReferenceLinks.Contains($Index)) {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Path        = $ReferenceNode.GetPathName() + "[$Index]"
                                    Inequality  = 'Exists'
                                    Reference   = $true
                                    InputObject = $false
                                }
                            }
                        }
                        for ($Index = 0; $Index -lt $ObjectNode.get_Count(); $Index ++) {
                            if (-not $ObjectLinks.Contains($Index)) {
                                if ($IsEqual) { return $false }
                                [PSCustomObject]@{
                                    Path        = $ObjectNode.GetPathName() + "[$Index]"
                                    Inequality  = 'Exists'
                                    Reference   = $false
                                    InputObject = $true
                                }
                            }                            
                        }
                    }
                }
                elseif ($ObjectNode.Structure -eq 'Dictionary') {
                    $Found = [HashTable]::new() # (Case sensitive)
                    $Order = if ($ReferenceNode.Type.Name -ne 'HashTable') { [HashTable]::new() }
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
                                    Path        = $ObjectItem.GetPathName()
                                    Inequality  = 'Order'
                                    Reference   = $Order[$ReferenceItem.Key]
                                    InputObject = $Index
                                }                                
                            }
                            $Compare = CompareObject -Reference $ReferenceItem -Object $ObjectItem -IsEqual:$IsEqual
                            if ($Compare -eq $false) { return $Compare } elseif ($Compare -ne $true) { $Compare }  
                        }
                        else {
                            if ($IsEqual) { return $false }
                            [PSCustomObject]@{
                                Path        = $ObjectItem.GetPathName()
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
                                Path        = $ReferenceNode.GetItemNode($_).GetPathName()
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
