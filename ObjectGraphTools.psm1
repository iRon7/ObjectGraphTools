#Region Using

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Linq.Expressions
using namespace System.Reflection

#EndRegion Using

#Region Enum

enum LogicalOperatorEnum {
    not = 0
    and = 1
    or  = 2
    xor = 3
}
enum PSNodeStructure {
    Leaf = 0
    List = 1
    Map  = 2
}
enum PSNodeOrigin {
    Root = 0
    List = 1
    Map  = 2
}
enum ObjectCompareMode {
    Equals  = 0
    Compare = 1
    Report  = 2
}
[Flags()] enum ObjectComparison {
    MatchCase       = 1
    MatchType       = 2
    IgnoreListOrder = 4
    MatchMapOrder   = 8
    Descending      = 128
}
enum XdnType {
    Root       = 0
    Ancestor   = 1
    Index      = 2
    Child      = 3
    Descendant = 4
    Offspring  = 5
    Equals     = 9
    Error      = 99
}
enum XdnColorName {
    Reset    = 0
    Regular  = 1
    Literal  = 2
    WildCard = 3
    Operator = 4
    Error    = 99
}

#EndRegion Enum

#Region Class

Class Abbreviate {
    hidden static [String]$Ellipses = [Char]0x2026

    hidden [String] $Prefix
    hidden [String] $String
    hidden [String] $AndSoForth = [Abbreviate]::Ellipses
    hidden [String] $Suffix
    hidden [Int] $MaxLength

    Abbreviate([String]$Prefix, [String]$String, [Int]$MaxLength, [String]$AndSoForth, [String]$Suffix) {
        $this.Prefix     = $Prefix
        $this.String     = $String
        $this.MaxLength  = $MaxLength
        $this.AndSoForth = $AndSoForth
        $this.Suffix     = $Suffix
    }
    Abbreviate([String]$Prefix, [String]$String, [Int]$MaxLength, [String]$Suffix) {
        $this.Prefix    = $Prefix
        $this.String    = $String
        $this.MaxLength = $MaxLength
        $this.Suffix    = $Suffix
    }
    Abbreviate([String]$String, [Int]$MaxLength) {
        $this.String    = $String
        $this.MaxLength = $MaxLength
    }

    [String] ToString() {
        if ($this.MaxLength -le 0) { return $this.String }
        if ($this.String.Length -gt 3 * $this.MaxLength) { $this.String = $this.String.SubString(0, (3 * $this.MaxLength)) } # https://stackoverflow.com/q/78787537/1701026
        $this.String = [Regex]::Replace($this.String, '\s+', ' ')
        if ($this.Prefix.Length + $this.String.Length + $this.Suffix.Length -gt $this.MaxLength) {
            $Length = $this.MaxLength - $this.Prefix.Length - $this.AndSoForth.Length - $this.Suffix.Length
            if ($Length -gt 0) { $this.String = $this.String.SubString(0, $Length) + $this.AndSoForth } else { $this.String = $this.AndSoForth }
        }
        return $this.Prefix + $this.String + $this.Suffix
    }
}
class LogicalTerm {}
Class PSNodePath {
    hidden [PSNode[]]$Nodes
    hidden [String]$_String

    hidden PSNodePath($Nodes) { $this.Nodes = [PSNode[]]$Nodes }

    static [String] op_Addition([PSNodePath]$Path, [String]$String) {
        return "$Path" + $String
    }

    [Bool] Equals([Object]$Path) {
        if ($Path -is [PSNodePath]) {
            if ($this.Nodes.Count -ne $Path.Nodes.Count) { return $false }
            $Index = 0
            foreach( $Node in $this.Nodes) {
                if ($Node.NodeOrigin -ne $Path.Nodes[$Index].NodeOrigin -or
                    $Node.Name       -ne $Path.Nodes[$Index].Name
                ) { return $false }
                $Index++
            }
            return $true
        }
        elseif ($Path -is [String]) {
            return $this.ToString() -eq $Path
        }
        return $false
    }

    [String] ToString() {
        if ($Null -eq $this._String) {
            $Count = $this.Nodes.Count
            $this._String = if ($Count -gt 1) { $this.Nodes[-2].Path.ToString() }
            $Node = $this.Nodes[-1]
            $this._String += # Copy the new path into the current node
                if ($Node.NodeOrigin -eq 'List') {
                    "[$($Node._Name)]"
                }
                elseif ($Node.NodeOrigin -eq 'Map') {
                    $KeyExpression = [PSKeyExpression]$Node._Name
                    if ($Count -le 2) { $KeyExpression } else { ".$KeyExpression" }
                }
        }
        return $this._String
    }

}
Class PSNode : IComparable {
    hidden static PSNode() { Use-ClassAccessors }

    static [int]$DefaultMaxDepth = 20

    hidden $_Name
    [Int]$Depth
    hidden $_Value
    hidden [Int]$_MaxDepth = [PSNode]::DefaultMaxDepth
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this
    hidden [Dictionary[String,Object]]$Cache = [Dictionary[String,Object]]::new()
    hidden [DateTime]$MaxDepthWarningTime            # Warn ones per item branch

    static ExportTypes() { # https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#exporting-classes-with-type-accelerators
        # Define the types to export with type accelerators.
        $ExportableTypes =@(
            [PSNode]
            [PSCollectionNode]
            [PSListNode]
            [PSMapNode]
            [PSDictionaryNode]
            [PSObjectNode]
        )
        # Get the internal TypeAccelerators class to use its static methods.
        $TypeAcceleratorsClass = [psobject].Assembly.GetType(
            'System.Management.Automation.TypeAccelerators'
        )
        # Ensure none of the types would clobber an existing type accelerator.
        # If a type accelerator with the same name exists, throw an exception.
        $ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
        foreach ($Type in $ExportableTypes) {
            if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
                $Message = @(
                    "Unable to register type accelerator '$($Type.FullName)'"
                    'Accelerator already exists.'
                ) -join ' - '

                throw [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($Message),
                    'TypeAcceleratorAlreadyExists',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Type.FullName
                )
            }
        }
        # Add type accelerators for every exportable type.
        foreach ($Type in $ExportableTypes) {
            $TypeAcceleratorsClass::Add($Type.FullName, $Type)
        }
        # Remove type accelerators when the module is removed.
        $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
            foreach($Type in $ExportableTypes) {
                $TypeAcceleratorsClass::Remove($Type.FullName)
            }
        }.GetNewClosure()
    }

    static [PSNode] ParseInput($Object, $MaxDepth) {
        $Node =
            if ($Object -is [PSNode]) { $Object }
            else {
                if     ($Null -eq $Object)                                  { [PSLeafNode]::new($Object) }
                elseif ($Object -is [Management.Automation.PSCustomObject]) { [PSObjectNode]::new($Object) }
                elseif ($Object -is [Collections.IDictionary])              { [PSDictionaryNode]::new($Object) }
                elseif ($Object -is [Specialized.StringDictionary])         { [PSDictionaryNode]::new($Object) }
                elseif ($Object -is [Collections.ICollection])              { [PSListNode]::new($Object) }
                elseif ($Object -is [ValueType])                            { [PSLeafNode]::new($Object) }
                elseif ($Object -is [String])                               { [PSLeafNode]::new($Object) }
                elseif ($Object -is [Type])                                 { [PSLeafNode]::new($Object) }
                elseif ($Object -is [ScriptBlock])                          { [PSLeafNode]::new($Object) }
                elseif ($Object.PSObject.Properties)                        { [PSObjectNode]::new($Object) }
                else                                                        { [PSLeafNode]::new($Object) }
            }
        $Node.RootNode = $Node
        if ($MaxDepth -gt 0) { $Node._MaxDepth = $MaxDepth }
        return $Node
    }

    static [PSNode] ParseInput($Object) { return [PSNode]::parseInput($Object, 0) }

    static [int] Compare($Left, $Right) {
        return [ObjectComparer]::new().Compare($Left, $Right)
    }
    static [int] Compare($Left, $Right, [String[]]$PrimaryKey) {
        return [ObjectComparer]::new($PrimaryKey, 0, [CultureInfo]::CurrentCulture).Compare($Left, $Right)
    }
    static [int] Compare($Left, $Right, [String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) {
        return [ObjectComparer]::new($PrimaryKey, $ObjectComparison, [CultureInfo]::CurrentCulture).Compare($Left, $Right)
    }
    static [int] Compare($Left, $Right, [String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison, [CultureInfo]$CultureInfo) {
       return [ObjectComparer]::new($PrimaryKey, $ObjectComparison, $CultureInfo).Compare($Left, $Right)
    }

    hidden [object] get_Value() { return ,$this._Value }

    hidden set_Value($Value) {
        $this.Cache.Remove('ChildNodes')
        $this._Value = $Value
        if ($Null -ne $this.ParentNode) { $this.ParentNode.SetValue($this._Name,  $Value) }
        if ($this.GetType() -ne [PSNode]::ParseInput($Value).GetType()) { # The root node is of type PSNode (always false)
            Write-Warning "The supplied value has a different PSNode type than the existing $($this.Path). Use .ParentNode.SetValue() method and reload its child item(s)."
        }
    }

    hidden [Object] get_Name() { return ,$this._Name }

    hidden [Object] get_MaxDepth() { return $this.RootNode._MaxDepth }

    hidden set_MaxDepth($MaxDepth) {
        if (-not $this.ChildType) {
            $this._MaxDepth = $MaxDepth
        }
        else {
            Throw 'The MaxDepth can only be set at the root node: [PSNode].RootNode.MaxDepth = <Maximum Depth>'
        }
    }

    hidden [PSNodeStructure] get_NodeStructure()  {
        if ($this -is [PSListNode]) { return 'List' } elseif ($this -is [PSMapNode]) { return 'Map' } else { return 'Leaf' }
    }

    hidden [PSNodeOrigin] get_NodeOrigin()  {
        if ($this.ParentNode -is [PSListNode]) { return 'List' } elseif ($this.ParentNode -is [PSMapNode]) { return 'Map' } else { return 'Root' }
    }

    hidden [Type] get_ValueType() {
        if ($Null -eq $this._Value) { return $Null }
        else { return $this._Value.getType() }
    }

    [Int]GetHashCode() { return $this.GetHashCode($false) } # Ignore the case of a string value

    hidden [Object] get_Path() {
        if (-not $this.Cache.ContainsKey('Path')) {
            if ($this.ParentNode) {
                $this.Cache['Path'] = [PSNodePath]($this.ParentNode.get_Path().Nodes + $this)
            }
            else {
                $this.Cache['Path'] = [PSNodePath]$this
            }
        }
        return $this.Cache['Path']
    }

    [String] GetPathName($VariableName) {
        $PathName = $this.get_Path().ToString()
        if (-not $PathName) { return $VariableName }
        elseif ($PathName.StartsWith('.')) { return "$VariableName$PathName" }
        else { return "$VariableName.$PathName" }
    }

    [String] GetPathName() { return $this.get_Path().ToString() }

    hidden [String] get_Expression() { return [PSSerialize]$this }

    Remove() {
        if ($null -eq $this.ParentNode) { Throw "The root node can't be removed." }
        $this.ParentNode.RemoveAt($this.Name)
        $this.Cache.Remove('ChildNodes')
    }

    [Bool] Equals($Object)  {  # https://learn.microsoft.com/dotnet/api/system.globalization.compareoptions
        if ($Object -is [PSNode]) { $Node = $Object }
        else { $Node = [PSNode]::ParseInput($Object) }
        $ObjectComparer = [ObjectComparer]::new()
        return $ObjectComparer.IsEqual($this, $Node)
    }

    [int] CompareTo($Object)  {
        if ($Object -is [PSNode]) { $Node = $Object }
        else { $Node = [PSNode]::ParseInput($Object) }
        $ObjectComparer = [ObjectComparer]::new()
        return $ObjectComparer.Compare($this, $Node)
    }

    hidden CollectNodes($NodeTable, [XdnPath]$Path, [Int]$PathIndex) {
        $Entry = $Path.Entries[$PathIndex]
        $NextIndex = if ($PathIndex -lt $Path.Entries.Count -1) { $PathIndex + 1 }
        $NextEntry = if ($NextIndex) { $Path.Entries[$NextIndex] }
        $Equals    = if ($NextEntry -and $NextEntry.Key -eq 'Equals') {
            $NextEntry.Value
            $NextIndex = if ($NextIndex -lt $Path.Entries.Count -1) { $NextIndex + 1 }
        }
        switch ($Entry.Key) {
            Root {
                $Node = $this.RootNode
                if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                else { $NodeTable[$Node.getPathName()] = $Node }
            }
            Ancestor {
                $Node = $this
                for($i = $Entry.Value; $i -gt 0 -and $Node.ParentNode; $i--) { $Node = $Node.ParentNode }
                if ($i -eq 0) { # else: reached root boundary
                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                    else { $NodeTable[$Node.getPathName()] = $Node }
                }
            }
            Index {
                if ($this -is [PSListNode] -and [Int]::TryParse($Entry.Value, [Ref]$Null)) {
                    $Node = $this.GetChildNode([Int]$Entry.Value)
                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                    else { $NodeTable[$Node.getPathName()] = $Node }
                }
            }
            Default { # Child, Descendant
                if ($this -is [PSListNode]) { # Member access enumeration
                    foreach ($Node in $this.get_ChildNodes()) {
                        $Node.CollectNodes($NodeTable, $Path, $PathIndex)
                    }
                }
                elseif ($this -is [PSMapNode]) {
                    $Found = $False
                    $ChildNodes = $this.get_ChildNodes()
                    foreach ($Node in $ChildNodes) {
                        if ($Entry.Value -eq $Node.Name -and (-not $Equals -or ($Node -is [PSLeafNode] -and $Equals -eq $Node._Value))) {
                            $Found = $True
                            if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                            else { $NodeTable[$Node.getPathName()] = $Node }
                        }
                    }
                    if (-not $Found -and $Entry.Key -eq 'Descendant') {
                        foreach ($Node in $ChildNodes) {
                            $Node.CollectNodes($NodeTable, $Path, $PathIndex)
                        }
                    }
                }
            }
        }
    }

    [Object] GetNode([XdnPath]$Path) {
        $NodeTable = [system.collections.generic.dictionary[String, PSNode]]::new() # Case sensitive (case insensitive map nodes use the same name)
        $this.CollectNodes($NodeTable, $Path, 0)
        if ($NodeTable.Count -eq 0) { return @() }
        if ($NodeTable.Count -eq 1) { return $NodeTable[$NodeTable.Keys] }
        else                        { return [PSNode[]]$NodeTable.Values }
    }
}
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
Class PSDeserialize {
    hidden static [String[]]$Parameters = 'LanguageMode', 'ArrayType', 'HashTableType'
    hidden static PSDeserialize() { Use-ClassAccessors }

    hidden $_Object
    [PSLanguageMode]$LanguageMode = 'Restricted'
    [Type]$ArrayType     = 'Array'     -as [Type]
    [Type]$HashTableType = 'HashTable' -as [Type]
    [String] $Expression

    PSDeserialize([String]$Expression) { $this.Expression = $Expression }
    PSDeserialize(
        $Expression,
        $LanguageMode  = 'Restricted',
        $ArrayType     = $Null,
        $HashTableType = $Null
    ) {
        if ($this.LanguageMode -eq 'NoLanguage') { # No language mode is internally used for displaying
            Throw 'The language mode "NoLanguage" is not supported.'
        }
        $this.Expression    = $Expression
        $this.LanguageMode  = $LanguageMode
        if ($Null -ne $ArrayType)     { $this.ArrayType     = $ArrayType }
        if ($Null -ne $HashTableType) { $this.HashTableType = $HashTableType }
    }

    hidden [Object] get_Object() {
        if ($Null -eq $this._Object) {
            $Ast = [System.Management.Automation.Language.Parser]::ParseInput($this.Expression, [ref]$null, [ref]$Null)
            $this._Object = $this.ParseAst([Ast]$Ast)
        }
        return $this._Object
    }

    hidden [Object] ParseAst([Ast]$Ast) {
        # Write-Host 'Ast type:' "$($Ast.getType())"
        $Type = $Null
        if ($Ast -is [ConvertExpressionAst]) {
            $FullTypeName = $Ast.Type.TypeName.FullName
            if (
                $this.LanguageMode -eq 'Full' -or (
                    $this.LanguageMode -eq 'Constrained' -and
                    [PSLanguageType]::IsConstrained($FullTypeName)
                )
            ) {
                try { $Type = $FullTypeName -as [Type] } catch { write-error $_ }
            }
            $Ast = $Ast.Child
        }
        if ($Ast -is [ScriptBlockAst]) {
            $List = [List[Object]]::new()
            if ($Null -ne $Ast.BeginBlock)   { $Ast.BeginBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($Null -ne $Ast.ProcessBlock) { $Ast.ProcessBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($Null -ne $Ast.EndBlock)     { $Ast.EndBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($List.Count -eq 1) { return $List[0] } else { return @($List) }
        }
        elseif ($Ast -is [PipelineAst]) {
            $Elements = $Ast.PipelineElements
            if (-not $Elements.Count)  { return @() }
            elseif ($Elements -is [CommandAst]) {
                return $Null #85 ConvertFrom-Expression: convert function/cmdlet calls to Objects
            }
            elseif ($Elements.Expression.Count -eq 1) { return $this.ParseAst($Elements.Expression[0]) }
            else { return $Elements.Expression.Foreach{ $this.ParseAst($_) } }
        }
        elseif ($Ast -is [ArrayLiteralAst] -or $Ast -is [ArrayExpressionAst]) {
            if (-not $Type -or 'System.Object[]', 'System.Array' -eq $Type.FullName) { $Type = $this.ArrayType }
            if ($Ast -is [ArrayLiteralAst]) { $Value = $Ast.Elements.foreach{ $this.ParseAst($_) } }
            else { $Value = $Ast.SubExpression.Statements.foreach{ $this.ParseAst($_) } }
            if ('System.Object[]', 'System.Array' -eq $Type.FullName) {
                if ($Value -isnot [Array]) { $Value = @($Value) } # Prevent single item array unrolls
            }
            else { $Value = $Value -as $Type }
            return $Value
        }
        elseif ($Ast -is [HashtableAst]) {
            if (-not $Type -or $Type.FullName -eq 'System.Collections.Hashtable') { $Type = $this.HashTableType }
            $IsPSCustomObject = "$Type" -in
                'PSCustomObject',
                'System.Management.Automation.PSCustomObject',
                'PSObject',
                'System.Management.Automation.PSObject'
            if ($Type.FullName -eq 'System.Collections.Hashtable') { $Map = @{} } # Case insensitive
            elseif ($IsPSCustomObject) { $Map = [Ordered]@{} }
            else { $Map = New-Object -Type $Type }
            $Ast.KeyValuePairs.foreach{
                if ( $Map -is [Collections.IDictionary]) { $Map.Add($_.Item1.Value, $this.ParseAst($_.Item2)) }
                else { $Map."$($_.Item1.Value)" = $this.ParseAst($_.Item2) }
            }
            if ($IsPSCustomObject) { return [PSCustomObject]$Map } else { return $Map }
        }
        elseif ($Ast -is [ConstantExpressionAst]) {
            if ($Type) { $Value = $Ast.Value -as $Type } else { $Value = $Ast.Value }
            return $Value
        }
        elseif ($Ast -is [VariableExpressionAst]) {
            $Value = switch ($Ast.VariablePath.UserPath) {
                Null        { $Null }
                True        { $True }
                False       { $False }
                PSCulture   { (Get-Culture).ToString() }
                PSUICulture { (Get-UICulture).ToString() }
                Default     { $Ast.Extent.Text }
            }
            return $Value
        }
        else { return $Null }
    }
}
Class PSInstance {
    static [Object]Create($Object) {
        if ($Null -eq $Object) { return $Null }
        elseif ($Object -is [String]) {
            $String = if ($Object.StartsWith('[') -and $Object.EndsWith(']')) { $Object.SubString(1, ($Object.Length - 2)) } else { $Object }
            Switch -Regex ($String) {
                '^((System\.)?String)?$'                                         { return '' }
                '^(System\.)?Array$'                                             { return ,@() }
                '^(System\.)?Object\[\]$'                                        { return ,@() }
                '^((System\.)?Collections\.Hashtable\.)?hashtable$'              { return @{} }
                '^((System\.)?Management\.Automation\.)?ScriptBlock$'            { return {} }
                '^((System\.)?Collections\.Specialized\.)?Ordered(Dictionary)?$' { return [Ordered]@{} }
                '^((System\.)?Management\.Automation\.)?PS(Custom)?Object$'      { return [PSCustomObject]@{} }
            }
            $Type = $String -as [Type]
            if (-not $Type) { Throw "Unknown type: [$Object]" }
        }
        elseif ($Object -is [Type]) {
            $Type = $Object.UnderlyingSystemType
            if     ("$Type" -eq 'string')      { Return '' }
            elseif ("$Type" -eq 'array')       { Return ,@() }
            elseif ("$Type" -eq 'scriptblock') { Return {} }
        }
        else {
            if     ($Object -is [Object[]])       { Return ,@() }
            elseif ($Object -is [ScriptBlock])    { Return {} }
            elseif ($Object -is [PSCustomObject]) { Return [PSCustomObject]::new() }
            $Type = $Object.GetType()
        }
        try { return [Activator]::CreateInstance($Type) } catch { throw $_ }
    }
}
Class PSKeyExpression {
    hidden static [Regex]$UnquoteMatch = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
    hidden $Key
    hidden [PSLanguageMode]$LanguageMode = 'Restricted'
    hidden [Bool]$Compress
    hidden [Int]$MaxLength

    PSKeyExpression($Key)                                                 { $this.Key = $Key }
    PSKeyExpression($Key, [PSLanguageMode]$LanguageMode)                  { $this.Key = $Key; $this.LanguageMode = $LanguageMode }
    PSKeyExpression($Key, [PSLanguageMode]$LanguageMode, [Bool]$Compress) { $this.Key = $Key; $this.LanguageMode = $LanguageMode; $this.Compress = $Compress }
    PSKeyExpression($Key, [int]$MaxLength)                                { $this.Key = $Key; $this.MaxLength = $MaxLength }

    [String]ToString() {
        $Name = $this.Key
        if ($Name -is [byte]  -or $Name -is [int16]  -or $Name -is [int32]  -or $Name -is [int64]  -or
            $Name -is [sByte] -or $Name -is [uint16] -or $Name -is [uint32] -or $Name -is [uint64] -or
            $Name -is [float] -or $Name -is [double] -or $Name -is [decimal]) { return [Abbreviate]::new($Name, $this.MaxLength)
        }
        if ($this.MaxLength) { $Name = "$Name" }
        if ($Name -is [String]) {
            if ($Name -cMatch [PSKeyExpression]::UnquoteMatch) { return [Abbreviate]::new($Name, $this.MaxLength) }
            return "'$([Abbreviate]::new($Name.Replace("'", "''"), ($this.MaxLength - 2)))'"
        }
        $Node = [PSNode]::ParseInput($Name, 2) # There is no way to expand keys more than 2 levels
        return  [PSSerialize]::new($Node, $this.LanguageMode, -$this.Compress)
    }
}
Class PSLanguageType {
    hidden static $_TypeCache = [Dictionary[String,Bool]]::new()
    hidden Static PSLanguageType() { # Hardcoded
        [PSLanguageType]::_TypeCache['System.Void'] = $True
        [PSLanguageType]::_TypeCache['System.Management.Automation.PSCustomObject'] = $True # https://github.com/PowerShell/PowerShell/issues/20767
    }
    static [Bool]IsRestricted($TypeName) {
        if ($Null -eq $TypeName) { return $True } # Warning: a $Null is considered a restricted "type"!
        $Type = $TypeName -as [Type]
        if ($Null -eq $Type) { Throw 'Unknown type name: $TypeName' }
        $TypeName = $Type.FullName
        return $TypeName -in 'bool', 'array', 'hashtable'
    }
    static [Bool]IsConstrained($TypeName) { # https://stackoverflow.com/a/64806919/1701026
        if ($Null -eq $TypeName) { return $True } # Warning: a $Null is considered a constrained "type"!
        $Type = $TypeName -as [Type]
        if ($Null -eq $Type) { Throw 'Unknown type name: $TypeName' }
        $TypeName = $Type.FullName
        if (-not [PSLanguageType]::_TypeCache.ContainsKey($TypeName)) {
            [PSLanguageType]::_TypeCache[$TypeName] = try {
                $ConstrainedSession = [PowerShell]::Create()
                $ConstrainedSession.RunSpace.SessionStateProxy.LanguageMode = 'Constrained'
                $ConstrainedSession.AddScript("[$TypeName]0").Invoke().Count -ne 0 -or
                $ConstrainedSession.Streams.Error[0].FullyQualifiedErrorId -ne 'ConversionSupportedOnlyToCoreTypes'
            } catch { $False }
        }
        return [PSLanguageType]::_TypeCache[$TypeName]
    }
}
Class PSSerialize {
    # hidden static [Dictionary[String,Bool]]$IsConstrainedType = [Dictionary[String,Bool]]::new()
    hidden static [Dictionary[String,Bool]]$HasStringConstructor = [Dictionary[String,Bool]]::new()

    hidden static [String]$AnySingleQuote = "'|$([char]0x2018)|$([char]0x2019)"

    # NoLanguage mode only
    hidden static [int]$MaxLeafLength       = 48
    hidden static [int]$MaxKeyLength        = 12
    hidden static [int]$MaxValueLength      = 16
    hidden static [int[]]$NoLanguageIndices = 0, 1, -1
    hidden static [int[]]$NoLanguageItems   = 0, 1, -1

    hidden $_Object

    hidden [PSLanguageMode]$LanguageMode = 'Restricted' # "NoLanguage" will stringify the object for displaying (Use: PSStringify)
    hidden [Int]$ExpandDepth = [Int]::MaxValue
    hidden [Bool]$Explicit
    hidden [Bool]$FullTypeName
    hidden [bool]$HighFidelity
    hidden [String]$Indent = '    '
    hidden [Bool]$ExpandSingleton

    # The dictionary below defines the round trip property. Unless the `-HighFidelity` switch is set,
    # the serialization will stop (even it concerns a `PSCollectionNode`) when the specific property
    # type is reached.
    # * An empty string will return the string representation of the object: `"<Object>"`
    # * Any other string will return the string representation of the object property: `"$(<Object>.<Property>)"`
    # * A ScriptBlock will be invoked and the result will be used for the object value

    hidden static $RoundTripProperty = @{
        'Microsoft.Management.Infrastructure.CimInstance'                     = ''
        'Microsoft.Management.Infrastructure.CimSession'                      = 'ComputerName'
        'Microsoft.PowerShell.Commands.ModuleSpecification'                   = 'Name'
        'System.DateTime'                                                     = { $($Input).ToString('o') }
        'System.DirectoryServices.DirectoryEntry'                             = 'Path'
        'System.DirectoryServices.DirectorySearcher'                          = 'Filter'
        'System.Globalization.CultureInfo'                                    = 'Name'
        'Microsoft.PowerShell.VistaCultureInfo'                               = 'Name'
        'System.Management.Automation.AliasAttribute'                         = 'AliasNames'
        'System.Management.Automation.ArgumentCompleterAttribute'             = 'ScriptBlock'
        'System.Management.Automation.ConfirmImpact'                          = ''
        'System.Management.Automation.DSCResourceRunAsCredential'             = ''
        'System.Management.Automation.ExperimentAction'                       = ''
        'System.Management.Automation.OutputTypeAttribute'                    = 'Type'
        'System.Management.Automation.PSCredential'                           = { ,@($($Input).UserName, @("(""$($($Input).Password | ConvertFrom-SecureString)""", '|', 'ConvertTo-SecureString)')) }
        'System.Management.Automation.PSListModifier'                         = 'Replace'
        'System.Management.Automation.PSReference'                            = 'Value'
        'System.Management.Automation.PSTypeNameAttribute'                    = 'PSTypeName'
        'System.Management.Automation.RemotingCapability'                     = ''
        'System.Management.Automation.ScriptBlock'                            = 'Ast'
        'System.Management.Automation.SemanticVersion'                        = ''
        'System.Management.Automation.ValidatePatternAttribute'               = 'RegexPattern'
        'System.Management.Automation.ValidateScriptAttribute'                = 'ScriptBlock'
        'System.Management.Automation.ValidateSetAttribute'                   = 'ValidValues'
        'System.Management.Automation.WildcardPattern'                        = { $($Input).ToWql().Replace('%', '*').Replace('_', '?').Replace('[*]', '%').Replace('[?]', '_') }
        'Microsoft.Management.Infrastructure.CimType'                         = ''
        'System.Management.ManagementClass'                                   = 'Path'
        'System.Management.ManagementObject'                                  = 'Path'
        'System.Management.ManagementObjectSearcher'                          = { $($Input).Query.QueryString }
        'System.Net.IPAddress'                                                = 'IPAddressToString'
        'System.Net.IPEndPoint'                                               = { $($Input).Address.Address; $($Input).Port }
        'System.Net.Mail.MailAddress'                                         = 'Address'
        'System.Net.NetworkInformation.PhysicalAddress'                       = ''
        'System.Security.Cryptography.X509Certificates.X500DistinguishedName' = 'Name'
        'System.Security.SecureString'                                        = { ,[string[]]("(""$($Input | ConvertFrom-SecureString)""", '|', 'ConvertTo-SecureString)') }
        'System.Text.RegularExpressions.Regex'                                = ''
        'System.RuntimeType'                                                  = ''
        'System.Uri'                                                          = 'OriginalString'
        'System.Version'                                                      = ''
        'System.Void'                                                         = $Null
    }
    hidden $StringBuilder
    hidden [Int]$Offset = 0
    hidden [Int]$LineNumber = 1

    PSSerialize($Object) { $this._Object = $Object }
    PSSerialize($Object, $LanguageMode) {
        $this._Object = $Object
        $this.LanguageMode = $LanguageMode
    }
    PSSerialize($Object, $LanguageMode, $ExpandDepth) {
        $this._Object = $Object
        $this.LanguageMode = $LanguageMode
        $this.ExpandDepth = $ExpandDepth
    }
    PSSerialize(
        $Object,
        $LanguageMode    = 'Restricted',
        $ExpandDepth     = [Int]::MaxValue,
        $Explicit        = $False,
        $FullTypeName    = $False,
        $HighFidelity    = $False,
        $ExpandSingleton = $False,
        $Indent          = '    '
    ) {
        $this._Object         = $Object
        $this.LanguageMode    = $LanguageMode
        $this.ExpandDepth     = $ExpandDepth
        $this.Explicit        = $Explicit
        $this.FullTypeName    = $FullTypeName
        $this.HighFidelity    = $HighFidelity
        $this.ExpandSingleton = $ExpandSingleton
        $this.Indent          = $Indent
    }

    hidden static [String[]]$Parameters = 'LanguageMode', 'Explicit', 'FullTypeName', 'HighFidelity', 'Indent', 'ExpandSingleton'
    PSSerialize($Object, [HashTable]$Parameters) {
        $this._Object = $Object
        foreach ($Name in $Parameters.get_Keys()) { # https://github.com/PowerShell/PowerShell/issues/13307
            if ($Name -notin [PSSerialize]::Parameters) { Throw "Unknown parameter: $Name." }
            $this.GetType().GetProperty($Name).SetValue($this, $Parameters[$Name])
        }
    }

    [String]Serialize($Object) {
        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
        if (-not ('ConstrainedLanguage', 'FullLanguage' -eq $this.LanguageMode)) {
            if ($this.FullTypeName) { Write-Warning 'The FullTypeName switch requires Constrained - or FullLanguage mode.' }
            if ($this.Explicit)     { Write-Warning 'The Explicit switch requires Constrained - or FullLanguage mode.' }
        }
        if ($Object -is [PSNode]) { $Node = $Object } else { $Node = [PSNode]::ParseInput($Object) }
        $this.StringBuilder = [System.Text.StringBuilder]::new()
        $this.Stringify($Node)
        return $this.StringBuilder.ToString()
    }

    hidden Stringify([PSNode]$Node) {
        $Value = $Node.Value
        $IsSubNode = $this.StringBuilder.Length -ne 0
        if ($Null -eq $Value) {
            $this.StringBuilder.Append('$Null')
            return
        }
        $Type = $Node.ValueType
        $TypeName = "$Type"
        $TypeInitializer =
            if ($Null -ne $Type -and (
                    $this.LanguageMode -eq 'Full' -or (
                        $this.LanguageMode -eq 'Constrained' -and
                        [PSLanguageType]::IsConstrained($Type) -and (
                            $this.Explicit -or -not (
                                $Type.IsPrimitive      -or
                                $Value -is [String]    -or
                                $Value -is [Object[]]  -or
                                $Value -is [Hashtable]
                            )
                        )
                    )
                )
                ) {
                    if ($this.FullTypeName) {
                        if ($Type.FullName -eq 'System.Management.Automation.PSCustomObject' ) { '[System.Management.Automation.PSObject]' } # https://github.com/PowerShell/PowerShell/issues/2295
                        else { "[$($Type.FullName)]" }
                    }
                    elseif ($TypeName  -eq 'System.Object[]') { "[Array]" }
                    elseif ($TypeName  -eq 'System.Management.Automation.PSCustomObject') { "[PSCustomObject]" }
                    elseif ($Type.Name -eq 'RuntimeType') { "[Type]" }
                    else { "[$TypeName]" }
                }
        if ($TypeInitializer) { $this.StringBuilder.Append($TypeInitializer) }

        if ($Node -is [PSLeafNode] -or (-not $this.HighFidelity -and [PSSerialize]::RoundTripProperty.Contains($Node.ValueType.FullName))) {
            $MaxLength = if ($IsSubNode) { [PSSerialize]::MaxValueLength } else { [PSSerialize]::MaxLeafLength }

            if ([PSSerialize]::RoundTripProperty.Contains($Node.ValueType.FullName)) {
                $Property = [PSSerialize]::RoundTripProperty[$Node.ValueType.FullName]
                    if ($Null -eq $Property)          { $Expression = $Null }
                elseif ($Property -is [String])       { $Expression = if ($Property) { ,$Value.$Property } else { "$Value" } }
                elseif ($Property -is [ScriptBlock] ) { $Expression = Invoke-Command $Property -InputObject $Value }
                elseif ($Property -is [HashTable])    { $Expression = if ($this.LanguageMode -eq 'Restricted') { $Null } else { @{} } }
                elseif ($Property -is [Array])        { $Expression = @($Property.foreach{ $Value.$_ }) }
                else { Throw "Unknown round trip property type: $($Property.GetType())."}
            }
            elseif ($Value -is [Type])                        { $Expression = @() }
            elseif ($Value -is [Attribute])                   { $Expression = @() }
            elseif ($Type.IsPrimitive)                        { $Expression = $Value }
            elseif (-not $Type.GetConstructors())             { $Expression = "$TypeName" }
            elseif ($Type.GetMethod('ToString', [Type[]]@())) { $Expression = $Value.ToString() }
            elseif ($Value -is [Collections.ICollection])     { $Expression = ,$Value }
            else                                              { $Expression = $Value } # Handle compression

            if     ($Null -eq $Expression)         { $Expression = '$Null' }
            elseif ($Expression -is [Bool])        { $Expression = "`$$Value" }
            elseif ($Expression -is [Char])        { $Expression = "'$Value'" }
            elseif ($Expression -is [ScriptBlock]) { $Expression = [Abbreviate]::new('{', $Expression, $MaxLength, '}') }
            elseif ($Expression -is [HashTable])   { $Expression = '@{}' }
            elseif ($Expression -is [Array]) {
                if ($this.LanguageMode -eq 'NoLanguage') { $Expression = [Abbreviate]::new('[', $Expression[0], $MaxLength, ']') }
                else {
                    $Space = if ($this.ExpandDepth -ge 0) { ' ' }
                    $New = if ($TypeInitializer) { '::new(' } else { '@(' }
                    $Expression = $New + ($Expression.foreach{
                        if ($Null -eq $_)  { '$Null' }
                        elseif ($_.GetType().IsPrimitive) { "$_" }
                        elseif ($_ -is [Array]) { $_ -Join $Space }
                        else { "'$_'" }
                    } -Join ",$Space") + ')'
                }
            }
            elseif ($Type -and $Type.IsPrimitive) {
                if ($this.LanguageMode -eq 'NoLanguage') { $Expression = [CommandColor]([String]$Expression[0]) }
            }
            else {
                if ($Expression -isnot [String]) { $Expression = "$Expression" }
                if ($this.LanguageMode -eq 'NoLanguage') { $Expression = [StringColor]([Abbreviate]::new("'", $Expression, $MaxLength, "'")) }
                else {
                    if ($Expression.Contains("`n")) {
                        $Expression = "@'" + [Environment]::NewLine + "$Expression".Replace("'", "''") + [Environment]::NewLine + "'@"
                    }
                    else { $Expression = "'$($Expression -Replace [PSSerialize]::AnySingleQuote, '$0$0')'" }
                }
            }

            $this.StringBuilder.Append($Expression)
        }
        elseif ($Node -is [PSListNode]) {
            $ChildNodes = $Node.get_ChildNodes()
            $this.StringBuilder.Append('@(')
            if ($this.LanguageMode -eq 'NoLanguage') {
                if ($ChildNodes.Count -eq 0) { }
                elseif ($IsSubNode) { $this.StringBuilder.Append([Abbreviate]::Ellipses) }
                else {
                    $Indices = [PSSerialize]::NoLanguageIndices
                    if (-not $Indices -or $ChildNodes.Count -lt $Indices.Count) { $Indices = 0..($ChildNodes.Count - 1) }
                    $LastIndex = $Null
                    foreach ($Index in $Indices) {
                        if ($Null -ne $LastIndex) { $this.StringBuilder.Append(',') }
                        if ($Index -lt 0) { $Index = $ChildNodes.Count + $Index }
                        if ($Index -gt $LastIndex + 1) { $this.StringBuilder.Append("$([Abbreviate]::Ellipses),") }
                        $this.StringBuilder.Append($this.Stringify($ChildNodes[$Index]))
                        $LastIndex = $Index
                    }
                }
            }
            else {
                $this.Offset++
                $StartLine = $this.LineNumber
                $ExpandSingle = $this.ExpandSingleton -or $ChildNodes.Count -gt 1 -or ($ChildNodes.Count -eq 1 -and $ChildNodes[0] -isnot [PSLeafNode])
                foreach ($ChildNode in $ChildNodes) {
                    if ($ChildNode.Name -gt 0) {
                        $this.StringBuilder.Append(',')
                        $this.NewWord()
                    }
                    elseif ($ExpandSingle) { $this.NewWord('') }
                    $this.Stringify($ChildNode)
                }
                $this.Offset--
                if ($this.LineNumber -gt $StartLine) { $this.NewWord('') }
            }
            $this.StringBuilder.Append(')')
        }
        else { # if ($Node -is [PSMapNode]) {
            $ChildNodes = $Node.get_ChildNodes()
            if ($ChildNodes) {
                $this.StringBuilder.Append('@{')
                if ($this.LanguageMode -eq 'NoLanguage') {
                    if ($ChildNodes.Count -gt 0) {
                        $Indices = [PSSerialize]::NoLanguageItems
                        if (-not $Indices -or $ChildNodes.Count -lt $Indices.Count) { $Indices = 0..($ChildNodes.Count - 1) }
                        $LastIndex = $Null
                        foreach ($Index in $Indices) {
                            if ($IsSubNode -and $Index) { $this.StringBuilder.Append(";$([Abbreviate]::Ellipses)"); break }
                            if ($Null -ne $LastIndex) { $this.StringBuilder.Append(';') }
                            if ($Index -lt 0) { $Index = $ChildNodes.Count + $Index }
                            if ($Index -gt $LastIndex + 1) { $this.StringBuilder.Append("$([Abbreviate]::Ellipses);") }
                            $this.StringBuilder.Append([VariableColor](
                                [PSKeyExpression]::new($ChildNodes[$Index].Name, [PSSerialize]::MaxKeyLength)))
                            $this.StringBuilder.Append('=')
                            if (-not $IsSubNode -or $this.StringBuilder.Length -le [PSSerialize]::MaxKeyLength) {
                                $this.StringBuilder.Append($this.Stringify($ChildNodes[$Index]))
                            }
                            else { $this.StringBuilder.Append([Abbreviate]::Ellipses) }
                            $LastIndex = $Index
                        }
                    }
                }
                else {
                    $this.Offset++
                    $StartLine = $this.LineNumber
                    $Index = 0
                    $ExpandSingle = $this.ExpandSingleton -or $ChildNodes.Count -gt 1 -or $ChildNodes[0] -isnot [PSLeafNode]
                    foreach ($ChildNode in $ChildNodes) {
                        if ($ChildNode.Name -eq 'TypeId' -and $Node._Value -is $ChildNode._Value) { continue }
                        if ($Index++) {
                            $Separator = if ($this.ExpandDepth -ge 0) { '; ' } else { ';' }
                            $this.NewWord($Separator)
                        }
                        elseif ($this.ExpandDepth -ge 0) {
                            if ($ExpandSingle) { $this.NewWord() } else { $this.StringBuilder.Append(' ') }
                        }
                        $this.StringBuilder.Append([PSKeyExpression]::new($ChildNode.Name, $this.LanguageMode, ($this.ExpandDepth -lt 0)))
                        if ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' = ') } else { $this.StringBuilder.Append('=') }
                        $this.Stringify($ChildNode)
                    }
                    $this.Offset--
                    if ($this.LineNumber -gt $StartLine) { $this.NewWord() }
                    elseif ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' ') }
                }
                $this.StringBuilder.Append('}')
            }
            elseif ($Node -is [PSObjectNode] -and $TypeInitializer) { $this.StringBuilder.Append('::new()') }
            else { $this.StringBuilder.Append('@{}') }
        }
    }

    hidden NewWord() { $this.NewWord(' ') }
    hidden NewWord([String]$Separator) {
        if ($this.Offset -le $this.ExpandDepth) {
            $this.StringBuilder.AppendLine()
            for($i = $this.Offset; $i -gt 0; $i--) {
                $this.StringBuilder.Append($this.Indent)
            }
            $this.LineNumber++
        }
        else {
            $this.StringBuilder.Append($Separator)
        }
    }

    [String] ToString() {
        if ($this._Object -is [PSNode]) { $Node = $this._Object }
        else { $Node = [PSNode]::ParseInput($this._Object) }
        $this.StringBuilder = [System.Text.StringBuilder]::new()
        $this.Stringify($Node)
        return $this.StringBuilder.ToString()
    }
}
Class ANSI {
    # Retrieved from Get-PSReadLineOption
    static [String]$CommandColor
    static [String]$CommentColor
    static [String]$ContinuationPromptColor
    static [String]$DefaultTokenColor
    static [String]$EmphasisColor
    static [String]$ErrorColor
    static [String]$KeywordColor
    static [String]$MemberColor
    static [String]$NumberColor
    static [String]$OperatorColor
    static [String]$ParameterColor
    static [String]$SelectionColor
    static [String]$StringColor
    static [String]$TypeColor
    static [String]$VariableColor

    # Hardcoded (if valid Get-PSReadLineOption)
    static [String]$Reset
    static [String]$ResetColor
    static [String]$InverseColor
    static [String]$InverseOff

    Static ANSI() {
        $PSReadLineOption = try { Get-PSReadLineOption -ErrorAction SilentlyContinue } catch { $null }
        if (-not $PSReadLineOption) { return }
        $ANSIType = [ANSI] -as [Type]
        foreach ($Property in [ANSI].GetProperties()) {
            $PSReadLineProperty = $PSReadLineOption.PSObject.Properties[$Property.Name]
            if ($PSReadLineProperty) {
                $ANSIType.GetProperty($Property.Name).SetValue($Property.Name, $PSReadLineProperty.Value)
            }
        }
        $Esc = [char]0x1b
        [ANSI]::Reset        = "$Esc[0m"
        [ANSI]::ResetColor   = "$Esc[39m"
        [ANSI]::InverseColor = "$Esc[7m"
        [ANSI]::InverseOff   = "$Esc[27m"
    }
}
Class TextStyle {
    hidden [String]$Text
    hidden [String]$AnsiCode
    hidden [String]$ResetCode = [ANSI]::Reset
    TextStyle ([String]$Text, [String]$AnsiCode, [String]$ResetCode) {
        $this.Text = $Text
        $this.AnsiCode = $AnsiCode
        $this.ResetCode = $ResetCode
    }
    TextStyle ([String]$Text, [String]$AnsiCode) {
        $this.Text = $Text
        $this.AnsiCode = $AnsiCode
    }
    [String] ToString() {
        if ($this.ResetCode -eq [ANSI]::ResetColor) {
            return "$($this.AnsiCode)$($this.Text.Replace($this.ResetCode, $this.AnsiCode))$($this.ResetCode)"
        }
        else {
            return "$($this.AnsiCode)$($this.Text)$($this.ResetCode)"
        }
    }
}
class XdnName {
    hidden [Bool]$_Literal
    hidden $_IsVerbatim
    hidden $_ContainsWildcard
    hidden $_Value

