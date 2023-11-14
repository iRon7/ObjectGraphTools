function Compare-ObjectGraph {
    [CmdletBinding()] param(

        [Parameter(Mandatory=$true, ValueFromPipeLine = $True)]
        $InputObject,

        [Parameter(Mandatory=$true, Position=0)]
        $Reference,

        [Alias('Depth')][int]$MaxDepth = 10,

        [Switch]$IsEqual,

        [Switch]$MatchCase, # If MatchOrder is enabled, the default depends on $Reference 

        [Switch]$MatchType,

        [Switch]$MatchOrder
    )
    begin {
        # function PathToString([Array]$Path) {
        #     $Extent = 
        #         foreach ($Key in $Path) {
        #             if ($Key -is [ValueType])    { "[$Key]"}
        #             elseif (-not $Key)           { ".''" }
        #             elseif ($Key -Match '^\d+$') { ".'$Key'" }
        #             elseif ($Key -NotMatch '\W') { ".$Key" }
        #             else                         { ".'$Key'" }
        #         }
        #     -Join $Extent
        # }
        $Result = [Collections.Generic.List[PSObject]]::new()
        function CompareObject($Reference, $Object, $Path, [int]$Depth, [Switch]$IsEqual) {
            if ($Depth++ -gt $MaxDepth) { Write-Warning "The maximum depth of $MaxDepth has been reached for $Path."; return }
            if ($Reference -is [PSInterface]) { $PSReference = $Reference } else { $PSReference = [PSInterface]::new($Reference) }
            if ($Object    -is [PSInterface]) { $PSObject    = $Object }   else  { $PSObject    = [PSInterface]::new($Object) }
            $Inequality = $Null
            if ($PSReference.Structure -ne $PSObject.Structure) {
                if ($IsEqual) { return $false } else { $Inequality   = 'Incompatible structure' }
            }
            else {
                if ($PSReference.Structure -eq 'List') {
                    if ($PSReference.get_Count() -ne $PSObject.get_Count()) {
                        if ($IsEqual) { return $false } else { $Inequality   = 'Different list size' }
                    }
                    $ObjectHash = @{}
                    $ReferenceHash = @{}
                    for ($i = 0; $i -lt $Object.get_Count(); $i++) {
                        $ObjectItem = $Object[$i]
                        $PSObjectItem = [PSInterface]$ObjectItem

                        if ()
                        
                        $Linked = [System.Collections.Generic.HashSet[int]]::new()



                    $LinkedObject   = $false
                    if ($PSObject.Base.IsFixedSize) { $List = [Collections.Generic.List[PSObject]]::new() }
                    else { $List = New-Object -TypeName $PSObject.Base.GetType() }         # The $InputObject defines the list type
                    foreach($ObjectItem in $PSObject.get_Values()) {
                        $PSObjectItem = [PSInterface]::new($ObjectItem)
                        if ($PSObjectItem.Structure -ne 'Dictionary') { continue }
                        for ($i = 0; $i -lt $PSReference.get_Count(); $i++) {
                            $ReferenceItem = $PSReference.Get($i)
                            $PSReferenceItem = [PSInterface]::new($ReferenceItem)
                            if ($PSReferenceItem.Structure -ne 'Dictionary') { continue }
                            foreach ($Key in $PrimaryKey) {
                                if (-not $PSReferenceItem.Contains($Key) -or -not $PSObjectItem.Contains($Key)) { continue }
                                if ($PSReferenceItem.Get($Key) -eq $PSObjectItem.Get($Key)) {
                                    $Item = MergeObject $PSReferenceItem $PSObjectItem ($Depth - 1)
                                    $List.Add($Item)
                                    $Null = $LinkedReference.Add($i)
                                    $LinkedObject = $True
                                }
                            }
                        }
                        if (-not $LinkedObject) { $List.Add($ObjectItem) }
                    }
                    for ($i = 0; $i -lt $PSReference.get_Count(); $i++) {
                        if (-not $LinkedReference.Contains($i)) { $List.Add($PSReference.Base[$i]) }
                    }
                    if ($PSObject.Base.IsFixedSize) { $List = @($List) }
                    ,$list
                }
                elseif ($PSReference.Structure -eq 'Dictionary') {
                    $PSNew = [PSInterface]::new($PSObject.Type)                             # The $InputObject defines the dictionary type
                    foreach ($Key in $PSObject.get_Keys()) {                                # The $InputObject order takes president
                        if ($PSReference.Contains($Key)) {
                            $Value = MergeObject $PSReference.Get($Key) $PSObject.Get($Key) ($Depth - 1)
                        }
                        else { $Value = $PSReference.Get($Key) }
                        $PSNew.Set($Key, $Value)
                    }
                    foreach ($Key in $PSReference.get_Keys()) {
                        if (-not $PSNew.Contains($Key)) { $PSNew.Set($Key, $PSReference.Get($Key)) }
                    }
                    $PSNew.Base
                }
                else { # if the structures are scalar
                    $IsEqual = if ($MatchCase) { $Reference -ceq $Object } else { $Reference -eq $Object }
                    if (-not $IsEqual) {

                    } elseif ()
                }
            }
            [PSCustomObject]@{
                PropertyPath = PathToString $Path
                Reference    = $PSReference.Structure
                InputObject  = $PSObject.Structure
                Inequality   = $Inequality
            }
        }
    }
    process {
        $Result = CompareObject $Reference $InputObject
        if ($IsEqual) { $Result }
        else {
            foreach($Item in Result) {
                if ()
            }
        }

    }
}