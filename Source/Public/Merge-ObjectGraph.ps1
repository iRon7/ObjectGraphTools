<#
.SYNOPSIS
    Merges two graph objects into one

.DESCRIPTION
    Merges two graph objects into one
    
#>

function Merge-ObjectGraph {
    [CmdletBinding()][OutputType([Object[]])] param(

        [Parameter(Mandatory=$true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(Mandatory=$true, Position=0)]
        $Template,

        [String[]]$PrimaryKey,

        [Switch]$MatchCase,

        [Alias('Depth')][int]$MaxDepth = 10
    )
    begin {
        function MergeObject($Template, $Object, [Int]$Depth) {
            if ($Depth -lt 0) {
                Write-Warning "The maximum depth of $MaxDepth has been reached."
                return $Object
            }
            if ($Template -is [PSInterface]) { $PSTemplate = $Template } else { $PSTemplate = [PSInterface]::new($Template) }
            if ($Object   -is [PSInterface]) { $PSObject   = $Object }   else { $PSObject   = [PSInterface]::new($Object) }
            if ($PSTemplate.Structure -eq $PSObject.Structure) {
                if ($PSTemplate.Structure -eq 'List') {
                    $LinkedTemplate = [System.Collections.Generic.HashSet[int]]::new()
                    if ($PSObject.Base.IsFixedSize) { $List = [Collections.Generic.List[PSObject]]::new() }
                    else { $List = New-Object -TypeName $PSObject.Base.GetType() }         # The $InputObject defines the list type
                    foreach($ObjectItem in $PSObject.get_Values()) {
                        $PSObjectItem = [PSInterface]::new($ObjectItem)
                        $LinkedObject = $false
                        for ($i = 0; $i -lt $PSTemplate.get_Count(); $i++) {
                            $TemplateItem = $PSTemplate.Get($i)
                            $PSTemplateItem = [PSInterface]::new($TemplateItem)
                            if ($PSObjectItem.Structure -eq $PSTemplateItem.Structure) {
                                switch ($PSObjectItem.Structure) {
                                    'Scalar' {
                                        $Equal = if ($MatchCase) { $ObjectItem -ceq $TemplateItem } else { $ObjectItem -eq $TemplateItem }
                                        if ($Equal) {
                                            $List.Add($ObjectItem)
                                            $LinkedObject = $True
                                            $Null = $LinkedTemplate.Add($i)
                                        }
                                    }
                                    'Dictionary' {
                                        foreach ($Key in $PrimaryKey) {
                                            if (-not $PSTemplateItem.Contains($Key) -or -not $PSObjectItem.Contains($Key)) { continue }
                                            if ($PSTemplateItem.Get($Key) -eq $PSObjectItem.Get($Key)) {
                                                $Item = MergeObject $PSTemplateItem $PSObjectItem ($Depth - 1)
                                                $List.Add($Item)
                                                $LinkedObject = $True
                                                $Null = $LinkedTemplate.Add($i)
                                            }
                                        }                                        
                                    }
                                }
                            }
                        }
                        if (-not $LinkedObject) { $List.Add($ObjectItem) }
                    }
                    for ($i = 0; $i -lt $PSTemplate.get_Count(); $i++) {
                        if (-not $LinkedTemplate.Contains($i)) { $List.Add($PSTemplate.Base[$i]) }
                    }
                    if ($PSObject.Base.IsFixedSize) { $List = @($List) }
                    ,$list
                }
                elseif ($PSTemplate.Structure -eq 'Dictionary') {
                    $PSNew = [PSInterface]::new($PSObject.Type)                             # The $InputObject defines the dictionary type
                    foreach ($Key in $PSObject.get_Keys()) {                                # The $InputObject order takes president
                        if ($PSTemplate.Contains($Key)) {
                            $Value = MergeObject $PSTemplate.Get($Key) $PSObject.Get($Key) ($Depth - 1)
                        }
                        else { $Value = $PSObject.Get($Key) }
                        $PSNew.Set($Key, $Value)
                    }
                    foreach ($Key in $PSTemplate.get_Keys()) {
                        if (-not $PSNew.Contains($Key)) { $PSNew.Set($Key, $PSTemplate.Get($Key)) }
                    }
                    $PSNew.Base
                }
                else { $PSObject.Base }
            }
            else { $PSObject.Base }
        }
    }
    process {
        MergeObject $Template $InputObject $MaxDepth
    }
}