    hidden Initialize($Value, $Literal) {
        $this._Value = $Value
        if ($Null -ne $Literal) { $this._Literal = $Literal } else { $this._Literal = $this.IsVerbatim() }
        if ($this._Literal) {
            $XdnName = [XdnName]::new()
            $XdnName._ContainsWildcard = $False
         }
        else {
            $XdnName = [XdnName]::new()
            $XdnName._ContainsWildcard = $null
        }

    }
    XdnName() {}
    XdnName($Value)                    { $this.Initialize($Value, $null) }
    XdnName($Value, [Bool]$Literal)    { $this.Initialize($Value, $Literal) }
    static [XdnName]Literal($Value)    { return [XdnName]::new($Value, $true) }
    static [XdnName]Expression($Value) { return [XdnName]::new($Value, $false) }

    [Bool] IsVerbatim() {
        if ($Null -eq $this._IsVerbatim) {
            $this._IsVerbatim = $this._Value -is [String] -and $this._Value -Match '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
        }
        return $this._IsVerbatim
    }

    [Bool] ContainsWildcard() {
        if ($Null -eq $this._ContainsWildcard) {
            $this._ContainsWildcard = $this._Value -is [String] -and $this._Value -Match '(?<=([^`]|^)(``)*)[\?\*]'
        }
        return $this._ContainsWildcard
    }

