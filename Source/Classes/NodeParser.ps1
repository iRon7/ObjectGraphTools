<#
.SYNOPSIS
    Class to support Object Graph Tools
.DESCRIPTION
    This class provides general properties and method to recursively
    iterate through to PowerShell Object Graph nodes.

    For details, see:

    * [PowerShell Object Parser][1] for details on the `[PSNode]` properties and methods.
    * [Extended-Dot-Notation][2] for details on path selectors.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Xdn.md "Extended Dot Notation"
#>

using module .\..\..\..\ObjectGraphTools

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Linq.Expressions
using namespace System.Reflection

enum PSNodeStructure { Leaf; List; Map }
enum PSNodeOrigin { Root; List; Map }

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
                    foreach ($Value in $Entry.Value) {
                        $Name = $Value._Value
                        if ($Value.ContainsWildcard()) {
                            foreach ($Node in $this.ChildNodes) {
                                if ($Node.Name -like $Name -and (-not $Equals -or ($Node -is [PSLeafNode] -and $Equals -eq $Node._Value))) {
                                    $Found = $True
                                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                                    else { $NodeTable[$Node.getPathName()] = $Node }
                                }
                            }
                        }
                        elseif ($this.Contains($Name)) {
                            $Node = $this.GetChildNode($Name)
                            if (-not $Equals -or ($Node -is [PSLeafNode] -and $Equals -eq $Node._Value)) {
                                $Found = $True
                                if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                                else { $NodeTable[$Node.getPathName()] = $Node }
                            }
                        }
                    }
                    if (-not $Found -and $Entry.Key -eq 'Descendant') {
                        foreach ($Node in $this.ChildNodes) {
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