    [Bool] Equals($Object) {
        if ($this._Literal)               { return $this._Value -eq $Object }
        elseif ($this.ContainsWildcard()) { return $Object -Like $this._Value }
        else                              { return $this._Value -eq $Object }
    }

    [String] ToString($Colored) {
        $Color = if ($Colored) {
            if ($this._Literal)               { [ANSI]::VariableColor }
            elseif (-not $this.IsVerbatim())  { [ANSI]::StringColor }
            elseif ($this.ContainsWildcard()) { [ANSI]::EmphasisColor }
            else                              { [ANSI]::VariableColor }
        }
        $String =
            if ($this._Literal) { "'" + "$($this._Value)".Replace("'", "''") + "'" }
            else { "$($this._Value)" -replace '(?<!([^`]|^)(``)*)[\.\[\~\=\/]', '`${0}' } # Escape any Xdn operator (that isn't yet escaped)
        $Reset = if ($Colored) { [ANSI]::ResetColor }
        return $Color + $String + $Reset
    }
    [String] ToString()        { return $this.ToString($False) }
    [String] ToColoredString() { return $this.ToString($True) }
}
class XdnPath {
    hidden $_Entries = [List[KeyValuePair[XdnType, Object]]]::new()

    hidden [Object]get_Entries() { return ,$this._Entries } # Read-only

    XdnPath ([String]$Path)                 { $this.FromString($Path, $False) }
    XdnPath ([String]$Path, [Bool]$Literal) { $this.FromString($Path, $Literal) }
    XdnPath ([PSNodePath]$Path) {
        foreach ($Node in $Path.Nodes) {
            Switch ($Node.NodeOrigin) {
                Root { $this.Add('Root',  $Null) }
                List { $this.Add('Index', $Node.Name) }
                Map  { $this.Add('Child', [XdnName]$Node.Name) }
            }
        }
    }

    hidden AddError($Value) {
        $this._Entries.Add([KeyValuePair[XdnType, Object]]::new('Error', $Value))
    }

    Add ($EntryType, $Value) {
        if ($EntryType -eq '/') {
            if ($this._Entries.Count -eq 0) { $this.AddError($Value) }
            elseif ($this._Entries[-1].Key -NotIn 'Child', 'Descendant', 'Offspring', 'Equals') { $this.AddError($Value) }
            else {
                $EntryValue = $this._Entries[-1].Value
                if ($EntryValue -IsNot [IList]) { $EntryValue = [List[Object]]$EntryValue }
                $EntryValue.Add($Value)
                $this._Entries[-1] = [KeyValuePair[XdnType, Object]]::new($this._Entries[-1].Key, $EntryValue)
            }
        }
        else {
            $XdnType = Switch ($EntryType) {
                '.'     { 'Child' }
                '~'     { 'Descendant' }
                '~~'    { 'Offspring' }
                '='     { 'Equals' }
                default { $EntryType }
            }
            if ($XdnType -in [XdnType].GetEnumNames()) {
                $this._Entries.Add([KeyValuePair[XdnType, Object]]::new($XdnType, $Value))
            } else { $this.AddError($Value) }

        }
    }

    hidden FromString ([String]$Path, [Bool]$Literal) {
        $XdnOperator = $Null
        if (-not $this._Entries.Count) {
            $IsRoot = if ($Literal) { $Path -NotMatch '^\.' } else { $Path -NotMatch '^(?<=([^`]|^)(``)*)\.' }
            if ($IsRoot) {
                $this.Add('Root', $Null)
                $XdnOperator = 'Child'
            }
        }
        $Length  = [Int]::MaxValue
        while ($Path) {
            if ($Path.Length -ge $Length) { break }
            $Length = $Path.Length
            if ($Path[0] -in "'", '"') {
                if (-not $XdnOperator) { $XdnOperator = 'Child' }
                $Ast = [Parser]::ParseInput($Path, [ref]$Null, [ref]$Null)
                $StringAst = $Ast.EndBlock.Statements.Find({ $args[0] -is [StringConstantExpressionAst] }, $False)
                if ($Null -ne $StringAst) {
                    $this.Add($XdnOperator, [XdnName]::Literal($StringAst[0].Value))
                    $Path = $Path.SubString($StringAst[0].Extent.EndOffset)
                }
                else { # Probably a quoting error
                    $this.Add($XdnOperator, [XdnName]::Literal($Path, $True))
                    $Path = $Null
                }
            }
            else {
                $Match = if ($Literal) { [regex]::Match($Path, '[\.\[]') } else { [regex]::Match($Path, '(?<=([^`]|^)(``)*)[\.\[\~\=\/]') }
                $Match = [regex]::Match($Path, '(?<=([^`]|^)(``)*)\~\~?|[\.\[\=\/]')
                if ($Match.Success -and $Match.Index -eq 0) { # Operator
                    $IndexEnd  = if ($Match.Value -eq '[') { $Path.IndexOf(']') }
                    $Ancestors = if ($Match.Value -eq '.' -and $Path -Match '^\.\.+') { $Matches[0].Length - 1 }
                    if ($IndexEnd -gt 0) {
                        $Index = $Path.SubString(1, ($IndexEnd - 1))
                        $CommandAst = [Parser]::ParseInput($Index, [ref]$Null, [ref]$Null).EndBlock.Statements.PipelineElements
                        if ($CommandAst -is [CommandExpressionAst]) { $Index = $CommandAst.expression.Value }
                        $this.Add('Index', $Index)
                        $Path = $Path.SubString(($IndexEnd + 1))
                        $XdnOperator = $Null
                    }
                    elseif ($Ancestors) {
                        $this.Add('Ancestor', $Ancestors)
                        $Path = $Path.Substring($Ancestors + 1)
                        $XdnOperator = 'Child'
                    }
                    elseif ($Match.Value -in '.', '~', '~~', '=', '/' -and $Match.Value -ne $XdnOperator) {
                        $XdnOperator = $Match.Value
                        $Path = $Path.Substring($Match.Value.Length)
                    }
                    else {
                        $XdnOperator = 'Error'
                        $this.Add($XdnOperator, $Match.Value)
                        $Path = $Path.Substring(1)
                    }
                }
                elseif ($Match.Success) {
                    if (-not $XdnOperator) { $XdnOperator = 'Child' }
                    $Name = $Path.SubString(0, $Match.Index)
                    $Value = if ($Literal) { [XdnName]::Literal($Name) } else { [XdnName]::Expression($Name) }
                    $this.Add($XdnOperator, $Value)
                    $Path = $Path.SubString($Match.Index)
                    $XdnOperator = $Null
                }
                else {
                    $Value = if ($Literal) { [XdnName]::Literal($Path) } else { [XdnName]::Expression($Path)}
                    $this.Add($XdnOperator, $Value)
                    $Path = $Null
                }
            }
        }
    }

    [String] ToString([String]$VariableName, [Bool]$Colored) {
        $RegularColor  = if ($Colored) { [ANSI]::VariableColor }
        $OperatorColor = if ($Colored) { [ANSI]::CommandColor }
        $ErrorColor    = if ($Colored) { [ANSI]::ErrorColor }
        $ResetColor    = if ($Colored) { [ANSI]::ResetColor }

        $Path = [System.Text.StringBuilder]::new()
        $PreviousEntry = $Null
        foreach ($Entry in $this._Entries) {
            $Value = $Entry.Value
            $Append = Switch ($Entry.Key) {
                Root        { "$OperatorColor$VariableName" }
                Ancestor    { "$OperatorColor$('.' * $Value)" }
                Index       {
                                $Dot = if (-not $PreviousEntry -or $PreviousEntry.Key -eq 'Ancestor') { "$OperatorColor." }
                                if ([int]::TryParse($Value, [Ref]$Null)) { "$Dot$RegularColor[$Value]" }
                                else { "$ErrorColor[$Value]" }
                            }
                Child       { "$RegularColor.$(@($Value).foreach{ $_.ToString($Colored) }   -Join ""$OperatorColor/"")" }
                Descendant  { "$OperatorColor~$(@($Value).foreach{ $_.ToString($Colored) }  -Join ""$OperatorColor/"")" }
                Offspring   { "$OperatorColor~~$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Equals      { "$OperatorColor=$(@($Value).foreach{ $_.ToString($Colored) }  -Join ""$OperatorColor/"")" }
                Default     { "$ErrorColor$($Value)" }
            }
            $Path.Append($Append)
            $PreviousEntry = $Entry
        }
        $Path.Append($ResetColor)
        return $Path.ToString()
    }
    [String] ToString()                             { return $this.ToString($Null        , $False)}
    [String] ToString([String]$VariableName)        { return $this.ToString($VariableName, $False)}
    [String] ToColoredString()                      { return $this.ToString($Null,         $True)}
    [String] ToColoredString([String]$VariableName) { return $this.ToString($VariableName, $True)}

    static XdnPath() {
        Use-ClassAccessors
    }
}
class LogicalOperator : LogicalTerm {
    hidden [LogicalOperatorEnum]$Value
    LogicalOperator ([LogicalOperatorEnum]$Operator) { $this.Value = $Operator }
    LogicalOperator ([String]$Operator) { $this.Value = [LogicalOperatorEnum]$Operator }
    [String]ToString() { return $this.Value }
}
class LogicalVariable : LogicalTerm {
    hidden [Object]$Value
    LogicalVariable ($Variable) { $this.Value = $Variable }
    [String]ToString() {
        if ($this.Value -is [String]) {
            return "'$($this.Value -Replace "'", "''")'"
        }
        else { return $this.Value }
    }
}
class LogicalFormula : LogicalTerm {
    hidden static $OperatorSymbols = @{
        '!' = [LogicalOperatorEnum]'Not'
        ',' = [LogicalOperatorEnum]'And'
        '*' = [LogicalOperatorEnum]'And'
        '|' = [LogicalOperatorEnum]'Or'
        '+' = [LogicalOperatorEnum]'Or'
    }
    hidden static [Int[]]$OperatorNameLengths

    hidden [List[LogicalTerm]]$Terms = [List[LogicalTerm]]::new()
    hidden [Int]$Pointer

    GetFormula([String]$Expression, [Int]$Start) {
        $SubExpression = $Start -gt 0
        $InString = $null # Quote type (double - or single quoted)
        $Escaped = $null
        $this.Pointer = $Start
        While ($this.Pointer -le $Expression.Length) {
            $Char = if ($this.Pointer -lt $Expression.Length) { $Expression[$this.Pointer] }
            if ($InString) {
                if ($Char -eq $InString) {
                    if ($this.Pointer + 1 -lt $Expression.Length -and $Expression[$this.Pointer + 1] -eq $InString) {
                        $Escaped = $true
                         $this.Pointer++
                    }
                    else {
                        $Name = $Expression.SubString($Start + 1, ($this.Pointer - $Start - 1))
                        if ($Escaped) { $Name = $Name.Replace("$InString$InString", $InString) }
                        $this.Terms.Add([LogicalVariable]::new($Name))
                        $InString = $Null
                        $Start = $this.Pointer + 1
                    }
                }
            }
            elseif ('"', "'" -eq $Char) {
                $InString = $Char
                $Escaped = $false
                $Start = $this.Pointer
            }
            elseif ($Char -eq '(') {
                $Formula = [LogicalFormula]::new($Expression, ($this.Pointer + 1))
                $this.Terms.Add($Formula)
                $this.Pointer = $Formula.Pointer
                $Start = $this.Pointer + 1
            }
            elseif ($Char -in $Null, ' ', ')' + [LogicalFormula]::OperatorSymbols.Keys) {
                $Length = $this.Pointer - $Start
                if ($Length -gt 0) {
                    $Term = $Expression.SubString($Start, $Length)
                    if ([LogicalOperatorEnum].GetEnumNames() -eq $Term) {
                        $this.Terms.Add([LogicalOperator]::new($Term))
                    }
                    else {
                        $Double = 0
                        if ([double]::TryParse($Term, [Ref]$Double)) {
                            $this.Terms.Add([LogicalVariable]::new($Double))
                        }
                        else {
                            $this.Terms.Add([LogicalVariable]::new($Term))
                        }
                    }
                }
                if ($Char -eq ')') { return }
                if ($Char -gt ' ') {
                    $this.Terms.Add([LogicalOperator]::new([LogicalFormula]::OperatorSymbols($Char)))
                }
                $Start = $this.Pointer + 1
            }
            # elseif ($Char -le ' ' -or $Null -eq $Char) { # A space or any control code
            #     if ($Start -lt $this.Pointer) {
            #         $this.Terms.Add($this.GetUnquotedTerm($Expression, $Start, ($this.Pointer - $Start)))
            #     }
            #     $Start = $this.Pointer + 1
            # }
            $this.Pointer++
        }
        if ($InString) { Throw "Missing the terminator: $InString in logical expression: $Expression" }
        if ($SubExpression) { Throw "Missing closing ')' in logical expression: $Expression" }
    }

    LogicalFormula ([String]$Expression) {
        $this.GetFormula($Expression, 0)
        if ($this.Pointer -lt $Expression.Length) {
            Throw "Unexpected token ')' at position $($this.Pointer) in logical expression: $Expression"
        }
    }

    LogicalFormula ([String]$Expression, $Start) {
        $this.GetFormula($Expression, $Start)
    }

    Append ([LogicalOperator]$Operator, [LogicalFormula]$Formula) {
        if ($Operator.Value -eq 'Not') { $this.Terms.Add([LogicalOperator]'And') }
        $this.Terms.Add($Operator)
        $this.Terms.AddRange($Formula.Terms)
    }

    [String] ToString() {
        $StringBuilder = [System.Text.StringBuilder]::new()
        $Stack = [System.Collections.Stack]::new()
        $Enumerator = $this.Terms.GetEnumerator()
        $Term = $null
        while ($true) {
            while ($Enumerator.MoveNext()) {
                if ($Null -ne $Term) {
                    $null = $StringBuilder.Append([ANSI]::ResetColor) # Not really necessarily
                    $null = $StringBuilder.Append(' ')
                }
                $Term = $Enumerator.Current
                if ($Term -is [LogicalVariable]) {
                    if ($Term.Value -is [String])     { $null = $StringBuilder.Append([ANSI]::VariableColor) }
                    else                              { $null = $StringBuilder.Append([ANSI]::NumberColor) }
                }
                elseif ($Term -is [LogicalOperator])  { $null = $StringBuilder.Append([ANSI]::OperatorColor) }
                else { # if ($Term -is [LogicalFormula])
                    $null = $StringBuilder.Append([ANSI]::StringColor)
                    $null = $StringBuilder.Append('(')
                    $Stack.Push($Enumerator)
                    $Enumerator = $Term.Terms.GetEnumerator()
                    $Term = $null
                    continue
                }
                $null = $StringBuilder.Append($Term)
            }
            if (-not $Stack.Count) {
                $null = $StringBuilder.Append([ANSI]::ResetColor)
                break
            }
            $null = $StringBuilder.Append([ANSI]::StringColor)
            $null = $StringBuilder.Append(')')
            $Enumerator = $Stack.Pop()
        }
        return $StringBuilder.ToString()
    }
}
Class PSLeafNode : PSNode {

    hidden MaxDepthReached() { } # return nothing knowing that leaf nodes terminate the path anyways

    hidden PSLeafNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    [Int]GetHashCode($CaseSensitive) {
        if ($Null -eq $this._Value) { return '$Null'.GetHashCode() }
        if ($CaseSensitive) { return $this._Value.GetHashCode() }
        else {
            if ($this._Value -is [String]) { return $this._Value.ToUpper().GetHashCode() } # Windows PowerShell doesn't have a System.HashCode structure
            else { return $this._Value.GetHashCode() }
        }
    }

    [string]ToString() {
        return "$([TypeColor][PSSerialize]::new($this, [PSLanguageMode]'NoLanguage'))"
    }
}
Class PSCollectionNode : PSNode {
    hidden static PSCollectionNode() { Use-ClassAccessors }
    hidden [Dictionary[bool,int]]$_HashCode # Unlike the value HashCode, the default (bool = $false) node HashCode is case insensitive
    hidden [Dictionary[bool,int]]$_ReferenceHashCode # if changed, recalculate the (bool = case sensitive) node's HashCode

    hidden [bool]MaxDepthReached() {
        # Check whether the max depth has been reached.
        # Warn if it has, but suppress the warning if
        # it took less then 5 seconds since the last
        # time it reached the max depth.
        $MaxDepthReached = $this.Depth -ge $this.RootNode._MaxDepth
        if ($MaxDepthReached) {
            if (([DateTime]::Now - $this.RootNode.MaxDepthWarningTime).TotalSeconds -gt 5) {
                Write-Warning "$($this.Path) reached the maximum depth of $($this.RootNode._MaxDepth)."
            }
            $this.RootNode.MaxDepthWarningTime = [DateTime]::Now
        }
        return $MaxDepthReached
    }

    hidden WarnSelector ([PSCollectionNode]$Node, [String]$Name) {
        if ($Node -is [PSListNode]) {
            $SelectionName  = "'$Name'"
            $CollectionType = 'list'
        }
        else {
            $SelectionName  = "[$Name]"
            $CollectionType = 'list'
        }
        Write-Warning "Expected $SelectionName to be a $CollectionType selector for: <Object>$($Node.Path)"
    }

    hidden [List[Ast]] GetAstSelectors ($Ast) {
        $List = [List[Ast]]::new()
        if ($Ast -isnot [Ast]) {
            $Ast = [Parser]::ParseInput("`$_$Ast", [ref]$Null, [ref]$Null)
            $Ast = $Ast.EndBlock.Statements.PipeLineElements.Expression
        }
        if ($Ast -is [IndexExpressionAst]) {
            $List.AddRange($this.GetAstSelectors($Ast.Target))
            $List.Add($Ast)
        }
        elseif ($Ast -is [MemberExpressionAst]) {
            $List.AddRange($this.GetAstSelectors($Ast.Expression))
            $List.Add($Ast)
        }
        elseif ($Ast.Extent.Text -ne '$_') {
            Throw "Parse error: $($Ast.Extent.Text)"
        }
        return $List
    }

    [List[PSNode]]GetNodeList($Levels, [Bool]$LeafNodesOnly) {
        $NodeList = [List[PSNode]]::new()
        $Stack = [Stack]::new()
        $Stack.Push($this.get_ChildNodes().GetEnumerator())
        $Level = 1
        While ($Stack.Count -gt 0) {
            $Enumerator = $Stack.Pop()
            $Level--
            while ($Enumerator.MoveNext()) {
                $Node = $Enumerator.Current
                if ($Node.MaxDepthReached() -or ($Levels -ge 0 -and $Level -ge $Levels)) { break }
                if (-not $LeafNodesOnly -or $Node -is [PSLeafNode]) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode]) {
                    $Stack.Push($Enumerator)
                    $Level++
                    $Enumerator = $Node.get_ChildNodes().GetEnumerator()
                }
            }
        }
        return $NodeList
    }
    [List[PSNode]]GetNodeList()             { return $this.GetNodeList(1, $False) }
    [List[PSNode]]GetNodeList([Int]$Levels) { return $this.GetNodeList($Levels, $False) }
    hidden [PSNode[]]get_DescendantNodes()  { return $this.GetNodeList(-1, $False) }
    hidden [PSNode[]]get_LeafNodes()        { return $this.GetNodeList(-1, $True) }

    Sort() { $this.Sort($Null, 0) }
    Sort([ObjectComparison]$ObjectComparison) { $this.Sort($Null, $ObjectComparison) }
    Sort([String[]]$PrimaryKey) { $this.Sort($PrimaryKey, 0) }
    Sort([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.Sort($PrimaryKey, $ObjectComparison) }
    Sort([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) {
        # As the child nodes are sorted first, we just do a side-by-side node compare:
        $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'MatchMapOrder'
        $ObjectComparison = $ObjectComparison -band (-1 - [ObjectComparison]'IgnoreListOrder')
        $PSListNodeComparer = [PSListNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
        $PSMapNodeComparer = [PSMapNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
        $this.SortRecurse($PSListNodeComparer, $PSMapNodeComparer)
    }

    hidden SortRecurse([PSListNodeComparer]$PSListNodeComparer, [PSMapNodeComparer]$PSMapNodeComparer) {
        $NodeList = $this.GetNodeList()
        foreach ($Node in $NodeList) {
            if ($Node -is [PSCollectionNode]) { $Node.SortRecurse($PSListNodeComparer, $PSMapNodeComparer) }
        }
        if ($this -is [PSListNode]) {
            $NodeList.Sort($PSListNodeComparer)
            if ($NodeList.Count) { $this._Value = @($NodeList.Value) } else { $this._Value = @() }
        }
        else { # if ($Node -is [PSMapNode])
            $NodeList.Sort($PSMapNodeComparer)
            $Properties = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
            foreach($ChildNode in $NodeList) { $Properties[[Object]$ChildNode.Name] = $ChildNode.Value } # [Object] forces a key rather than an index (ArgumentOutOfRangeException)
            if ($this -is [PSObjectNode]) { $this._Value = [PSCustomObject]$Properties } else { $this._Value = $Properties }
        }
    }
}
Class PSListNode : PSCollectionNode {
    hidden static PSListNode() { Use-ClassAccessors }

    hidden PSListNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    hidden [Object]get_Count() {
        return $this._Value.get_Count()
    }

    hidden [Object]get_Names() {
        if ($this._Value.Length) { return ,@(0..($this._Value.Length - 1)) }
        return ,@()
    }

    hidden [Object]get_Values() {
        return ,@($this._Value)
    }

    hidden [Object]get_CaseMatters() { return $false }

    [Bool]Contains($Index) {
       return $Index -ge 0 -and $Index -lt $this.get_Count()
    }

    [Bool]Exists($Index) {
        return $Index -ge 0 -and $Index -lt $this.get_Count()
    }

    [Object]GetValue($Index) { return $this._Value[$Index] }
    [Object]GetValue($Index, $Default) {
        if (-not $This.Contains($Index)) { return $Default }
        return $this._Value[$Index]
    }

    SetValue($Index, $Value) {
        if ($Value -is [PSNode]) { $Value = $Value.Value }
        $this._Value[$Index] = $Value
    }

    Add($Value) {
        if ($Value -is [PSNode]) { $Value = $Value._Value }
        if ($this._Value.GetType().GetMethod('Add')) { $null = $This._Value.Add($Value) }
        else { $this._Value = ($this._Value + $Value) -as $this._Value.GetType() }
        $this.Cache.Remove('ChildNodes')
    }

    Remove($Value) {
        if ($Value -is [PSNode]) { $Value = $Value.Value }
        if (-not $this.Value.Contains($Value)) { return }
        if ($this.Value.GetType().GetMethod('Remove')) { $null = $this._value.remove($Value) }
        else {
            $cList = [List[Object]]::new()
            $iList = [List[Object]]::new()
            $ceq = $false
            foreach ($ChildNode in $this.get_ChildNodes()) {
                if (-not $ceq -and $ChildNode.Value -ceq $Value) { $ceq = $true } else { $cList.Add($ChildNode.Value) }
                if (-not $ceq -and $ChildNode.Value -ine $Value)                       { $iList.Add($ChildNode.Value) }
            }
            if ($ceq) { $this._Value = $cList -as $this._Value.GetType() }
            else      { $this._Value = $iList -as $this._Value.GetType() }
        }
        $this.Cache.Remove('ChildNodes')
    }

    RemoveAt([Int]$Index) {
        if ($Index -lt 0 -or $Index -ge $this.Value.Count) { Throw 'Index was out of range. Must be non-negative and less than the size of the collection.' }
        if ($this.Value.GetType().GetMethod('RemoveAt')) { $null = $this._Value.removeAt($Index) }
        else {
            $this._Value = $(for ($i = 0; $i -lt $this._Value.Count; $i++) {
                if ($i -ne $index) { $this._Value[$i] }
            }) -as $this.ValueType
        }
        $this.Cache.Remove('ChildNodes')
    }

    [Object]GetChildNode([Int]$Index) {
        if ($this.MaxDepthReached()) { return @() }
        $Count = $this._Value.get_Count()
        if ($Index -lt -$Count -or $Index -ge $Count) { throw "The <Object>$($this.Path) doesn't contain a child index: $Index" }
        if ($Index -lt 0) { $Index = $Count + $Index } # Negative index
        if (-not $this.Cache.ContainsKey('ChildNode')) { $this.Cache['ChildNode'] = [Dictionary[Int,Object]]::new() }
        if (
            -not $this.Cache.ChildNode.ContainsKey($Index) -or
            -not [Object]::ReferenceEquals($this.Cache.ChildNode[$Index]._Value, $this._Value[$Index])
        ) {
            $Node             = [PSNode]::ParseInput($this._Value[$Index])
            $Node._Name       = $Index
            $Node.Depth       = $this.Depth + 1
            $Node.RootNode    = [PSNode]$this.RootNode
            $Node.ParentNode  = $this
            $this.Cache.ChildNode[$Index] = $Node
        }
        return $this.Cache.ChildNode[$Index]
    }

    hidden [Object[]]get_ChildNodes() {
        if (-not $this.Cache.ContainsKey('ChildNodes')) {
            $ChildNodes = for ($Index = 0; $Index -lt $this._Value.get_Count(); $Index++) { $this.GetChildNode($Index) }
            if ($null -ne $ChildNodes) { $this.Cache['ChildNodes'] = $ChildNodes } else { $this.Cache['ChildNodes'] =  @() }
        }
        return $this.Cache['ChildNodes']
    }

    [Int]GetHashCode($CaseSensitive) {
        # The hash of a list node is equal if all items match the order and the case.
        # The primary keys and the list type are not relevant
        if ($null -eq $this._HashCode) {
            $this._HashCode = [Dictionary[bool,int]]::new()
            $this._ReferenceHashCode = [Dictionary[bool,int]]::new()
        }
        $ReferenceHashCode = $This._value.GetHashCode()
        if (-not $this._ReferenceHashCode.ContainsKey($CaseSensitive) -or $this._ReferenceHashCode[$CaseSensitive] -ne $ReferenceHashCode) {
            $this._ReferenceHashCode[$CaseSensitive] = $ReferenceHashCode
            $HashCode = '@()'.GetHashCode() # Empty lists have a common hash that is not 0
            $Index = 0
            foreach ($Node in $this.GetNodeList()) {
                $HashCode = $HashCode -bxor "$Index.$($Node.GetHashCode($CaseSensitive))".GetHashCode()
                $index++
            }
            $this._HashCode[$CaseSensitive] = $HashCode
        }
        return $this._HashCode[$CaseSensitive]
    }

    [string]ToString() {
        return "$([TypeColor][PSSerialize]::new($this, [PSLanguageMode]'NoLanguage'))"
    }
}
Class PSMapNode : PSCollectionNode {
    hidden static PSMapNode() { Use-ClassAccessors }

    [Int]GetHashCode($CaseSensitive) {
        # The hash of a map node is equal if all names and items match the order and the case.
        # The map type is not relevant
        if ($null -eq $this._HashCode) {
            $this._HashCode = [Dictionary[bool,int]]::new()
            $this._ReferenceHashCode = [Dictionary[bool,int]]::new()
        }
        $ReferenceHashCode = $This._value.GetHashCode()
        if (-not $this._ReferenceHashCode.ContainsKey($CaseSensitive) -or $this._ReferenceHashCode[$CaseSensitive] -ne $ReferenceHashCode) {
            $this._ReferenceHashCode[$CaseSensitive] = $ReferenceHashCode
            $HashCode = '@{}'.GetHashCode() # Empty maps have a common hash that is not 0
            $Index = 0
            foreach ($Node in $this.GetNodeList()) {
                $Name = if ($CaseSensitive) { $Node._Name } else { $Node._Name.ToUpper() }
                $HashCode = $HashCode -bxor "$Index.$Name=$($Node.GetHashCode())".GetHashCode()
                $Index++
            }
            $this._HashCode[$CaseSensitive] = $HashCode
        }
        return $this._HashCode[$CaseSensitive]
    }
}
Class PSDictionaryNode : PSMapNode {
    hidden static PSDictionaryNode() { Use-ClassAccessors }

    hidden PSDictionaryNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    hidden [Object]get_Count() {
        return $this._Value.get_Count()
    }

    hidden [Object]get_Names() {
        return ,$this._Value.get_Keys()
    }

    hidden [Object]get_Values() {
        return ,$this._Value.get_Values()
    }

    hidden [Object]get_CaseMatters() { #Returns Nullable[Boolean]
        if (-not $this.Cache.ContainsKey('CaseMatters')) {
            $this.Cache['CaseMatters'] = $null # else $Null means that there is no key with alphabetic characters in the dictionary
            foreach ($Key in $this._Value.Get_Keys()) {
                if ($Key -is [String] -and $Key -match '[a-z]') {
                    $Case = if ([Int][Char]($Matches[0]) -ge 97) { $Key.ToUpper() } else { $Key.ToLower() }
                    $this.Cache['CaseMatters'] = -not $this.Contains($Case) -or $Case -cin $this._Value.Get_Keys()
                    break
                }
            }
        }
        return $this.Cache['CaseMatters']
    }

    [Bool]Contains($Key) {
        if ($this._Value.GetType().GetMethod('ContainsKey')) {
            return $this._Value.ContainsKey($Key)
        }
        else {
            return $this._Value.Contains($Key)
        }
    }
    [Bool]Exists($Key) { return $this.Contains($Key) }

    [Object]GetValue($Key) { return $this._Value[$Key] }
    [Object]GetValue($Key, $Default) {
        if (-not $This.Contains($Key)) { return $Default }
        return $this._Value[$Key]
    }

    SetValue($Key, $Value) {
        if ($Value -is [PSNode]) { $Value = $Value.Value }
        $this._Value[$Key] = $Value
        $this.Cache.Remove('ChildNodes')
    }

    Add($Key, $Value) {
        if ($this.Contains($Key)) { Throw "Item '$Key' has already been added." }
        if ($Value -is [PSNode]) { $Value = $Value.Value }
        $this._Value.Add($Key, $Value)
        $this.Cache.Remove('ChildNodes')
    }

    Remove($Key) {
        $null = $this._Value.Remove($Key)
        $this.Cache.Remove('ChildNodes')
    }

    hidden RemoveAt($Key) { # General method for: ChildNode.Remove() { $_.ParentNode.Remove($_.Name) }
        if (-not $this.Contains($Key)) { Throw "Item '$Key' doesn't exist." }
        $null = $this._Value.Remove($Key)
        $this.Cache.Remove('ChildNodes')
    }

    [Object]GetChildNode([Object]$Key) {
        if ($this.MaxDepthReached()) { return @() }
        if (-not $this.Contains($Key)) { Throw "The <Object>$($this.Path) doesn't contain a child named: $Key" }
        if (-not $this.Cache.ContainsKey('ChildNode')) {
            # The ChildNode cache case sensitivity is based on the current dictionary population.
            # The ChildNode cache is always ordinal, if the contained dictionary is invariant, extra entries might
            # appear in the cache but shouldn't effect the results other than slightly slow down the performance.
            # In other words, do not use the cache to count the entries. Custom comparers are not supported.
            $this.Cache['ChildNode'] = if ($this.get_CaseMatters()) { [HashTable]::new() } else { @{} } # default is case insensitive
        }
        elseif (
            -not $this.Cache.ChildNode.ContainsKey($Key) -or
            -not [Object]::ReferenceEquals($this.Cache.ChildNode[$Key]._Value, $this._Value[$Key])
        ) {
            if($null -eq $this.get_CaseMatters()) { # If the case was undetermined, check the new key for case sensitivity
                $this.Cache.CaseMatters = if ($Key -is [String] -and $Key -match '[a-z]') {
                    $Case = if ([Int][Char]($Matches[0]) -ge 97) { $Key.ToUpper() } else { $Key.ToLower() }
                    -not $this._Value.Contains($Case) -or $Case -cin $this._Value.Get_Keys()
                }
                if ($this.get_CaseMatters()) {
                    $ChildNode = $this.Cache['ChildNode']
                    $this.Cache['ChildNode'] = [HashTable]::new() # Create a new cache as it appears to be case sensitive
                    foreach ($Key in $ChildNode.get_Keys()) { # Migrate the content
                        $this.Cache.ChildNode[$Key] = $ChildNode[$Key]
                    }
                }
            }
        }
        if (
            -not $this.Cache.ChildNode.ContainsKey($Key) -or
            -not [Object]::ReferenceEquals($this.Cache.ChildNode[$Key].Value, $this._Value[$Key])
        ) {
            $Node             = [PSNode]::ParseInput($this._Value[$Key])
            $Node._Name       = $Key
            $Node.Depth       = $this.Depth + 1
            $Node.RootNode    = [PSNode]$this.RootNode
            $Node.ParentNode  = $this
            $this.Cache.ChildNode[$Key] = $Node
        }
        return $this.Cache.ChildNode[$Key]
    }

    hidden [Object[]]get_ChildNodes() {
        if (-not $this.Cache.ContainsKey('ChildNodes')) {
            $ChildNodes = foreach ($Key in $this._Value.get_Keys()) { $this.GetChildNode($Key) }
            if ($null -ne $ChildNodes) { $this.Cache['ChildNodes'] = $ChildNodes } else { $this.Cache['ChildNodes'] =  @() }
        }
        return $this.Cache['ChildNodes']
    }

    [string]ToString() {
        return "$([TypeColor][PSSerialize]::new($this, [PSLanguageMode]'NoLanguage'))"
    }
}
Class PSObjectNode : PSMapNode {
    hidden static PSObjectNode() { Use-ClassAccessors }

    hidden PSObjectNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    hidden [Object]get_Count() {
        return @($this._Value.PSObject.Properties).get_Count()
    }

    hidden [Object]get_Names() {
        return ,$this._Value.PSObject.Properties.Name
    }

    hidden [Object]get_Values() {
        return ,$this._Value.PSObject.Properties.Value
    }

    hidden [Object]get_CaseMatters() { return $false }

    [Bool]Contains($Name) {
        return $this._Value.PSObject.Properties[$Name]
    }

    [Bool]Exists($Name) {
        return $this._Value.PSObject.Properties[$Name]
    }

    [Object]GetValue($Name) { return $this._Value.PSObject.Properties[$Name].Value }
    [Object]GetValue($Name, $Default) {
        if (-not $this.Contains($Name)) { return $Default }
        return $this._Value[$Name]
    }

    SetValue($Name, $Value) {
        if ($Value -is [PSNode]) { $Value = $Value.Value }
        if ($this._Value -isnot [PSCustomObject]) {
            $Properties = [Ordered]@{}
            foreach ($Property in $this._Value.PSObject.Properties) { $Properties[$Property.Name] = $Property.Value }
            $Properties[$Name] = $Value
            $this._Value = [PSCustomObject]$Properties
            $this.Cache.Remove('ChildNodes')
        }
        elseif ($this._Value.PSObject.Properties[$Name]) {
            $this._Value.PSObject.Properties[$Name].Value = $Value
        }
        else {
            Add-Member -InputObject $this._Value -Type NoteProperty -Name $Name -Value $Value
            $this.Cache.Remove('ChildNodes')
        }
    }

    Add($Name, $Value) {
        if ($this.Contains($Name)) { Throw "Item '$Name' has already been added." }
        $this.SetValue($Name, $Value)
    }

    Remove($Name) {
        $this._Value.PSObject.Properties.Remove($Name)
        $this.Cache.Remove('ChildNodes')
    }

    hidden RemoveAt($Name) { # General method for: ChildNode.Remove() { $_.ParentNode.Remove($_.Name) }
        if (-not $this.Contains($Name)) { Throw "Item '$Name' doesn't exist." }
        $this._Value.PSObject.Properties.Remove($Name)
        $this.Cache.Remove('ChildNodes')
    }

    [Object]GetChildNode([String]$Name) {
        if ($this.MaxDepthReached()) { return @() }
        if (-not $this.Contains($Name)) { Throw Throw "$($this.GetPathName('<Root>')) doesn't contain a child named: $Name"  }
        if (-not $this.Cache.ContainsKey('ChildNode')) { $this.Cache['ChildNode'] = @{} } # Object properties are case insensitive
        if (
            -not $this.Cache.ChildNode.ContainsKey($Name) -or
            -not [Object]::ReferenceEquals($this.Cache.ChildNode[$Name]._Value, $this._Value.PSObject.Properties[$Name].Value)
        ) {
            $Node             = [PSNode]::ParseInput($this._Value.PSObject.Properties[$Name].Value)
            $Node._Name       = $Name
            $Node.Depth       = $this.Depth + 1
            $Node.RootNode    = [PSNode]$this.RootNode
            $Node.ParentNode  = $this
            $this.Cache.ChildNode[$Name] = $Node
        }
        return $this.Cache.ChildNode[$Name]
    }

    hidden [Object[]]get_ChildNodes() {
        if (-not $this.Cache.ContainsKey('ChildNodes')) {
            $ChildNodes = foreach ($Property in $this._Value.PSObject.Properties) { $this.GetChildNode($Property.Name) }
            #     if ($Property.Value -isnot [Reflection.MemberInfo]) { $this.GetChildNode($Property.Name) }
            # }
            if ($null -ne $ChildNodes) { $this.Cache['ChildNodes'] = $ChildNodes } else { $this.Cache['ChildNodes'] =  @() }
        }
        return $this.Cache['ChildNodes']
    }

    [string]ToString() {
        return "$([TypeColor][PSSerialize]::new($this, [PSLanguageMode]'NoLanguage'))"
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
Class TextColor : TextStyle { TextColor($Text, $AnsiColor) : base($Text, $AnsiColor, [ANSI]::ResetColor) {} }
Class CommandColor : TextColor { CommandColor($Text) : base($Text, [ANSI]::CommandColor) {} }
Class CommentColor : TextColor { CommentColor($Text) : base($Text, [ANSI]::CommentColor) {} }
Class ContinuationPromptColor : TextColor { ContinuationPromptColor($Text) : base($Text, [ANSI]::ContinuationPromptColor) {} }
Class DefaultTokenColor : TextColor { DefaultTokenColor($Text) : base($Text, [ANSI]::DefaultTokenColor) {} }
Class EmphasisColor : TextColor { EmphasisColor($Text) : base($Text, [ANSI]::EmphasisColor) {} }
Class ErrorColor : TextColor { ErrorColor($Text) : base($Text, [ANSI]::ErrorColor) {} }
Class KeywordColor : TextColor { KeywordColor($Text) : base($Text, [ANSI]::KeywordColor) {} }
Class MemberColor : TextColor { MemberColor($Text) : base($Text, [ANSI]::MemberColor) {} }
Class NumberColor : TextColor { NumberColor($Text) : base($Text, [ANSI]::NumberColor) {} }
Class OperatorColor : TextColor { OperatorColor($Text) : base($Text, [ANSI]::OperatorColor) {} }
Class ParameterColor : TextColor { ParameterColor($Text) : base($Text, [ANSI]::ParameterColor) {} }
Class SelectionColor : TextColor { SelectionColor($Text) : base($Text, [ANSI]::SelectionColor) {} }
Class StringColor : TextColor { StringColor($Text) : base($Text, [ANSI]::StringColor) {} }
Class TypeColor : TextColor { TypeColor($Text) : base($Text, [ANSI]::TypeColor) {} }
Class VariableColor : TextColor { VariableColor($Text) : base($Text, [ANSI]::VariableColor) {} }
Class InverseColor : TextStyle { InverseColor($Text) : base($Text, [ANSI]::InverseColor, [ANSI]::InverseOff) {} }

#EndRegion Class

#Region Function

function Use-ClassAccessors {
<#
.SYNOPSIS
    Implements class getter and setter accessors.

.DESCRIPTION
    The [Use-ClassAccessors][1] cmdlet updates script property of a class from the getter and setter methods.
    Which are also known as [accessors or mutator methods][2].

    The getter and setter methods should use the following syntax:

    ### getter syntax

        [<type>] get_<property name>() {
            return <variable>
        }

    or:

        [Object] get_<property name>() {
            return ,[<Type>]<variable>
        }
    ### setter syntax

        set_<property name>(<variable>) {
            <code>
        }

    > [!NOTE]
    > A **setter** accessor requires a **getter** accessor to implement the related property.

    > [!NOTE]
    > In most cases, you might want to hide the getter and setter methods using the [`hidden` keyword][3]
    > on the getter and setter methods.

.EXAMPLE
    # Using class accessors

    The following example defines a getter and setter for a `value` property
    and a _readonly_ property for the type of the type of the contained value.

        Install-Script -Name Use-ClassAccessors

        Class ExampleClass {
            hidden $_Value
            hidden [Object] get_Value() {
                return $this._Value
            }
            hidden set_Value($Value) {
                $this._Value = $Value
            }
            hidden [Type]get_Type() {
                if ($Null -eq $this.Value) { return $Null }
                else { return $this._Value.GetType() }
            }
            hidden static ExampleClass() { Use-ClassAccessors }
        }

        $Example = [ExampleClass]::new()

        $Example.Value = 42         # Set value to 42
        $Example.Value              # Returns 42
        $Example.Type               # Returns [Int] type info
        $Example.Type = 'Something' # Throws readonly error

.PARAMETER Class

    Specifies the class from which the accessor need to be initialized.
    Default: The class from which this function is invoked (by its static initializer).

.PARAMETER Property

    Filters the property that requires to be (re)initialized.
    Default: All properties in the given class

.PARAMETER Force

    Indicates that the cmdlet reloads the specified accessors,
    even if the accessors already have been defined for the concerned class.

.LINK
    [1]: https://github.com/iRon7/Use-ClassAccessors "Online Help"
    [2]: https://en.wikipedia.org/wiki/Mutator_method "Mutator method"
    [3]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#hidden-keyword "Hidden keyword in classes"
#>
    param(
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Class,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Property,

        [switch]$Force
    )

    process {
        $ClassNames =
            if ($Class) { $Class }
            else {
                $Caller = (Get-PSCallStack)[1]
                if ($Caller.FunctionName -ne '<ScriptBlock>') {
                    $Caller.FunctionName
                }
                elseif ($Caller.ScriptName) {
                    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($Caller.ScriptName, [ref]$Null, [ref]$Null)
                    $Ast.EndBlock.Statements.where{ $_.IsClass }.Name
                }
            }
        foreach ($ClassName in $ClassNames) {
            $TargetType = $ClassName -as [Type]
            if (-not $TargetType) { Write-Warning "Class not found: $ClassName" }
            $TypeData = Get-TypeData -TypeName $ClassName
            $Members = if ($TypeData -and $TypeData.Members) { $TypeData.Members.get_Keys() }
            $Methods =
                if ($Property) {
                    $TargetType.GetMethod("get_$Property")
                    $TargetType.GetMethod("set_$Property")
                }
                else {
                    $NativeProperties = $TargetType.GetProperties()
                    $NativeNames = if ($NativeProperties) { $NativeProperties.Name }
                    $targetType.GetMethods().where{
                        -not $_.IsStatic -and
                        ($_.Name -Like 'get_*' -or  $_.Name -Like 'set_*') -and
                        $_.Name -NotLike '???__*' -and
                        $_.Name.SubString(4) -notin $NativeNames
                    }
                }
            $Accessors = [Ordered]@{}
            foreach ($Method in $Methods) {
                $Member = $Method.Name.SubString(4)
                if (-not $Force -and $Member -in $Members) { continue }
                $Parameters = $Method.GetParameters()
                if ($Method.Name -Like 'get_*') {
                    if ($Parameters.Count -eq 0) {
                        if ($Method.ReturnType.IsArray) {
                            $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Invoke = `$Method.Invoke(`$this, `$Null)
`$Output = `$Invoke -as '$($Method.ReturnType.FullName)'
if (@(`$Invoke).Count -gt 1) { `$Output } else { ,`$Output }
"@
                        }
                        else {
                            $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Method.Invoke(`$this, `$Null) -as '$($Method.ReturnType.FullName)'
"@
                        }
                        if (-not $Accessors.Contains($Member)) { $Accessors[$Member] = @{} }
                        $Accessors[$Member].Value = [ScriptBlock]::Create($Expression)
                    }
                    else { Write-Warning "The getter '$($Method.Name)' is skipped as it is not parameter-less." }
                }
                elseif ($Method.Name -Like 'set_*') {
                    if ($Parameters.Count -eq 1) {
                        $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Method.Invoke(`$this, `$Args)
"@
                        if (-not $Accessors.Contains($Member)) { $Accessors[$Member] = @{} }
                        $Accessors[$Member].SecondValue = [ScriptBlock]::Create($Expression)
                    }
                    else { Write-Warning "The setter '$($Method.Name)' is skipped as it does not have a single parameter" }
                }
            }
            foreach ($MemberName in $Accessors.get_Keys()) {
                $TypeData = $Accessors[$MemberName]
                if ($TypeData.Contains('Value')) {
                    $TypeData.TypeName   = $ClassName
                    $TypeData.MemberType = 'ScriptProperty'
                    $TypeData.MemberName = $MemberName
                    $TypeData.Force      = $Force
                    Update-TypeData @TypeData
                }
                else { Write-Warning "'[$ClassName].set_$MemberName()' accessor requires a '[$ClassName].get_$MemberName()' accessor." }
            }
        }
    }
}

#EndRegion Function

#Region Cmdlet

function Compare-ObjectGraph {
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
function ConvertFrom-Expression {
<#
.SYNOPSIS
    Deserializes a PowerShell expression to an object.

.DESCRIPTION
    The `ConvertFrom-Expression` cmdlet safely converts a PowerShell formatted expression to an object-graph
    existing of a mixture of nested arrays, hash tables and objects that contain a list of strings and values.

.PARAMETER InputObject
    Specifies the PowerShell expressions to convert to objects. Enter a variable that contains the string,
    or type a command or expression that gets the string. You can also pipe a string to ConvertFrom-Expression.

    The **InputObject** parameter is required, but its value can be an empty string.
    The **InputObject** value can't be `$null` or an empty string.

.PARAMETER LanguageMode
    Defines which object types are allowed for the deserialization, see: [About language modes][2]

    * Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,
      `[String]`, `[Array]` or `[HashTable]`.
    * Any variable that is not `$True`, `$False` or `$Null` will be converted to a literal string, e.g. `$Test`.

    > [!Caution]
    >
    > In full language mode, `ConvertTo-Expression` permits all type initializers. Cmdlets, functions,
    > CIM commands, and workflows will *not* be invoked by the `ConvertFrom-Expression` cmdlet.
    >
    > Take reasonable precautions when using the `Invoke-Expression -LanguageMode Full` command in scripts.
    > Verify that the class types in the expression are safe before instantiating them. In general, it is
    > best to design your configuration expressions with restricted or constrained classes, rather than
    > allowing full freeform expressions.

.PARAMETER ListAs
    If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown
    or denied type initializer will be converted to the given list type.

.PARAMETER MapAs
    If supplied, the Hash table literal syntax `@{ }` syntaxes without an type initializer or with an unknown
    or denied type initializer will be converted to the given map (dictionary or object) type.

#>

[Alias('cfe')]
[CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ConvertFrom-Expression.md')][OutputType([Object])] param(

    [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
    [Alias('Expression')][String]$InputObject,

    [ValidateScript({ $_ -ne 'NoLanguage' })]
    [System.Management.Automation.PSLanguageMode]$LanguageMode = 'Restricted',

    [ValidateNotNull()][Alias('ArrayAs')]$ListAs,

    [ValidateNotNull()][Alias('DictionaryAs')]$MapAs
)

begin {
    function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
        if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
    }

    if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }

    $ListNode = if ($ListAs) { [PSNode]::ParseInput([PSInstance]::Create($ListAs)) }
    $MapNode  = if ($MapAs)  { [PSNode]::ParseInput([PSInstance]::Create($MapAs)) }

    if (
        $ListNode -is [PSMapNode] -and $MapNode -is [PSListNode] -or
        -not $ListNode -and $MapNode -is [PSListNode] -or
        $ListNode -is [PSMapNode] -and -not $MapNode
    ) {
        $ListNode, $MapNode = $MapNode, $ListNode # In case the parameter positions are swapped
    }

    $ListType = if ($ListNode) {
        if ($ListType -is [PSListNode]) { $ListNode.ValueType }
        else { StopError 'The -ListAs parameter requires a string, type or an object example that supports a list structure' }
    }

    $MapType = if ($MapNode) {
        if ($MapNode -is [PSMapNode]) { $MapNode.ValueType }
        else { StopError 'The -MapAs parameter requires a string, type or an object example that supports a map structure' }
    }
    if ('System.Management.Automation.PSCustomObject' -eq $MapNode.ValueType) { $MapType = 'PSCustomObject' -as [type] } # https://github.com/PowerShell/PowerShell/issues/2295

}

process {
    [PSDeserialize]::new($InputObject, $LanguageMode, $ListType, $MapType).Object
}
}
function ConvertTo-Expression {
<#
.SYNOPSIS
    Serializes an object to a PowerShell expression.

.DESCRIPTION
    The ConvertTo-Expression cmdlet converts (serializes) an object to a PowerShell expression.
    The object can be stored in a variable, (.psd1) file or any other common storage for later use or to be ported
    to another system.

    expressions might be restored to an object using the native [Invoke-Expression] cmdlet:

        $Object = Invoke-Expression ($Object | ConvertTo-Expression)

    > [!Warning]
    > Take reasonable precautions when using the Invoke-Expression cmdlet in scripts. When using `Invoke-Expression`
    > to run a command that the user enters, verify that the command is safe to run before running it.
    > In general, it is best to restore your objects using [ConvertFrom-Expression].

    > [!Note]
    > Some object types can not be reconstructed from a simple serialized expression.

.INPUTS
    Any. Each objects provided through the pipeline will converted to an expression. To concatenate all piped
    objects in a single expression, use the unary comma operator,  e.g.: `,$Object | ConvertTo-Expression`

.OUTPUTS
    String[]. `ConvertTo-Expression` returns a PowerShell [String] expression for each input object.

.PARAMETER InputObject
    Specifies the objects to convert to a PowerShell expression. Enter a variable that contains the objects,
    or type a command or expression that gets the objects. You can also pipe one or more objects to
    `ConvertTo-Expression.`

.PARAMETER LanguageMode
    Defines which object types are allowed for the serialization, see: [About language modes][2]
    If a specific type isn't allowed in the given language mode, it will be substituted by:

    * **`$Null`** in case of a null value
    * **`$False`** in case of a boolean false
    * **`$True`** in case of a boolean true
    * **A number** in case of a primitive value
    * **A string** in case of a string or any other **leaf** node
    * `@(...)` for an array (**list** node)
    * `@{...}` for any dictionary, PSCustomObject or Component (aka **map** node)

    See the [PSNode Object Parser][1] for a detailed definition on node types.

.PARAMETER ExpandDepth
    Defines up till what level the collections will be expanded in the output.

    * A `-ExpandDepth 0` will create a single line expression.
    * A `-ExpandDepth -1` will compress the single line by removing command spaces.

    > [!Note]
    > White spaces (as newline characters and spaces) will not be removed from the content
    > of a (here) string.

.PARAMETER Explicit
    By default, restricted language types initializers are suppressed.
    When the `Explicit` switch is set, *all* values will be prefixed with an initializer
    (as e.g. `[Long]` and `[Array]`)

    > [!Note]
    > The `-Explicit` switch can not be used in **restricted** language mode

.PARAMETER FullTypeName
    In case a value is prefixed with an initializer, the full type name of the initializer is used.

    > [!Note]
    > The `-FullTypename` switch can not be used in **restricted** language mode and will only be
    > meaningful if the initializer is used (see also the [-Explicit] switch).

.PARAMETER HighFidelity
    If the `-HighFidelity` switch is supplied, all nested object properties will be serialized.

    By default the fidelity of an object expression will end if:

    1) the (embedded) object is a leaf node (see: [PSNode Object Parser][1])
    2) the (embedded) object expression is able to round trip.

    An object is able to roundtrip if the resulted expression of the object itself or one of
    its properties (prefixed with the type initializer) can be used to rebuild the object.

    The advantage of the default fidelity is that the resulted expression round trips (aka the
    object might be rebuild from the expression), the disadvantage is that information hold by
    less significant properties is lost (as e.g. timezone information in a `DateTime]` object).

    The advantage of the high fidelity switch is that all the information of the underlying
    properties is shown, yet any constrained or full object type will likely fail to rebuild
    due to constructor limitations such as readonly property.

    > [!Note]
    > The Object property `TypeId = [<ParentType>]` is always excluded.

.PARAMETER ExpandSingleton
    (List or map) collections nodes that contain a single item will not be expanded unless this
    `-ExpandSingleton` is supplied.

.PARAMETER IndentSize
    Specifies indent used for the nested properties.

.PARAMETER MaxDepth
    Specifies how many levels of contained objects are included in the PowerShell representation.
    The default value is define by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`).

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"
#>

[Alias('cto')]
[CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ConvertTo-Expression.md')][OutputType([String])] param(

    [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [ValidateScript({ $_ -ne 'NoLanguage' })]
    [System.Management.Automation.PSLanguageMode]$LanguageMode = 'Restricted',

    [Alias('Expand')][Int]$ExpandDepth = [Int]::MaxValue,

    [Switch]$Explicit,

    [Switch]$FullTypeName,

    [Switch]$HighFidelity,

    [Switch]$ExpandSingleton,

    [String]$Indent = '    ',

    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)

begin {
    function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
        if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
    }

    if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
    if (-not ('ConstrainedLanguage', 'FullLanguage' -eq $LanguageMode)) {
        if ($Explicit)     { StopError 'The Explicit switch requires Constrained - or FullLanguage mode.' }
        if ($FullTypeName) { StopError 'The FullTypeName switch requires Constrained - or FullLanguage mode.' }
    }

}

process {
    $Node = [PSNode]::ParseInput($InputObject, $MaxDepth)

    [PSSerialize]::new(
        $Node,
        $LanguageMode,
        $ExpandDepth,
        $Explicit,
        $FullTypeName,
        $HighFidelity,
        $ExpandSingleton,
        $Indent
    )
}
}
function Copy-ObjectGraph {
<#
.SYNOPSIS
    Copy object graph

.DESCRIPTION
    Recursively ("deep") copies a object graph.

.EXAMPLE
    # Deep copy a complete object graph into a new object graph

        $NewObjectGraph = Copy-ObjectGraph $ObjectGraph

.EXAMPLE
    # Copy (convert) an object graph using common PowerShell arrays and PSCustomObjects

        $PSObject = Copy-ObjectGraph $Object -ListAs [Array] -DictionaryAs PSCustomObject

.EXAMPLE
    # Convert a Json string to an object graph with (case insensitive) ordered dictionaries

        $PSObject = $Json | ConvertFrom-Json | Copy-ObjectGraph -DictionaryAs ([Ordered]@{})

.PARAMETER InputObject
    The input object that will be recursively copied.

.PARAMETER ListAs
    If supplied, lists will be converted to the given type (or type of the supplied object example).

.PARAMETER DictionaryAs
    If supplied, dictionaries will be converted to the given type (or type of the supplied object example).
    This parameter also accepts the [`PSCustomObject`][1] types
    By default (if the [-DictionaryAs] parameters is omitted),
    [`Component`][2] objects will be converted to a [`PSCustomObject`][1] type.

.PARAMETER ExcludeLeafs
    If supplied, only the structure (lists, dictionaries, [`PSCustomObject`][1] types and [`Component`][2] types will be copied.
    If omitted, each leaf will be shallow copied

.LINK
    [1]: https://learn.microsoft.com/dotnet/api/system.management.automation.pscustomobject "PSCustomObject Class"
    [2]: https://learn.microsoft.com/dotnet/api/system.componentmodel.component "Component Class"
#>
[Alias('Copy-Object', 'cpo')]
[OutputType([Object[]])]
[CmdletBinding(DefaultParameterSetName = 'ListAs', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Copy-ObjectGraph.md')] param(

    [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
    $InputObject,

    [ValidateNotNull()][Alias('ArrayAs')]$ListAs,

    [ValidateNotNull()][Alias('DictionaryAs')]$MapAs,

    [Switch]$ExcludeLeafs,

    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)
begin {
    function StopError($Exception, $Id = 'IncorrectArgument', $Group = [Management.Automation.ErrorCategory]::SyntaxError, $Object){
        if ($Exception -is [System.Management.Automation.ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new($Exception, $Id, $Group, $Object))
    }

    $ListNode = if ($PSBoundParameters.ContainsKey('ListAs')) { [PSNode]::ParseInput([PSInstance]::Create($ListAs)) }
    $MapNode  = if ($PSBoundParameters.ContainsKey('MapAs'))  { [PSNode]::ParseInput([PSInstance]::Create($MapAs)) }

    if (
        $ListNode -is [PSMapNode] -and $MapNode -is [PSListNode] -or
        -not $ListNode -and $MapNode -is [PSListNode] -or
        $ListNode -is [PSMapNode] -and -not $MapNode
    ) {
        $ListNode, $MapNode = $MapNode, $ListNode # In case the parameter positions are swapped
    }

    $ListType = if ($ListNode) {
        if ($ListNode -is [PSListNode]) { $ListNode.ValueType }
        else { StopError 'The -ListAs parameter requires a string, type or an object example that supports a list structure' }
    }

    $MapType = if ($MapNode) {
        if ($MapNode -is [PSMapNode]) { $MapNode.ValueType }
        else { StopError 'The -MapAs parameter requires a string, type or an object example that supports a map structure' }
    }
    if ('System.Management.Automation.PSCustomObject' -eq $MapNode.ValueType) { $MapType = 'PSCustomObject' -as [type] } # https://github.com/PowerShell/PowerShell/issues/2295

    function CopyObject(
        [PSNode]$Node,
        [Type]$ListType,
        [Type]$MapType,
        [Switch]$ExcludeLeafs
    ) {
        if ($Node -is [PSLeafNode]) {
            if ($ExcludeLeafs -or $Null -eq $Node.Value) { return $Node.Value }
            else { $Node.Value.PSObject.Copy() }
        }
        elseif ($Node -is [PSListNode]) {
            $Type = if ($Null -ne $ListType) { $ListType } else { $Node.ValueType }
            $Values = foreach ($ChildNode in $Node.ChildNodes) { CopyObject $ChildNode -ListType $ListType -MapType $MapType }
            $Values = $Values -as $Type
            ,$Values
        }
        elseif ($Node -is [PSMapNode]) {
            $Type = if ($Null -ne $MapType) { $MapType } else { $Node.ValueType }
            $IsDirectory = $Null -ne $Type.GetInterface('IDictionary')
            if ($Type.FullName -eq 'System.Collections.Hashtable') { $Dictionary = @{} } # Case insensitive
            elseif ($IsDirectory) { $Dictionary = New-Object -Type $Type }
            else { $Dictionary = [Ordered]@{} }
            foreach ($ChildNode in $Node.ChildNodes) { $Dictionary[[Object]$ChildNode.Name] = CopyObject $ChildNode -ListType $ListType -MapType $MapType }
            if ($IsDirectory) { $Dictionary } else { [PSCustomObject]$Dictionary }
        }
    }
}
process {
    $PSNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    CopyObject $PSNode -ListType $ListType -MapType $MapType -ExcludeLeafs:$ExcludeLeafs
}
}
function Export-ObjectGraph {
<#
.SYNOPSIS
    Serializes a PowerShell File or object-graph and exports it to a PowerShell (data) file.

.DESCRIPTION
    The `Export-ObjectGraph` cmdlet converts a PowerShell (complex) object to an PowerShell expression
    and exports it to a PowerShell (`.ps1`) file or a PowerShell data (`.psd1`) file.

.PARAMETER Path
    Specifies the path to a file where `Export-ObjectGraph` exports the ObjectGraph.
    Wildcard characters are permitted.

.PARAMETER LiteralPath
    Specifies a path to one or more locations where PowerShell should export the object-graph.
    The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
    If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell
    PowerShell not to interpret any characters as escape sequences.

.PARAMETER LanguageMode
    Defines which object types are allowed for the serialization, see: [About language modes][2]
    If a specific type isn't allowed in the given language mode, it will be substituted by:

    * **`$Null`** in case of a null value
    * **`$False`** in case of a boolean false
    * **`$True`** in case of a boolean true
    * **A number** in case of a primitive value
    * **A string** in case of a string or any other **leaf** node
    * `@(...)` for an array (**list** node)
    * `@{...}` for any dictionary, PSCustomObject or Component (aka **map** node)

    See the [PSNode Object Parser][1] for a detailed definition on node types.

.PARAMETER ExpandDepth
    Defines up till what level the collections will be expanded in the output.

    * A `-ExpandDepth 0` will create a single line expression.
    * A `-ExpandDepth -1` will compress the single line by removing command spaces.

    > [!Note]
    > White spaces (as newline characters and spaces) will not be removed from the content
    > of a (here) string.

.PARAMETER Explicit
    By default, restricted language types initializers are suppressed.
    When the `Explicit` switch is set, *all* values will be prefixed with an initializer
    (as e.g. `[Long]` and `[Array]`)

    > [!Note]
    > The `-Explicit` switch can not be used in **restricted** language mode

.PARAMETER FullTypeName
    In case a value is prefixed with an initializer, the full type name of the initializer is used.

    > [!Note]
    > The `-FullTypename` switch can not be used in **restricted** language mode and will only be
    > meaningful if the initializer is used (see also the [-Explicit] switch).

.PARAMETER HighFidelity
    If the `-HighFidelity` switch is supplied, all nested object properties will be serialized.

    By default the fidelity of an object expression will end if:

    1) the (embedded) object is a leaf node (see: [PSNode Object Parser][1])
    2) the (embedded) object expression is able to round trip.

    An object is able to roundtrip if the resulted expression of the object itself or one of
    its properties (prefixed with the type initializer) can be used to rebuild the object.

    The advantage of the default fidelity is that the resulted expression round trips (aka the
    object might be rebuild from the expression), the disadvantage is that information hold by
    less significant properties is lost (as e.g. timezone information in a `DateTime]` object).

    The advantage of the high fidelity switch is that all the information of the underlying
    properties is shown, yet any constrained or full object type will likely fail to rebuild
    due to constructor limitations such as readonly property.

    > [!Note]
    > Objects properties of type `[Reflection.MemberInfo]` are always excluded.

.PARAMETER ExpandSingleton
    (List or map) collections nodes that contain a single item will not be expanded unless this
    `-ExpandSingleton` is supplied.

.PARAMETER IndentSize
    Specifies indent used for the nested properties.

.PARAMETER MaxDepth
    Specifies how many levels of contained objects are included in the PowerShell representation.
    The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

.PARAMETER Encoding
    Specifies the type of encoding for the target file. The default value is `utf8NoBOM`.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"
#>

[Alias('Export-Object', 'epo')]
[CmdletBinding(DefaultParameterSetName='Path', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Export-ObjectGraph.md')]
param(
    [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $Path,

    [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath','LP')]
    [string[]]
    $LiteralPath,

    [ValidateScript({ $_ -ne 'NoLanguage' })]
    [System.Management.Automation.PSLanguageMode]$LanguageMode,

    [Alias('Expand')][Int]$ExpandDepth = [Int]::MaxValue,

    [Switch]$Explicit,

    [Switch]$FullTypeName,

    [Switch]$HighFidelity,

    [Switch]$ExpandSingleton,

    [String]$Indent = '    ',

    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth,

    [ValidateNotNullOrEmpty()]$Encoding
)

begin {
    $Extension = if ($Path) { [System.IO.Path]::GetExtension($Path) } else { [System.IO.Path]::GetExtension($LiteralPath) }
    if (-not $PSBoundParameters.ContainsKey('LanguageMode')) {
        $PSBoundParameters['LanguageMode'] = if ($Extension -eq '.psd1') { 'Restricted' } else { 'Constrained' }
    }

    $ToExpressionParameters = 'LanguageMode', 'ExpandDepth', 'Explicit', 'FullTypeName', '$HighFidelity', 'ExpandSingleton', 'Indent', 'MaxDepth'
    $ToExpressionArguments = @{}
    $ToExpressionParameters.where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $ToExpressionArguments[$_] = $PSBoundParameters[$_] }
    $ToExpressionContext = $ExecutionContext.InvokeCommand.GetCommand('ObjectGraphTools\ConvertTo-Expression', [System.Management.Automation.CommandTypes]::Cmdlet)
    $ToExpressionPipeline = { & $ToExpressionContext @ToExpressionArguments }.GetSteppablePipeline()
    $ToExpressionPipeline.Begin($True)

    $SetContentArguments = @{}
    @('Path', 'LiteralPath', 'Encoding').where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $SetContentArguments[$_] = $PSBoundParameters[$_] }
}

process {
    $Expression = $ToExpressionPipeline.Process($InputObject)
    Set-Content @SetContentArguments -Value $Expression
}

end {
    $ToExpressionPipeline.End()
}
}
function Get-ChildNode {
<#
.SYNOPSIS
    Gets the child nodes of an object-graph

.DESCRIPTION
    Gets the (unique) nodes and child nodes in one or more specified locations of an object-graph
    The returned nodes are unique even if the provide list of input parent nodes have an overlap.

.EXAMPLE
    # Select all leaf nodes in a object graph

    Given the following object graph:

        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                @{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                @{
                    Index = 2
                    Name = 'Two'
                    Comment = 'Second item'
                }
                @{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }

    The following example will receive all leaf nodes:

        $Object | Get-ChildNode -Recurse -Leaf

        Path             Name    Depth Value
        ----             ----    ----- -----
        .Data[0].Comment Comment     3 First item
        .Data[0].Name    Name        3 One
        .Data[0].Index   Index       3 1
        .Data[1].Comment Comment     3 Second item
        .Data[1].Name    Name        3 Two
        .Data[1].Index   Index       3 2
        .Data[2].Comment Comment     3 Third item
        .Data[2].Name    Name        3 Three
        .Data[2].Index   Index       3 3
        .Comment         Comment     1 Sample ObjectGraph

.EXAMPLE
    # update a property

    The following example selects all child nodes named `Comment` at a depth of `3`.
    Than filters the one that has an `Index` sibling with the value `2` and eventually
    sets the value (of the `Comment` node) to: 'Two to the Loo'.

        $Object | Get-ChildNode -AtDepth 3 -Include Comment |
            Where-Object { $_.ParentNode.GetChildNode('Index').Value -eq 2 } |
            ForEach-Object { $_.Value = 'Two to the Loo' }

        ConvertTo-Expression $Object

        @{
            Data =
                @{
                    Comment = 'First item'
                    Name = 'One'
                    Index = 1
                },
                @{
                    Comment = 'Two to the Loo'
                    Name = 'Two'
                    Index = 2
                },
                @{
                    Comment = 'Third item'
                    Name = 'Three'
                    Index = 3
                }
            Comment = 'Sample ObjectGraph'
        }

    See the [PowerShell Object Parser][1] For details on the `[PSNode]` properties and methods.

.PARAMETER InputObject
    The concerned object graph or node.

.PARAMETER Recurse
    Recursively iterates through all embedded property objects (nodes) to get the selected nodes.
    The maximum depth of of a specific node that might be retrieved is define by the `MaxDepth`
    of the (root) node. To change the maximum depth the (root) node needs to be loaded first, e.g.:

        Get-Node <InputObject> -Depth 20 | Get-ChildNode ...

    (See also: [`Get-Node`][2])

    > [!NOTE]
    > If the [AtDepth] parameter is supplied, the object graph is recursively searched anyways
    > for the selected nodes up till the deepest given `AtDepth` value.

.PARAMETER AtDepth
    When defined, only returns nodes at the given depth(s).

    > [!NOTE]
    > The nodes below the `MaxDepth` can not be retrieved.

.PARAMETER ListChild
    Returns the closest nodes derived from a **list node**.

.PARAMETER Include
    Returns only nodes derived from a **map node** including only the ones specified by one or more
    string patterns defined by this parameter. Wildcard characters are permitted.

    > [!NOTE]
    > The [-Include] and [-Exclude] parameters can be used together. However, the exclusions are applied
    > after the inclusions, which can affect the final output.

.PARAMETER Exclude
    Returns only nodes derived from a **map node** excluding the ones specified by one or more
    string patterns defined by this parameter. Wildcard characters are permitted.

    > [!NOTE]
    > The [-Include] and [-Exclude] parameters can be used together. However, the exclusions are applied
    > after the inclusions, which can affect the final output.

.PARAMETER Literal
    The values of the [-Include] - and [-Exclude] parameters are used exactly as it is typed.
    No characters are interpreted as wildcards.

.PARAMETER Leaf
    Only return leaf nodes. Leaf nodes are nodes at the end of a branch and do not have any child nodes.
    You can use the [-Recurse] parameter with the [-Leaf] parameter.

.PARAMETER IncludeSelf
    Includes the current node with the returned child nodes.

.PARAMETER ValueOnly
    returns the value of the node instead of the node itself.

.PARAMETER MaxDepth
    Specifies the maximum depth that an object graph might be recursively iterated before it throws an error.
    The failsafe will prevent infinitive loops for circular references as e.g. in:

        $Test = @{Guid = New-Guid}
        $Test.Parent = $Test

    The default `MaxDepth` is defined by `[PSNode]::DefaultMaxDepth = 10`.

    > [!Note]
    > The `MaxDepth` is bound to the root node of the object graph. Meaning that a descendant node
    > at depth of 3 can only recursively iterated (`10 - 3 =`) `7` times.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Get-Node.md "Get-Node"
#>

[Alias('gcn')]
[OutputType([PSNode[]])]
[CmdletBinding(DefaultParameterSetName='ListChild', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Get-ChildNode.md')] param(
    [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
    $InputObject,

    [switch]
    $Recurse,

    [ValidateRange(0, [int]::MaxValue)]
    [int[]]
    $AtDepth,

    [Parameter(ParameterSetName='ListChild')]
    [switch]
    $ListChild,

    [Parameter(ParameterSetName='MapChild', Position = 0)]
    [string[]]
    $Include,

    [Parameter(ParameterSetName='MapChild')]
    [string[]]
    $Exclude,

    [Parameter(ParameterSetName='MapChild')]
    [switch]
    $Literal,

    [switch]
    $Leaf,

    [Alias('Self')][switch]
    $IncludeSelf,

    [switch]
    $ValueOnly,

    [Int]
    $MaxDepth
)

begin {
    $SearchDepth = if ($PSBoundParameters.ContainsKey('AtDepth')) {
        [System.Linq.Enumerable]::Max($AtDepth) - $Node.Depth - 1
    } elseif ($Recurse) { -1 } else { 1 }
}

process {
    if ($InputObject -is [PSNode]) { $Self = $InputObject }
    else { $Self = [PSNode]::ParseInput($InputObject, $MaxDepth) }
    if ($Self -is [PSCollectionNode]) { $NodeList = $Self.GetNodeList($SearchDepth, $Leaf) }
    else {
        Write-Warning "The node '$($Self.Path)' is a leaf node which does not contain any child nodes."
        $NodeList = [System.Collections.Generic.List[Object]]::new()
    }
    if ($IncludeSelf) { $NodeList.Insert(0, $Self) }
    foreach ($Node in $NodeList) {
        if (
            (
                (-not $ListChild -and $PSCmdlet.ParameterSetName -ne 'MapChild') -or
                ($ListChild -and $Node.ParentNode -is [PSListNode]) -or
                ($PSCmdlet.ParameterSetName -eq 'MapChild' -and $Node.ParentNode -is [PSMapNode])
            ) -and
            (
                -not $PSBoundParameters.ContainsKey('AtDepth') -or $Node.Depth -in $AtDepth
            ) -and
            (
                -not $Include -or (
                    ($Literal -and $Node.Name -in $Include) -or
                    (-not $Literal -and $Include.where({ $Node.Name -like $_ }, 'first'))
                )
            ) -and -not (
                $Exclude -and (
                    ($Literal -and $Node.Name -in $Exclude) -or
                    (-not $Literal -and $Exclude.where({ $Node.Name -like $_ }, 'first'))
                )
            )
        ) {
            if ($ValueOnly) { $Node.Value } else { $Node }
        }
    }
}
}
function Get-Node {
<#
.SYNOPSIS
    Get a node

.DESCRIPTION
    The Get-Node cmdlet gets the node at the specified property location of the supplied object graph.

.EXAMPLE
    # Parse a object graph to a node instance

    The following example parses a hash table to `[PSNode]` instance:

        @{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node

        PathName Name Depth Value
        -------- ---- ----- -----
                          0 {My, Object}

.EXAMPLE
    # select a sub node in an object graph

    The following example parses a hash table to `[PSNode]` instance and selects the second (`0` indexed)
    item in the `My` map node

        @{ 'My' = 1, 2, 3; 'Object' = 'Graph' } | Get-Node My[1]

        PathName Name Depth Value
        -------- ---- ----- -----
        My[1]       1     2     2

.EXAMPLE
    # Change the price of the **PowerShell** book:

        $ObjectGraph =
            @{
                BookStore = @(
                    @{
                        Book = @{
                            Title = 'Harry Potter'
                            Price = 29.99
                        }
                    },
                    @{
                        Book = @{
                            Title = 'Learning PowerShell'
                            Price = 39.95
                        }
                    }
                )
            }

        ($ObjectGraph | Get-Node BookStore~Title=*PowerShell*..Price).Value = 24.95
        $ObjectGraph | ConvertTo-Expression
        @{
            BookStore = @(
                @{
                    Book = @{
                        Price = 29.99
                        Title = 'Harry Potter'
                    }
                },
                @{
                    Book = @{
                        Price = 24.95
                        Title = 'Learning PowerShell'
                    }
                }
            )
        }

    for more details, see: [PowerShell Object Parser][1] and [Extended dot notation][2]

.PARAMETER InputObject
    The concerned object graph or node.

.PARAMETER Path
    Specifies the path to a specific node in the object graph.
    The path might be either:

    * A dot-notation (`[String]`) literal or expression (as natively used with PowerShell)
    * A array of strings (dictionary keys or Property names) and/or integers (list indices)
    * A `[PSNodePath]` (such as `$Node.Path`) or a `[XdnPath]` (Extended Dot-Notation) object

.PARAMETER Literal
    If Literal switch is set, all (map) nodes in the given path are considered literal.

.PARAMETER ValueOnly
    returns the value of the node instead of the node itself.

.PARAMETER Unique
    Specifies that if a subset of the nodes has identical properties and values,
    only a single node of the subset should be selected.

.PARAMETER MaxDepth
    Specifies the maximum depth that an object graph might be recursively iterated before it throws an error.
    The failsafe will prevent infinitive loops for circular references as e.g. in:

        $Test = @{Guid = New-Guid}
        $Test.Parent = $Test

    The default `MaxDepth` is defined by `[PSNode]::DefaultMaxDepth = 10`.

    > [!Note]
    > The `MaxDepth` is bound to the root node of the object graph. Meaning that a descendant node
    > at depth of 3 can only recursively iterated (`10 - 3 =`) `7` times.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Xdn.md "Extended dot notation"
#>

[Alias('gn')]
[OutputType([PSNode])]
[CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Get-Node.md')] param(
    [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
    $InputObject,

    [Parameter(ParameterSetName='Path', Position=0, ValueFromPipelineByPropertyName = $true)]
    $Path,

    [Parameter(ParameterSetName='Path')]
    [Switch]
    $Literal,

    [switch]
    $ValueOnly,

    [switch]
    $Unique,

    [Int]
    $MaxDepth
)

begin {
    if ($Unique) {
        # As we want to support case sensitive and insensitive nodes the unique nodes are matched by case
        # also knowing that in most cases nodes are compared with its self.
        $UniqueNodes = [System.Collections.Generic.Dictionary[String, System.Collections.Generic.HashSet[Object]]]::new()
    }
    $XdnPaths = @($Path).ForEach{
        if ($_ -is [XdnPath]) { $_ }
        elseif ($literal) { [XdnPath]::new($_, $True) }
        else { [XdnPath]$_ }
    }
}

process {
    $Root = [PSNode]::ParseInput($InputObject, $MaxDepth)
    $Node =
        if ($XdnPaths) { $XdnPaths.ForEach{ $Root.GetNode($_) } }
        else { $Root }
    if (-not $Unique -or $(
        $PathName = $Node.Path.ToString()
        if (-not $UniqueNodes.ContainsKey($PathName)) {
            $UniqueNodes[$PathName] = [System.Collections.Generic.HashSet[Object]]::new()
        }
        $UniqueNodes[$PathName].Add($Node.Value)
    ))  {
        if ($ValueOnly) { $Node.Value } else { $Node }
    }
}
}
function Get-SortObjectGraph {
<#
.SYNOPSIS
    Sort an object graph

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
    (Alias `-CaseSensitive`) Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

.PARAMETER Descending
    Indicates that Sort-Object sorts the objects in descending order. The default is ascending order.

    > [!NOTE]
    > Primary keys (see: [-PrimaryKey]) will always put on top.

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded property (default: 10).
#>

[Alias('Sort-ObjectGraph', 'sro')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
[CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Sort-ObjectGraph.md')][OutputType([Object[]])] param(

    [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Alias('By')][String[]]$PrimaryKey,

    [Alias('CaseSensitive')]
    [Switch]$MatchCase,

    [Switch]$Descending,

    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)
begin {
    $ObjectComparison = [ObjectComparison]0
    if ($MatchCase)  { $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'MatchCase'}
    if ($Descending) { $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'Descending'}
    # As the child nodes are sorted first, we just do a side-by-side node compare:
    $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'MatchMapOrder'

    $PSListNodeComparer = [PSListNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
    $PSMapNodeComparer = [PSMapNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }

    function SortRecurse([PSCollectionNode]$Node, [PSListNodeComparer]$PSListNodeComparer, [PSMapNodeComparer]$PSMapNodeComparer) {
        $NodeList = $Node.GetNodeList()
        for ($i = 0; $i -lt $NodeList.Count; $i++) {
            if ($NodeList[$i] -is [PSCollectionNode]) {
                $NodeList[$i] = SortRecurse $NodeList[$i] -PSListNodeComparer $PSListNodeComparer -PSMapNodeComparer $PSMapNodeComparer
            }
        }
        if ($Node -is [PSListNode]) {
            $NodeList.Sort($PSListNodeComparer)
            if ($NodeList.Count) { $Node.Value = @($NodeList.Value) } else { $Node.Value =  @() }
        }
        else { # if ($Node -is [PSMapNode])
            $NodeList.Sort($PSMapNodeComparer)
            $Properties = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
            foreach($ChildNode in $NodeList) { $Properties[[Object]$ChildNode.Name] = $ChildNode.Value } # [Object] forces a key rather than an index (ArgumentOutOfRangeException)
            if ($Node -is [PSObjectNode]) { $Node.Value = [PSCustomObject]$Properties } else { $Node.Value = $Properties }
        }
        $Node
    }
}

process {
    $Node = [PSNode]::ParseInput($InputObject, $MaxDepth)
    if ($Node -is [PSCollectionNode]) {
        $Node = SortRecurse $Node -PSListNodeComparer $PSListNodeComparer -PSMapNodeComparer $PSMapNodeComparer
    }
    $Node.Value
}
}
function Import-ObjectGraph {
<#
.SYNOPSIS
    Deserializes a PowerShell File or any object-graphs from PowerShell file to an object.

.DESCRIPTION
    The `Import-ObjectGraph` cmdlet safely converts a PowerShell formatted expression contained by a file
    to an object-graph existing of a mixture of nested arrays, hash tables and objects that contain a list
    of strings and values.

.PARAMETER Path
    Specifies the path to a file where `Import-ObjectGraph` imports the object-graph.
    Wildcard characters are permitted.

.PARAMETER LiteralPath
    Specifies a path to one or more locations that contain a PowerShell the object-graph.
    The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
    If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell
    PowerShell not to interpret any characters as escape sequences.

.PARAMETER LanguageMode
    Defines which object types are allowed for the deserialization, see: [About language modes][2]

    * Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,
      `[String]`, `[Array]` or `[HashTable]`.
    * Any variable that is not `$True`, `$False` or `$Null` will be converted to a literal string, e.g. `$Test`.

    The default `LanguageMode` is `Restricted` for PowerShell Data (`psd1`) files and `Constrained` for any
    other files, which usually concerns PowerShell (`.ps1`) files.

    > [!Caution]
    >
    > In full language mode, `ConvertTo-Expression` permits all type initializers. Cmdlets, functions,
    > CIM commands, and workflows will *not* be invoked by the `ConvertFrom-Expression` cmdlet.
    >
    > Take reasonable precautions when using the `Invoke-Expression -LanguageMode Full` command in scripts.
    > Verify that the class types in the expression are safe before instantiating them. In general, it is
    > best to design your configuration expressions with restricted or constrained classes, rather than
    > allowing full freeform expressions.

.PARAMETER ListAs
    If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown or
    denied type initializer will be converted to the given list type.

.PARAMETER MapAs
    If supplied, the array subexpression `@{ }` syntaxes without an type initializer or with an unknown or
    denied type initializer will be converted to the given map (dictionary or object) type.

    The default `MapAs` is an (ordered) `PSCustomObject` for PowerShell Data (`psd1`) files and
    a (unordered) `HashTable` for any other files, which usually concerns PowerShell (`.ps1`) files that
    support explicit type initiators.

.PARAMETER Encoding
    Specifies the type of encoding for the target file. The default value is `utf8NoBOM`.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes "About language modes"
#>

[Alias('Import-Object', 'imo')]
[CmdletBinding(DefaultParameterSetName='Path', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Import-ObjectGraph.md')]
param(
    [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $Path,

    [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath','LP')]
    [string[]]
    $LiteralPath,

    [ValidateNotNull()][Alias('ArrayAs')]$ListAs,

    [ValidateNotNull()][Alias('DictionaryAs')]$MapAs,

    [ValidateScript({ $_ -ne 'NoLanguage' })]
    [System.Management.Automation.PSLanguageMode]$LanguageMode,

    [ValidateNotNullOrEmpty()]$Encoding
)

begin {
    $Extension = if ($Path) { [System.IO.Path]::GetExtension($Path) } else { [System.IO.Path]::GetExtension($LiteralPath) }
    if (-not $PSBoundParameters.ContainsKey('LanguageMode')) {
        $PSBoundParameters['LanguageMode'] = if ($Extension -eq '.psd1') { 'Restricted' } else { 'Constrained' }
    }
    if (-not $PSBoundParameters.ContainsKey('MapAs') -and $Extension -eq '.psd1') {
        $PSBoundParameters['MapAs'] = 'PSCustomObject'
    }

    $FromExpressionParameters = 'ListAs', 'MapAs', 'LanguageMode'
    $FromExpressionArguments = @{}
    $FromExpressionParameters.where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $FromExpressionArguments[$_] = $PSBoundParameters[$_] }
    $FromExpressionContext = $ExecutionContext.InvokeCommand.GetCommand('ObjectGraphTools\ConvertFrom-Expression', [System.Management.Automation.CommandTypes]::Cmdlet)
    $FromExpressionPipeline = { & $FromExpressionContext @FromExpressionArguments }.GetSteppablePipeline()
    $FromExpressionPipeline.Begin($True)

    $GetContentArguments = @{}
    @('Path', 'LiteralPath', 'Encoding').where{ $PSBoundParameters.ContainsKey($_) }.foreach{ $GetContentArguments[$_] = $PSBoundParameters[$_] }
}

process {
    $Expression = Get-Content @GetContentArguments -Raw
    $FromExpressionPipeline.Process($Expression)
}

end {
    $FromExpressionPipeline.End()
}
}
function Merge-ObjectGraph {
<#
.SYNOPSIS
    Merges two object graphs into one

.DESCRIPTION
    Recursively merges two object graphs into a new object graph.

.PARAMETER InputObject
    The input object that will be merged with the template object (see: [-Template] parameter).

    > [!NOTE]
    > Multiple input object might be provided via the pipeline.
    > The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
    > To avoid a list of (root) objects to unroll, use the **comma operator**:

        ,$InputObject | Compare-ObjectGraph $Template.

.PARAMETER Template
    The template that is used to merge with the input object (see: [-InputObject] parameter).

.PARAMETER PrimaryKey
    In case of a list of dictionaries or PowerShell objects, the PowerShell key is used to
    link the items or properties: if the PrimaryKey exists on both the [-Template] and the
    [-InputObject] and the values are equal, the dictionary or PowerShell object will be merged.
    Otherwise (if the key can't be found or the values differ), the complete dictionary or
    PowerShell object will be added to the list.

    It is allowed to supply multiple primary keys where each primary key will be used to
    check the relation between the [-Template] and the [-InputObject].

.PARAMETER MaxDepth
    The maximal depth to recursively compare each embedded node.
    The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).
#>

[Alias('Merge-Object', 'mgo')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Scope = "Function", Justification = 'False positive')]
[CmdletBinding(HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Merge-ObjectGraph.md')][OutputType([Object[]])] param(

    [Parameter(Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Parameter(Mandatory = $true, Position=0)]
    $Template,

    [String[]]$PrimaryKey,

    [Switch]$MatchCase,

    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)
begin {
    function MergeObject ([PSNode]$TemplateNode, [PSNode]$ObjectNode, [String[]]$PrimaryKey, [Switch]$MatchCase) {
        if ($ObjectNode -is [PSListNode] -and $TemplateNode -is [PSListNode]) {
            $FoundIndices = [System.Collections.Generic.HashSet[int]]::new()
            $Type = if ($ObjectNode.Value.IsFixedSize) { [Collections.Generic.List[PSObject]] } else { $ObjectNode.Value.GetType() }
            $Output = New-Object -TypeName $Type
            $ObjectItems   = $ObjectNode.ChildNodes
            $TemplateItems = $TemplateNode.ChildNodes
            foreach($ObjectItem in $ObjectItems) {
                $FoundNode = $False
                foreach ($TemplateItem in $TemplateItems) {
                    if ($ObjectItem -is [PSLeafNode] -and $TemplateItem  -is [PSLeafNode]) {
                        $Equal = if ($MatchCase) { $TemplateItem.Value -ceq $ObjectItem.Value }
                                    else            { $TemplateItem.Value -eq  $ObjectItem.Value }
                        if ($Equal) {
                            $Output.Add($ObjectItem.Value)
                            $FoundNode = $True
                            $Null = $FoundIndices.Add($TemplateItem.Name)
                        }
                    }
                    elseif ($ObjectItem -is [PSMapNode] -and $TemplateItem -is [PSMapNode]) {
                        foreach ($Key in $PrimaryKey) {
                            if (-not $TemplateItem.Contains($Key) -or -not $ObjectItem.Contains($Key)) { continue }
                            if ($TemplateItem.GetChildNode($Key).Value -eq $ObjectItem.GetChildNode($Key).Value) {
                                $Item = MergeObject -Template $TemplateItem -Object $ObjectItem -PrimaryKey $PrimaryKey -MatchCase $MatchCase
                                $Output.Add($Item)
                                $FoundNode = $True
                                $Null = $FoundIndices.Add($TemplateItem.Name)
                            }
                        }
                    }
                }
                if (-not $FoundNode) { $Output.Add($ObjectItem.Value) }
            }
            foreach ($TemplateItem in $TemplateItems) {
                if (-not $FoundIndices.Contains($TemplateItem.Name)) { $Output.Add($TemplateItem.Value) }
            }
            if ($ObjectNode.Value.IsFixedSize) { $Output = @($Output) }
            ,$Output
        }
        elseif ($ObjectNode -is [PSMapNode] -and $TemplateNode -is [PSMapNode]) {
            if ($ObjectNode -is [PSDictionaryNode]) { $Dictionary = New-Object -TypeName $ObjectNode.ValueType }     # The $InputObject defines the map type
            else { $Dictionary = [System.Collections.Specialized.OrderedDictionary]::new() }
            foreach ($ObjectItem in $ObjectNode.ChildNodes) {
                if ($TemplateNode.Contains($ObjectItem.Name)) {                                                  # The $InputObject defines the comparer
                    $Value = MergeObject -Template $TemplateNode.GetChildNode($ObjectItem.Name) -Object $ObjectItem -PrimaryKey $PrimaryKey -MatchCase $MatchCase
                }
                else { $Value = $ObjectItem.Value }
                $Dictionary.Add($ObjectItem.Name, $Value)
            }
            foreach ($Key in $TemplateNode.Names) {
                if (-not $Dictionary.Contains($Key)) { $Dictionary.Add($Key, $TemplateNode.GetChildNode($Key).Value) }
            }
            if ($ObjectNode -is [PSDictionaryNode]) { $Dictionary } else { [PSCustomObject]$Dictionary }
        }
        else { return $ObjectNode.Value }
    }
    $TemplateNode = [PSNode]::ParseInput($Template, $MaxDepth)
}
process {
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    MergeObject $TemplateNode $ObjectNode -PrimaryKey $PrimaryKey -MatchCase $MatchCase
}
}
function Test-ObjectGraph {
<#
.SYNOPSIS
Tests the properties of an object-graph.

.DESCRIPTION
Tests an object-graph against a schema object by verifying that the properties of the object-graph
meet the constrains defined in the schema object.

The schema object has the following major features:

* Independent of the object notation (as e.g. [Json (JavaScript Object Notation)][2] or [PowerShell Data Files][3])
* Each test node is at the same level as the input node being validated
* Complex node requirements (as mutual exclusive nodes) might be selected using a logical formula

.EXAMPLE
#Test whether a `$Person` object meats the schema requirements.

    $Person = [PSCustomObject]@{
        FirstName = 'John'
        LastName  = 'Smith'
        IsAlive   = $True
        Birthday  = [DateTime]'Monday,  October 7,  1963 10:47:00 PM'
        Age       = 27
        Address   = [PSCustomObject]@{
            Street     = '21 2nd Street'
            City       = 'New York'
            State      = 'NY'
            PostalCode = '10021-3100'
        }
        Phone = @{
            Home   = '212 555-1234'
            Mobile = '212 555-2345'
            Work   = '212 555-3456', '212 555-3456', '646 555-4567'
        }
        Children = @('Dennis', 'Stefan')
        Spouse = $Null
    }

    $Schema = @{
        FirstName = @{ '@Type' = 'String' }
        LastName  = @{ '@Type' = 'String' }
        IsAlive   = @{ '@Type' = 'Bool' }
        Birthday  = @{ '@Type' = 'DateTime' }
        Age       = @{
            '@Type' = 'Int'
            '@Minimum' = 0
            '@Maximum' = 99
        }
        Address = @{
            '@Type' = 'PSMapNode'
            Street     = @{ '@Type' = 'String' }
            City       = @{ '@Type' = 'String' }
            State      = @{ '@Type' = 'String' }
            PostalCode = @{ '@Type' = 'String' }
        }
        Phone = @{
            '@Type' = 'PSMapNode',  $Null
            Home    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
            Mobile  = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
            Work    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
        }
        Children  = @(@{ '@Type' = 'String', $Null })
        Spouse    = @{ '@Type' = 'String', $Null }
    }

    $Person | Test-Object $Schema | Should -BeNullOrEmpty

.PARAMETER InputObject
Specifies the object to test for validity against the schema object.
The object might be any object containing embedded (or even recursive) lists, dictionaries, objects or scalar
values received from a application or an object notation as Json or YAML using their related `ConvertFrom-*`
cmdlets.

.PARAMETER SchemaObject
Specifies a schema to validate the JSON input against. By default, if any discrepancies, toy will be reported
in a object list containing the path to failed node, the value whether the node is valid or not and the issue.
If no issues are found, the output is empty.

For details on the schema object, see the [schema object definitions][1] documentation.

.PARAMETER ValidateOnly

If set, the cmdlet will stop at the first invalid node and return the test result object.

.PARAMETER Elaborate

If set, the cmdlet will return the test result object for all tested nodes, even if they are valid
or ruled out in a possible list node branch selection.

.PARAMETER AssertTestPrefix

The prefix used to identify the assert test nodes in the schema object. By default, the prefix is `AssertTestPrefix`.

.PARAMETER MaxDepth

The maximal depth to recursively test each embedded node.
The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/SchemaObject.md "Schema object definitions"

#>

[Alias('Test-Object', 'tso')]
[CmdletBinding(DefaultParameterSetName = 'ResultList', HelpUri='https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-ObjectGraph.md')][OutputType([String])] param(

    [Parameter(ParameterSetName='ValidateOnly', Mandatory = $true, ValueFromPipeLine = $True)]
    [Parameter(ParameterSetName='ResultList', Mandatory = $true, ValueFromPipeLine = $True)]
    $InputObject,

    [Parameter(ParameterSetName='ValidateOnly', Mandatory = $true, Position = 0)]
    [Parameter(ParameterSetName='ResultList', Mandatory = $true, Position = 0)]
    $SchemaObject,

    [Parameter(ParameterSetName='ValidateOnly')]
    [Switch]$ValidateOnly,

    [Parameter(ParameterSetName='ResultList')]
    [Switch]$Elaborate,

    [Parameter(ParameterSetName='ValidateOnly')]
    [Parameter(ParameterSetName='ResultList')]
    [ValidateNotNullOrEmpty()][String]$AssertTestPrefix = 'AssertTestPrefix',

    [Parameter(ParameterSetName='ValidateOnly')]
    [Parameter(ParameterSetName='ResultList')]
    [Alias('Depth')][int]$MaxDepth = [PSNode]::DefaultMaxDepth
)

begin {

    $Script:Yield = {
        $Name = "$Args" -Replace '\W'
        $Value = Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue
        if ($Value) { "$args" }
    }

    $Script:Ordinal = @{$false = [StringComparer]::OrdinalIgnoreCase; $true = [StringComparer]::Ordinal }

    # The maximum schema object depth is bound by the input object depth (+1 one for the leaf test definition)
    $SchemaNode = [PSNode]::ParseInput($SchemaObject, ($MaxDepth + 2)) # +2 to be safe
    $Script:AssertPrefix = if ($SchemaNode.Contains($AssertTestPrefix)) { $SchemaNode.Value[$AssertTestPrefix] } else { '@' }

    function StopError($Exception, $Id = 'TestNode', $Category = [ErrorCategory]::SyntaxError, $Object) {
        if ($Exception -is [ErrorRecord]) { $Exception = $Exception.Exception }
        elseif ($Exception -isnot [Exception]) { $Exception = [ArgumentException]$Exception }
        $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new($Exception, $Id, $Category, $Object))
    }

    function SchemaError($Message, $ObjectNode, $SchemaNode, $Object = $SchemaObject) {
        $Exception = [ArgumentException]"$([String]$SchemaNode) $Message"
        $Exception.Data.Add('ObjectNode', $ObjectNode)
        $Exception.Data.Add('SchemaNode', $SchemaNode)
        StopError -Exception $Exception -Id 'SchemaError' -Category InvalidOperation -Object $Object
    }

    $Script:Tests = @{
        Description      = 'Describes the test node'
        References       = 'Contains a list of assert references'
        Type             = 'The node or value is of type'
        NotType          = 'The node or value is not type'
        CaseSensitive    = 'The (descendant) node are considered case sensitive'
        Required         = 'The node is required'
        Unique           = 'The node is unique'

        Minimum          = 'The value is greater than or equal to'
        ExclusiveMinimum = 'The value is greater than'
        ExclusiveMaximum = 'The value is less than'
        Maximum          = 'The value is less than or equal to'

        MinimumLength    = 'The value length is greater than or equal to'
        Length           = 'The value length is equal to'
        MaximumLength    = 'The value length is less than or equal to'

        MinimumCount     = 'The node count is greater than or equal to'
        Count            = 'The node count is equal to'
        MaximumCount     = 'The node count is less than or equal to'

        Like             = 'The value is like'
        Match            = 'The value matches'
        NotLike          = 'The value is not like'
        NotMatch         = 'The value not matches'

        Ordered          = 'The nodes are in order'
        RequiredNodes    = 'The node contains the nodes'
        AllowExtraNodes  = 'Allow extra nodes'
    }

    $At = @{}
    $Tests.Get_Keys().Foreach{ $At[$_] = "$($AssertPrefix)$_" }

    function ResolveReferences($Node) {
        if ($Node.Cache.ContainsKey('TestReferences')) { return }

    }

    function GetReference($LeafNode) {
        $TestNode = $LeafNode.ParentNode
        $References = if ($TestNode) {
            if (-not $TestNode.Cache.ContainsKey('TestReferences')) {
                $Stack = [Stack]::new()
                while ($true) {
                    $ParentNode = $TestNode.ParentNode
                    if ($ParentNode -and -not $ParentNode.Cache.ContainsKey('TestReferences')) {
                        $Stack.Push($TestNode)
                        $TestNode = $ParentNode
                        continue
                    }
                    $RefNode = if ($TestNode.Contains($At.References)) { $TestNode.GetChildNode($At.References) }
                    $TestNode.Cache['TestReferences'] = [HashTable]::new($Ordinal[[Bool]$RefNode.CaseMatters])
                    if ($RefNode) {
                        foreach ($ChildNode in $RefNode.ChildNodes) {
                            if (-not $TestNode.Cache['TestReferences'].ContainsKey($ChildNode.Name)) {
                                $TestNode.Cache['TestReferences'][$ChildNode.Name] = $ChildNode
                            }
                        }
                    }
                    $ParentNode = $TestNode.ParentNode
                    if ($ParentNode) {
                        foreach ($RefName in $ParentNode.Cache['TestReferences'].get_Keys()) {
                            if (-not $TestNode.Cache['TestReferences'].ContainsKey($RefName)) {
                                $TestNode.Cache['TestReferences'][$RefName] = $ParentNode.Cache['TestReferences'][$RefName]
                            }
                        }
                    }
                    if ($Stack.Count -eq 0) { break }
                    $TestNode = $Stack.Pop()
                }
            }
            $TestNode.Cache['TestReferences']
        } else { @{} }
        if ($References.Contains($LeafNode.Value)) {
            $AssertNode.Cache['TestReferences'] = $References
            $References[$LeafNode.Value]
        }
        else { SchemaError "Unknown reference: $LeafNode" $ObjectNode $LeafNode }
    }

    function MatchNode (
        [PSNode]$ObjectNode,
        [PSNode]$TestNode,
        [Switch]$ValidateOnly,
        [Switch]$Elaborate,
        [Switch]$Ordered,
        [Nullable[Bool]]$CaseSensitive,
        [Switch]$MatchAll,
        $MatchedNames
    ) {
        $Violates = $null
        $Name = $TestNode.Name

        $ChildNodes = $ObjectNode.ChildNodes
        if ($ChildNodes.Count -eq 0) { return }

        $AssertNode = if ($TestNode -is [PSCollectionNode]) { $TestNode } else { GetReference $TestNode }

        if ($ObjectNode -is [PSMapNode] -and $TestNode.NodeOrigin -eq 'Map') {
            if ($ObjectNode.Contains($Name)) {
                $ChildNode = $ObjectNode.GetChildNode($Name)
                if ($Ordered -and $ChildNodes.IndexOf($ChildNode) -ne $TestNodes.IndexOf($TestNode)) {
                    $Violates = "The node $Name is not in order"
                }
            } else { $ChildNode = $false }
        }
        elseif ($ChildNodes.Count -eq 1) { $ChildNode = $ChildNodes[0] }
        elseif ($Ordered) {
            $NodeIndex = $TestNodes.IndexOf($TestNode)
            if ($NodeIndex -ge $ChildNodes.Count) {
                $Violates = "Expected at least $($TestNodes.Count) (ordered) nodes"
            }
            $ChildNode = $ChildNodes[$NodeIndex]
        }
        else { $ChildNode = $null }

        if ($Violates) {
            if (-not $ValidateOnly) {
                $Output = [PSCustomObject]@{
                    ObjectNode = $ObjectNode
                    SchemaNode = $AssertNode
                    Valid      = -not $Violates
                    Issue      = $Violates
                }
                $Output.PSTypeNames.Insert(0, 'TestResult')
                $Output
            }
            return
        }
        if ($ChildNode -is [PSNode]) {
            $Issue = $Null
            $TestParams = @{
                ObjectNode     = $ChildNode
                SchemaNode     = $AssertNode
                Elaborate      = $Elaborate
                CaseSensitive  = $CaseSensitive
                ValidateOnly   = $ValidateOnly
                RefInvalidNode = [Ref]$Issue
            }
            TestNode @TestParams
            if (-not $Issue) { $null = $MatchedNames.Add($ChildNode.Name) }
        }
        elseif ($null -eq $ChildNode) {
            $SingleIssue = $Null
            foreach ($ChildNode in $ChildNodes) {
                if ($MatchedNames.Contains($ChildNode.Name)) { continue }
                $Issue = $Null
                $TestParams = @{
                    ObjectNode     = $ChildNode
                    SchemaNode     = $AssertNode
                    Elaborate      = $Elaborate
                    CaseSensitive  = $CaseSensitive
                    ValidateOnly   = $true
                    RefInvalidNode = [Ref]$Issue
                }
                TestNode @TestParams
                if($Issue) {
                    if ($Elaborate) { $Issue }
                    elseif (-not $ValidateOnly -and $MatchAll) {
                        if ($null -eq $SingleIssue) { $SingleIssue = $Issue } else { $SingleIssue = $false }
                    }
                }
                else {
                    $null = $MatchedNames.Add($ChildNode.Name)
                    if (-not $MatchAll) { break }
                }
            }
            if ($SingleIssue) { $SingleIssue }
        }
        elseif ($ChildNode -eq $false) { $AssertResults[$Name] = $false }
        else { throw "Unexpected return reference: $ChildNode" }
    }

    function TestNode (
        [PSNode]$ObjectNode,
        [PSNode]$SchemaNode,
        [Switch]$Elaborate,             # if set, include the failed test results in the output
        [Nullable[Bool]]$CaseSensitive, # inherited the CaseSensitivity frm the parent node if not defined
        [Switch]$ValidateOnly,          # if set, stop at the first invalid node
        $RefInvalidNode                 # references the first invalid node
    ) {
        $CallStack = Get-PSCallStack
        # if ($CallStack.Count -gt 20) { Throw 'Call stack failsafe' }
        if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
            $Caller = $CallStack[1]
            Write-Host "$([ParameterColor]'Caller (line: $($Caller.ScriptLineNumber))'):" $Caller.InvocationInfo.Line.Trim()
            Write-Host "$([ParameterColor]'ObjectNode:')" $ObjectNode.Path "$ObjectNode"
            Write-Host "$([ParameterColor]'SchemaNode:')" $SchemaNode.Path "$SchemaNode"
            Write-Host "$([ParameterColor]'ValidateOnly:')" ([Bool]$ValidateOnly)
        }
        if ($SchemaNode -is [PSListNode] -and $SchemaNode.Count -eq 0) { return } # Allow any node

        $AssertValue = $ObjectNode.Value
        $RefInvalidNode.Value = $null

        # Separate the assert nodes from the schema subnodes
        $AssertNodes = [Ordered]@{} # $AssertNodes{<Assert Test name>] = $ChildNodes.@<Assert Test name>
        if ($SchemaNode -is [PSMapNode]) {
            $TestNodes = [List[PSNode]]::new()
            foreach ($Node in $SchemaNode.ChildNodes) {
                if ($Null -eq $Node.Parent -and $Node.Name -eq $AssertTestPrefix) { continue }
                if ($Node.Name.StartsWith($AssertPrefix)) {
                    $TestName = $Node.Name.SubString($AssertPrefix.Length)
                    if ($TestName -notin $Tests.Keys) { SchemaError "Unknown assert: '$($Node.Name)'" $ObjectNode $SchemaNode }
                    $AssertNodes[$TestName] = $Node
                }
                else { $TestNodes.Add($Node) }
            }
        }
        elseif ($SchemaNode -is [PSListNode]) { $TestNodes = $SchemaNode.ChildNodes }
        else { $TestNodes = @() }

        if ($AssertNodes.Contains('CaseSensitive')) { $CaseSensitive = [Nullable[Bool]]$AssertNodes['CaseSensitive'] }
        $AllowExtraNodes = if ($AssertNodes.Contains('AllowExtraNodes')) { $AssertNodes['AllowExtraNodes'] }

#Region Node validation

        $RefInvalidNode.Value = $false
        $MatchedNames = [HashSet[Object]]::new()
        $AssertResults = $Null
        foreach ($TestName in $AssertNodes.get_Keys()) {
            $AssertNode = $AssertNodes[$TestName]
            $Criteria = $AssertNode.Value
            $Violates = $null # is either a boolean ($true if invalid) or a string with what was expected
            if ($TestName -eq 'Description') { $Null }
            elseif ($TestName -eq 'References') { }
            elseif ($TestName -in 'Type', 'notType') {
                $FoundType = foreach ($TypeName in $Criteria) {
                    if ($TypeName -in $null, 'Null', 'Void') {
                        if ($null -eq $AssertValue) { $true; break }
                    }
                    elseif ($TypeName -is [Type]) { $Type = $TypeName } else {
                        $Type = $TypeName -as [Type]
                        if (-not $Type) {
                            SchemaError "Unknown type: $TypeName" $ObjectNode $SchemaNode
                        }
                    }
                    if ($ObjectNode -is $Type -or $AssertValue -is $Type) { $true; break }
                }
                $Not = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                if ($null -eq $FoundType -xor $Not) { $Violates = "The node or value is $(if (!$Not) { 'not ' })of type $AssertNode" }
            }
            elseif ($TestName -eq 'CaseSensitive') {
                if ($null -ne $Criteria -and $Criteria -isnot [Bool]) {
                    SchemaError "The case sensitivity value should be a boolean: $Criteria" $ObjectNode $SchemaNode
                }
            }
            elseif ($TestName -in 'Minimum', 'ExclusiveMinimum', 'ExclusiveMaximum', 'Maximum') {
                if ($null -eq $AllowExtraNodes) { $AllowExtraNodes = $true }
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $Violates = "The value '$Value' is not a string or value type"
                    }
                    elseif ($TestName -eq 'Minimum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -cle $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -ile $Value }
                            else                               { $Criteria -le  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is less or equal than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMinimum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -clt $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -ilt $Value }
                            else                               { $Criteria -lt  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is less than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'ExclusiveMaximum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -cgt $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -igt $Value }
                            else                               { $Criteria -gt  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is greater than $AssertNode"
                        }
                    }
                    else { # if ($TestName -eq 'Maximum') {
                        $IsValid =
                            if     ($CaseSensitive -eq $true)  { $Criteria -cge $Value }
                            elseif ($CaseSensitive -eq $false) { $Criteria -ige $Value }
                            else                               { $Criteria -ge  $Value }
                        if (-not $IsValid) {
                            $Violates = "The $(&$Yield '(case sensitive) ')value $Value is greater than $AssertNode"
                        }
                    }
                    if ($Violates) { break }
                }
            }

            elseif ($TestName -in 'MinimumLength', 'Length', 'MaximumLength') {
                if ($null -eq $AllowExtraNodes) { $AllowExtraNodes = $true }
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $Violates = "The value '$Value' is not a string or value type"
                        break
                    }
                    $Length = "$Value".Length
                    if ($TestName -eq 'MinimumLength') {
                        if ($Length -lt $Criteria) {
                            $Violates = "The string length of '$Value' ($Length) is less than $AssertNode"
                        }
                    }
                    elseif ($TestName -eq 'Length') {
                        if ($Length -ne $Criteria) {
                            $Violates = "The string length of '$Value' ($Length) is not equal to $AssertNode"
                        }
                    }
                    else { # if ($TestName -eq 'MaximumLength') {
                        if ($Length -gt $Criteria) {
                            $Violates = "The string length of '$Value' ($Length) is greater than $AssertNode"
                        }
                    }
                    if ($Violates) { break }
                }
            }

            elseif ($TestName -in 'Like', 'NotLike', 'Match', 'NotMatch') {
                if ($null -eq $AllowExtraNodes) { $AllowExtraNodes = $true }
                $Negate = $TestName.StartsWith('Not', 'OrdinalIgnoreCase')
                $Match  = $TestName.EndsWith('Match', 'OrdinalIgnoreCase')
                $ValueNodes = if ($ObjectNode -is [PSCollectionNode]) { $ObjectNode.ChildNodes } else { @($ObjectNode) }
                foreach ($ValueNode in $ValueNodes) {
                    $Value = $ValueNode.Value
                    if ($Value -isnot [String] -and $Value -isnot [ValueType]) {
                        $Violates = "The value '$Value' is not a string or value type"
                        break
                    }
                    $Found = $false
                    foreach ($AnyCriteria in $Criteria) {
                        $Found = if ($Match) {
                            if     ($true -eq $CaseSensitive)  { $Value -cMatch $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $Value -iMatch $AnyCriteria }
                            else                               { $Value -Match  $AnyCriteria }
                        }
                        else { # if ($TestName.EndsWith('Link', 'OrdinalIgnoreCase')) {
                            if     ($true -eq $CaseSensitive)  { $Value -cLike  $AnyCriteria }
                            elseif ($false -eq $CaseSensitive) { $Value -iLike  $AnyCriteria }
                            else                               { $Value -Like   $AnyCriteria }
                        }
                        if ($Found) { break }
                    }
                    $IsValid = $Found -xor $Negate
                    if (-not $IsValid) {
                        $Not = if (-Not $Negate) { ' not' }
                        $Violates =
                            if ($Match) { "The $(&$Yield '(case sensitive) ')value $Value does$not match $AssertNode" }
                            else        { "The $(&$Yield '(case sensitive) ')value $Value is$not like $AssertNode" }
                    }
                }
            }

            elseif ($TestName -in 'MinimumCount', 'Count', 'MaximumCount') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = "The node $ObjectNode is not a collection node"
                }
                elseif ($TestName -eq 'MinimumCount') {
                    if ($ChildNodes.Count -lt $Criteria) {
                        $Violates = "The node count ($($ChildNodes.Count)) is less than $AssertNode"
                    }
                }
                elseif ($TestName -eq 'Count') {
                    if ($ChildNodes.Count -ne $Criteria) {
                        $Violates = "The node count ($($ChildNodes.Count)) is not equal to $AssertNode"
                    }
                }
                else { # if ($TestName -eq 'MaximumCount') {
                    if ($ChildNodes.Count -gt $Criteria) {
                        $Violates = "The node count ($($ChildNodes.Count)) is greater than $AssertNode"
                    }
                }
            }

            elseif ($TestName -eq 'Required') { }
            elseif ($TestName -eq 'Unique' -and $Criteria) {
                if (-not $ObjectNode.ParentNode) {
                    SchemaError "The unique assert can't be used on a root node" $ObjectNode $SchemaNode
                }
                if ($Criteria -eq $true) { $UniqueCollection = $ObjectNode.ParentNode.ChildNodes }
                elseif ($Criteria -is [String]) {
                    if (-not $UniqueCollections.Contains($Criteria)) {
                        $UniqueCollections[$Criteria] = [List[PSNode]]::new()
                    }
                    $UniqueCollection = $UniqueCollections[$Criteria]
                }
                else { SchemaError "The unique assert value should be a boolean or a string" $ObjectNode $SchemaNode }
                $ObjectComparer = [ObjectComparer]::new([ObjectComparison][Int][Bool]$CaseSensitive)
                foreach ($UniqueNode in $UniqueCollection) {
                    if ([object]::ReferenceEquals($ObjectNode, $UniqueNode)) { continue } # Self
                    if ($ObjectComparer.IsEqual($ObjectNode, $UniqueNode)) {
                        $Violates = "The node is equal to the node: $($UniqueNode.Path)"
                        break
                    }
                }
                if ($Criteria -is [String]) { $UniqueCollection.Add($ObjectNode) }
            }
            elseif ($TestName -eq 'AllowExtraNodes') {}
            elseif ($TestName -in 'Ordered', 'RequiredNodes') {
                if ($ObjectNode -isnot [PSCollectionNode]) {
                    $Violates = "The '$($AssertNode.Name)' is not a collection node"
                }
            }
            else { SchemaError "Unknown assert node: $TestName" $ObjectNode $SchemaNode }

            if ($DebugPreference -in 'Stop', 'Continue', 'Inquire') {
                if (-not $Violates) { Write-Host -ForegroundColor Green "Valid: $TestName $Criteria" }
                else { Write-Host -ForegroundColor Red "Invalid: $TestName $Criteria" }
            }

            if ($Violates -or $Elaborate) {
                $Issue =
                    if ($Violates -is [String]) { $Violates }
                    elseif ($Criteria -eq $true) { $($Tests[$TestName]) }
                    else { "$($Tests[$TestName] -replace 'The value ', "The value $ObjectNode ") $AssertNode" }
                $Output = [PSCustomObject]@{
                    ObjectNode = $ObjectNode
                    SchemaNode = $SchemaNode
                    Valid      = -not $Violates
                    Issue      = $Issue
                }
                $Output.PSTypeNames.Insert(0, 'TestResult')
                if ($Violates) {
                    $RefInvalidNode.Value = $Output
                    if ($ValidateOnly) { return }
                }
                if (-not $ValidateOnly -or $Elaborate) { <# Write-Output #> $Output }
            }
        }

#EndRegion Node validation

        if ($Violates) { return }

#Region Required nodes

        $ChildNodes = $ObjectNode.ChildNodes

        if ($TestNodes.Count -and -not $AssertNodes.Contains('Type')) {
            if ($SchemaNode -is [PSListNode] -and $ObjectNode -isnot [PSListNode]) {
                $Violates = "The node $ObjectNode is not a list node"
            }
            if ($SchemaNode -is [PSMapNode] -and $ObjectNode -isnot [PSMapNode]) {
                $Violates = "The node $ObjectNode is not a map node"
            }
        }

        if (-Not $Violates) {
            $RequiredNodes = $AssertNodes['RequiredNodes']
            $CaseSensitiveNames = if ($ObjectNode -is [PSMapNode]) { $ObjectNode.CaseMatters }
            $AssertResults = [HashTable]::new($Ordinal[[Bool]$CaseSensitiveNames])

            if ($RequiredNodes) { $RequiredList = [List[Object]]$RequiredNodes.Value } else { $RequiredList = [List[Object]]::new() }
            foreach ($TestNode in $TestNodes) {
                $AssertNode = if ($TestNode -is [PSCollectionNode]) { $TestNode } else { GetReference $TestNode }
                if ($AssertNode -is [PSMapNode] -and $AssertNode.GetValue($At.Required)) { $RequiredList.Add($TestNode.Name) }
            }

            foreach ($Requirement in $RequiredList) {
                $LogicalFormula = [LogicalFormula]$Requirement
                $Enumerator = $LogicalFormula.Terms.GetEnumerator()
                $Stack = [Stack]::new()
                $Stack.Push(@{
                    Enumerator  = $Enumerator
                    Accumulator = $null
                    Operator    = $null
                    Negate      = $null
                })
                $Term, $Operand, $Accumulator = $null
                While ($Stack.Count -gt 0) {
                    # Accumulator = Accumulator <operation> Operand
                    # if ($Stack.Count -gt 20) { Throw 'Formula stack failsafe'}
                    $Pop         = $Stack.Pop()
                    $Enumerator  = $Pop.Enumerator
                    $Operator    = $Pop.Operator
                    if ($null -eq $Operator) { $Operand = $Pop.Accumulator }
                    else { $Operand, $Accumulator = $Accumulator, $Pop.Accumulator }
                    $Negate      = $Pop.Negate
                    $Compute = $null -notin $Operand, $Operator, $Accumulator
                    while ($Compute -or $Enumerator.MoveNext()) {
                        if ($Compute) { $Compute = $false}
                        else {
                            $Term = $Enumerator.Current
                            if ($Term -is [LogicalVariable]) {
                                $Name = $Term.Value
                                if (-not $AssertResults.ContainsKey($Name)) {
                                    if (-not $SchemaNode.Contains($Name)) {
                                        SchemaError "Unknown test node: $Term" $ObjectNode $SchemaNode
                                    }
                                    $MatchCount0 = $MatchedNames.Count
                                    $MatchParams = @{
                                        ObjectNode    = $ObjectNode
                                        TestNode      = $SchemaNode.GetChildNode($Name)
                                        Elaborate     = $Elaborate
                                        ValidateOnly  = $ValidateOnly
                                        Ordered       = $AssertNodes['Ordered']
                                        CaseSensitive = $CaseSensitive
                                        MatchAll      = $false
                                        MatchedNames  = $MatchedNames
                                    }
                                    MatchNode @MatchParams
                                    $AssertResults[$Name] = $MatchedNames.Count -gt $MatchCount0
                                }
                                $Operand = $AssertResults[$Name]
                            }
                            elseif ($Term -is [LogicalOperator]) {
                                if ($Term.Value -eq 'Not') { $Negate = -Not $Negate }
                                elseif ($null -eq $Operator -and $null -ne $Accumulator) { $Operator = $Term.Value }
                                else { SchemaError "Unexpected operator: $Term" $ObjectNode $SchemaNode }
                            }
                            elseif ($Term -is [LogicalFormula]) {
                                $Stack.Push(@{
                                    Enumerator  = $Enumerator
                                    Accumulator = $Accumulator
                                    Operator    = $Operator
                                    Negate      = $Negate
                                })
                                $Accumulator, $Operator, $Negate = $null
                                $Enumerator  = $Term.Terms.GetEnumerator()
                                continue
                            }
                            else { SchemaError "Unknown logical operator term: $Term" $ObjectNode $SchemaNode }
                        }
                        if ($null -ne $Operand) {
                            if ($null -eq $Accumulator -xor $null -eq $Operator) {
                                if ($Accumulator) { SchemaError "Missing operator before: $Term" $ObjectNode $SchemaNode }
                                else { SchemaError "Missing variable before: $Operator $Term" $ObjectNode $SchemaNode }
                            }
                            $Operand = $Operand -Xor $Negate
                            $Negate = $null
                            if ($Operator -eq 'And') {
                                $Operator = $null
                                if ($Accumulator -eq $false -and -not $AllowExtraNodes) { break }
                                $Accumulator = $Accumulator -and $Operand
                            }
                            elseif ($Operator -eq 'Or') {
                                $Operator = $null
                                if ($Accumulator -eq $true -and -not $AllowExtraNodes) { break }
                                $Accumulator = $Accumulator -Or $Operand
                            }
                            elseif ($Operator -eq 'Xor') {
                                $Operator = $null
                                $Accumulator = $Accumulator -xor $Operand
                            }
                            else { $Accumulator = $Operand }
                            $Operand = $Null
                        }
                    }
                    if ($null -ne $Operator -or $null -ne $Negate) {
                        SchemaError "Missing variable after $Operator" $ObjectNode $SchemaNode
                    }
                }
                if ($Accumulator -eq $False) {
                    $Violates = "The required node condition $LogicalFormula is not met"
                    break
                }
            }
        }

#EndRegion Required nodes

#Region Optional nodes

        if (-not $Violates) {

            foreach ($TestNode in $TestNodes) {
                if ($MatchedNames.Count -ge $ChildNodes.Count) { break }
                if ($AssertResults.Contains($TestNode.Name)) { continue }
                $MatchCount0 = $MatchedNames.Count
                $MatchParams = @{
                    ObjectNode    = $ObjectNode
                    TestNode      = $TestNode
                    Elaborate     = $Elaborate
                    ValidateOnly  = $ValidateOnly
                    Ordered       = $AssertNodes['Ordered']
                    CaseSensitive = $CaseSensitive
                    MatchAll      = -not $AllowExtraNodes
                    MatchedNames  = $MatchedNames
                }
                MatchNode @MatchParams
                if ($AllowExtraNodes -and $MatchedNames.Count -eq $MatchCount0) {
                    $Violates = "When extra nodes are allowed, the node $ObjectNode should be accepted"
                    break
                }
                $AssertResults[$TestNode.Name] = $MatchedNames.Count -gt $MatchCount0
            }

            if (-not $AllowExtraNodes -and $MatchedNames.Count -lt $ChildNodes.Count) {
                $Count = 0; $LastName = $Null
                $Names = foreach ($Name in $ChildNodes.Name) {
                    if ($MatchedNames.Contains($Name)) { continue }
                    if ($Count++ -lt 4) {
                        if ($ObjectNode -is [PSListNode]) { [CommandColor]$Name }
                            else { [StringColor][PSKeyExpression]::new($Name, [PSSerialize]::MaxKeyLength)}
                    }
                    else { $LastName = $Name }
                }
                $Violates = "The following nodes are not accepted: $($Names -join ', ')"
                if ($LastName) {
                    $LastName = if ($ObjectNode -is [PSListNode]) { [CommandColor]$LastName }
                        else { [StringColor][PSKeyExpression]::new($LastName, [PSSerialize]::MaxKeyLength) }
                    $Violates += " .. $LastName"
                }
            }
        }

#EndRegion Optional nodes

        if ($Violates -or $Elaborate) {
            $Output = [PSCustomObject]@{
                ObjectNode = $ObjectNode
                SchemaNode = $SchemaNode
                Valid      = -not $Violates
                Issue      = if ($Violates) { $Violates } else { 'All the child nodes are valid'}
            }
            $Output.PSTypeNames.Insert(0, 'TestResult')
            if ($Violates) { $RefInvalidNode.Value = $Output }
            if (-not $ValidateOnly -or $Elaborate) { <# Write-Output #> $Output }
        }
    }
}

process {
    $ObjectNode = [PSNode]::ParseInput($InputObject, $MaxDepth)
    $Script:UniqueCollections = @{}
    $Invalid = $Null
    $TestParams = @{
        ObjectNode     = $ObjectNode
        SchemaNode     = $SchemaNode
        Elaborate     = $Elaborate
        ValidateOnly   = $ValidateOnly
        RefInvalidNode = [Ref]$Invalid
    }
    TestNode @TestParams
    if ($ValidateOnly) { -not $Invalid }
}
}

#EndRegion Cmdlet

#Region Alias

Set-Alias -Name 'ConvertFrom-Expression' -Value 'cfe'
Set-Alias -Name 'Copy-ObjectGraph' -Value 'Copy-Object'
Set-Alias -Name 'Copy-ObjectGraph' -Value 'cpo'
Set-Alias -Name 'ConvertTo-Expression' -Value 'cto'
Set-Alias -Name 'Export-ObjectGraph' -Value 'epo'
Set-Alias -Name 'Export-ObjectGraph' -Value 'Export-Object'
Set-Alias -Name 'Get-ChildNode' -Value 'gcn'
Set-Alias -Name 'Get-Node' -Value 'gn'
Set-Alias -Name 'Import-ObjectGraph' -Value 'imo'
Set-Alias -Name 'Import-ObjectGraph' -Value 'Import-Object'
Set-Alias -Name 'Merge-ObjectGraph' -Value 'Merge-Object'
Set-Alias -Name 'Merge-ObjectGraph' -Value 'mgo'
Set-Alias -Name 'Get-SortObjectGraph' -Value 'Sort-ObjectGraph'
Set-Alias -Name 'Get-SortObjectGraph' -Value 'sro'
Set-Alias -Name 'Test-ObjectGraph' -Value 'Test-Object'
Set-Alias -Name 'Test-ObjectGraph' -Value 'tso'

#EndRegion Alias

#Region Format

if (-not (Get-FormatData 'PSNode' -ErrorAction Ignore)) {
    Update-FormatData -PrependPath $PSScriptRoot\Source\Formats\PSNode.Format.ps1xml
}
if (-not (Get-FormatData 'TestResult' -ErrorAction Ignore)) {
    Update-FormatData -PrependPath $PSScriptRoot\Source\Formats\TestResultTable.Format.ps1xml
}
if (-not (Get-FormatData 'XdnName' -ErrorAction Ignore)) {
    Update-FormatData -PrependPath $PSScriptRoot\Source\Formats\XdnName.Format.ps1xml
}
if (-not (Get-FormatData 'XdnPath' -ErrorAction Ignore)) {
    Update-FormatData -PrependPath $PSScriptRoot\Source\Formats\XdnPath.Format.ps1xml
}

#EndRegion Format

#Region Export

$ModuleMembers = @{
    Alias = 'cfe', 'cto', 'Copy-Object', 'cpo', 'Export-Object', 'epo', 'gcn', 'gn', 'Sort-ObjectGraph', 'sro', 'Import-Object', 'imo', 'Merge-Object', 'mgo', 'Test-Object', 'tso'
    Function = 'Compare-ObjectGraph', 'ConvertFrom-Expression', 'ConvertTo-Expression', 'Copy-ObjectGraph', 'Export-ObjectGraph', 'Get-ChildNode', 'Get-Node', 'Get-SortObjectGraph', 'Import-ObjectGraph', 'Merge-ObjectGraph', 'Test-ObjectGraph'
}
Export-ModuleMember @ModuleMembers
# https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#exporting-classes-with-type-accelerators
# Define the types to export with type accelerators.
$ExportableTypes = @(
    [LogicalOperatorEnum]
    [PSNodeStructure]
    [PSNodeOrigin]
    [ObjectCompareMode]
    [ObjectComparison]
    [XdnType]
    [XdnColorName]
    [Abbreviate]
    [LogicalTerm]
    [LogicalOperator]
    [LogicalVariable]
    [LogicalFormula]
    [PSNodePath]
    [PSNode]
    [PSLeafNode]
    [PSCollectionNode]
    [PSListNode]
    [PSMapNode]
    [PSDictionaryNode]
    [PSObjectNode]
    [ObjectComparer]
    [PSListNodeComparer]
    [PSMapNodeComparer]
    [PSDeserialize]
    [PSInstance]
    [PSKeyExpression]
    [PSLanguageType]
    [PSSerialize]
    [ANSI]
    [TextStyle]
    [TextColor]
    [CommandColor]
    [CommentColor]
    [ContinuationPromptColor]
    [DefaultTokenColor]
    [EmphasisColor]
    [ErrorColor]
    [KeywordColor]
    [MemberColor]
    [NumberColor]
    [OperatorColor]
    [ParameterColor]
    [SelectionColor]
    [StringColor]
    [TypeColor]
    [VariableColor]
    [InverseColor]
    [XdnName]
    [XdnPath]
)

# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [PSObject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)
# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
foreach ($Type in $ExportableTypes) {
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        $Message = @(
            "Unable to register type accelerator '$($Type.FullName)'"
            'Accelerator already exists.'
        ) -join ' - '

        throw [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($Message),
            'TypeAcceleratorAlreadyExists',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Type.FullName
        )
    }
}
# Add type accelerators for every exportable type.
foreach ($Type in $ExportableTypes) {
    $TypeAcceleratorsClass::Add($Type.FullName, $Type)
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()

#EndRegion Export
