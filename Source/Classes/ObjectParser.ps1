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

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

enum XdnType { Root; Ancestor; Index; Child; Descendant; Equals; Error = 99 }

enum XdnColorName { Reset; Regular; Literal; WildCard; Operator; Error = 99 }

class XdnColor {
    Static [String]$Regular
    Static [String]$Literal
    Static [String]$Wildcard
    Static [String]$Extended
    Static [String]$Operator
    Static [String]$Error
    Static [String]$Reset

    static XdnColor() {
        $PSReadLineOption = try { Get-PSReadLineOption -ErrorAction SilentlyContinue } catch { $Null }
        [XdnColor]::Reset    = [char]0x1b + '[39m'
        [XdnColor]::Regular  = $PSReadLineOption.VariableColor
        [XdnColor]::WildCard = $PSReadLineOption.EmphasisColor
        [XdnColor]::Extended = $PSReadLineOption.StringColor
        [XdnColor]::Operator = $PSReadLineOption.CommandColor
        [XdnColor]::Error    = $PSReadLineOption.ErrorColor
    }
}

class XdnValue {
    hidden static $Verbatim = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
    hidden [Bool]$_IsLiteral
    hidden $_IsWildcard
    hidden $_Value

    XdnValue($Value) {
        $this._IsLiteral = $False
        $this._IsWildcard = $Null
        $this._Value = $Value -replace '(?<=[^`](``)*)`(?=[\.\[\~\=\/])' # Remove any (odd number of) escapes from Xdn operators
    }

    XdnValue($Value, [Bool]$Literal) {
        $this._IsLiteral = $Literal
        $this._IsWildcard = $False
        $this._Value = $Value
    }

    [Bool] IsWildcard() {
        if ($this._IsLiteral) { $this._IsWildcard = $False }
        elseif ($Null -eq $this._IsWildcard) {
            $this._IsWildcard = $this._Value -is [String] -and $this._Value -Match '(?<=([^`]|^)(``)*)[\?\*]'
        }
        return $this._IsWildcard
    }

    [Bool] Equals($Object) {
        if ($this._IsLiteral)       { return $this._Value -eq $Object }
        elseif ($this.IsWildcard()) { return $Object -Like $this._Value }
        else                        { return $this._Value -eq $Object }
    }

    [String] ToString($Colored) {
        $Color = if ($Colored) {
            if ($this._IsLiteral)                                { [XdnColor]::Regular }
            elseif ($this._Value -NotMatch [XdnValue]::Verbatim) { [XdnColor]::Extended }
            elseif ($this.IsWildcard())                          { [XdnColor]::Wildcard }
            else                                                 { [XdnColor]::Regular }
        }
        $String =
            if ($this._IsLiteral) { "'" + "$($this._Value)".Replace("'", "''") + "'" }
            else { "$($this._Value)" -replace '(?<!([^`]|^)(``)*)[\.\[\~\=\/]', '`${0}' } # Escape any Xdn operator (that isn't yet escaped)
        $Reset = if ($Colored) { [XdnColor]::Reset }
        return $Color + $String + $Reset
    }
    [String] ToString()        { return $this.ToString($False) }
    [String] ToColoredString() { return $this.ToString($True) }

    static XdnValue() {
        Set-View { $_.ToString($True) }
    }
}

class XdnPath {
    hidden static $_PSReadLineOption
    hidden static $Verbatim = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices

    hidden $_Entries = [List[KeyValuePair[XdnType, Object]]]::new()

    hidden [Object]get_Entries() { return ,$this._Entries }

    hidden AddError($Value) {
        $this._Entries.Add([KeyValuePair[XdnType, Object]]::new('Error', $Value))
    }

    Add ($EntryType, $Value) {
        if ($EntryType -eq '/') {
            if ($this._Entries.Count -eq 0) { $this.AddError($Value) }
            elseif ($this._Entries[-1].Key -NotIn 'Child', 'Descendant', 'Equals') { $this.AddError($Value) }
            else {
                $EntryValue = $this._Entries[-1].Value
                if ($EntryValue -IsNot [IList]) { $EntryValue = [List[Object]]$EntryValue }
                $EntryValue.Add($Value)
                $this._Entries[-1] = [KeyValuePair[XdnType, Object]]::new($this._Entries[-1].Key, $EntryValue)
            }
        }
        else {
            $XdnType = Switch ($EntryType) { '.' { 'Child' } '~' { 'Descendant' } '=' { 'Equals' } default { $EntryType } }
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
                $StringAst = $Ast.EndBlock.Statements.PipelineElements.Find({ $args[0] -is [StringConstantExpressionAst] }, $False)[0]
                if ($Null -ne $StringAst) {
                    $this.Add($XdnOperator, [XdnValue]::new($StringAst.Value, $True))
                    $Path = $Path.SubString($StringAst.Extent.EndOffset)
                }
                else { # Probably a quoting error
                    $this.Add($XdnOperator, [XdnValue]::new($Path, $True))
                    $Path = $Null
                }
            }
            else {
                $Match = if ($Literal) { [regex]::Match($Path, '[\.\[]') } else { [regex]::Match($Path, '(?<=([^`]|^)(``)*)[\.\[\~\=\/]') }
                $Match = [regex]::Match($Path, '(?<=([^`]|^)(``)*)[\.\[\~\=\/]')
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
                    elseif ($Match.Value -in '.', '~', '=', '/' -and $Match.Value -ne $XdnOperator) {
                        $XdnOperator = $Match.Value
                        $Path = $Path.Substring(1)
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
                    $Value = if ($Literal) { [XdnValue]::new($Name, $True) } else { [XdnValue]$Name }
                    $this.Add($XdnOperator, $Value)
                    $Path = $Path.SubString($Match.Index)
                    $XdnOperator = $Null
                }
                else {
                    $Value = if ($Literal) { [XdnValue]::new($Path, $True) } else { [XdnValue]$Path }
                    $this.Add($XdnOperator, $Value)
                    $Path = $Null
                }
            }
        }
    }
    XdnPath ([String]$Path)                 { $this.FromString($Path, $False) }
    XdnPath ([String]$Path, [Bool]$Literal) { $this.FromString($Path, $Literal) }

    [String] ToString([String]$VariableName, [Bool]$Colored) {
        $RegularColor  = if ($Colored) { [XdnColor]::Regular }
        $OperatorColor = if ($Colored) { [XdnColor]::Operator }
        $ErrorColor    = if ($Colored) { [XdnColor]::Error }
        $ResetColor    = if ($Colored) { [char]0x1b + '[39m' }

        $Path = [System.Text.StringBuilder]::new()
        $PreviousEntry = $Null
        foreach ($Entry in $this._Entries) {
            $Value = $Entry.Value
            $Append = Switch ($Entry.Key) {
                Root        { "$OperatorColor$VariableName$ResetColor" }
                Ancestor    { "$OperatorColor$('.' * $Value)$ResetColor" }
                Index       {
                                $Dot = if (-not $PreviousEntry -or $PreviousEntry.Key -eq 'Ancestor') { "$OperatorColor." }
                                if ([int]::TryParse($Value, [Ref]$Null)) { "$Dot$RegularColor[$Value]$ResetColor" }
                                else { "$ErrorColor[$Value]$ResetColor" }
                            }
                Child       { "$RegularColor.$(@($Value).foreach{ $_.ToString($Colored) }  -Join ""$OperatorColor/"")" }
                Descendant  { "$OperatorColor~$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Equals      { "$OperatorColor=$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Default     { "$ErrorColor$($Value)$ResetColor" }
            }
            $Path.Append($Append)
            $PreviousEntry = $Entry
        }
        return $Path.ToString()
    }
    [String] ToString()                             { return $this.ToString($Null        , $False)}
    [String] ToString([String]$VariableName)        { return $this.ToString($VariableName, $False)}
    [String] ToColoredString()                      { return $this.ToString($Null,         $True)}
    [String] ToColoredString([String]$VariableName) { return $this.ToString($VariableName, $True)}

    static XdnPath() {
        Use-ClassAccessors
        Set-View { $_.ToColoredString('<Root>') }
    }
}

enum PSNodeOrigin { Root; List; Map }

Class PSNodePath {
    hidden [PSNode[]]$Nodes
    hidden [String]$_String

    hidden PSNodePath($Nodes) { $this.Nodes = [PSNode[]]$Nodes }

    [String] ToString() {
        if ($Null -eq $this._String) {
            $Count = $this.Nodes.Count
            $this._String = if ($Count -gt 1) { $this.Nodes[-2].Path.ToString() }
            $Node = $this.Nodes[-1]
            $this._String +=
                if ($Node._NodeOrigin -eq 'List') {
                    "[$($Node._Name)]"
                }
                elseif ($Node._NodeOrigin -eq 'Map') {
                    $Dot = if ($Count -gt 2) { '.' }
                    if     ($Node.Name -is [ValueType])        { "$Dot$($Node._Name)" }
                    elseif ($Node.Name -isnot [String])        { "$Dot[$($Node._Name.GetType())]'$($Node._Name)'" }
                    elseif ($Node.Name -Match '^[_,a-z]+\w*$') { "$Dot$($Node._Name)" }
                    else                                       { "$Dot'$($Node._Name)'" }
                }
        }
        return $this._String
    }

}

Class PSNode {
    hidden static PSNode() { Use-ClassAccessors }

    static [int]$DefaultMaxDepth = 20
    hidden $_Name
    [Int]$Depth
    hidden $_Value
    hidden [Int]$_MaxDepth = [PSNode]::DefaultMaxDepth
    hidden [PSNodeOrigin]$_NodeOrigin
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this
    hidden [PSNodePath]$_Path
    hidden [String]$_PathName
    hidden [Bool]$WarnedMaxDepth            # Warn ones per item branch

    hidden [object] get_Value() {
        return ,$this._Value
    }

    hidden set_Value($Value) {
        if ($this.GetType().Name -eq [PSNode]::getPSNodeType($Value)) { # The root node is of type PSNode (always false)
            $this._Value = $Value
            $this.ParentNode.SetItem($this._Name,  $Value)
        }
        else {
            Throw "The supplied value has a different PSNode type than the existing $($this.PathName). Use .ParentNode.SetItem() method and reload its child item(s)."
        }
    }

    hidden [Object] get_Name() {
        return ,$this._Name
    }

    hidden [Object] get_MaxDepth() {
        return $this.RootNode._MaxDepth
    }

    hidden set_MaxDepth($MaxDepth) {
        if (-not $this.ChildType) {
            $this._MaxDepth = $MaxDepth
        }
        else {
            Throw 'The MaxDepth can only be set at the root node: [PSNode].RootNode.MaxDepth = <Maximum Depth>'
        }
    }

    hidden [Object] get_NodeOrigin()  { return [PSNodeOrigin]$this._NodeOrigin }

    hidden [Type] get_ValueType() {
        if ($Null -eq $this._Value) { return $Null }
        else { return $this._Value.getType() }
    }

    hidden static [String]GetPSNodeType($Object) {
            if ($Object -is [Management.Automation.PSCustomObject]) { return 'PSObjectNode' }
        elseif ($Object -is [ComponentModel.Component])             { return 'PSObjectNode' }
        elseif ($Object -is [Collections.IDictionary])              { return 'PSDictionaryNode' }
        elseif ($Object -is [Collections.ICollection])              { return 'PSListNode' }
        else                                                        { return 'PSLeafNode' }
    }

    static [PSNode] ParseInput($Object, $MaxDepth) {
        $Node =
            if ($Object -is [PSNode]) { $Object }
            else {
                switch ([PSNode]::getPSNodeType($object)) {
                    'PSObjectNode'     { [PSObjectNode]::new($Object) }
                    'PSDictionaryNode' { [PSDictionaryNode]::new($Object) }
                    'PSListNode'       { [PSListNode]::new($Object) }
                    Default            { [PSLeafNode]::new($Object) }
                }
            }
        $Node.RootNode  = $Node
        if ($MaxDepth -gt 0) { $Node._MaxDepth = $MaxDepth }
        return $Node
    }

    static [PSNode] ParseInput($Object) { return [PSNode]::parseInput($Object, 0) }

    hidden [PSNode] Append($Object) {
        $Node = [PSNode]::ParseInput($Object)
        $Node.Depth       = $this.Depth + 1
        $Node.RootNode    = [PSNode]$this.RootNode
        $Node.ParentNode  = $this
        $Node._NodeOrigin = if ($this -is [PSListNode]) { 'List' } elseif ($this -is [PSMapNode]) { 'Map' }
        return $Node
    }

    hidden [Object] get_Path() {
        if ($Null -eq $this._Path) {
            if ($this.ParentNode) {
                $this._Path = [PSNodePath]($this.ParentNode.get_Path().Nodes + $this)
            }
            else {
                $this._Path = [PSNodePath]$this
            }
        }
        return $this._Path
    }

    hidden [String] get_PathName() { return $this.get_Path().ToString() }

    [String] GetPathName($VariableName) {
        $PathName = $this.get_Path().ToString()
        if ($PathName -and $PathName.StartsWith('.') ) {
            return "$VariableName$PathName"
        }
        else {
            return "$VariableName.$PathName"
        }
    }

    hidden CollectNodes($NodeTable, [XdnPath]$Path, [Int]$PathIndex) {
        $Entry = $Path._Entries[$PathIndex]
        $NextIndex = if ($PathIndex -lt $Path._Entries.Count -1) { $PathIndex + 1 }
        $NextEntry = if ($NextIndex) { $Path._Entries[$NextIndex] }
        $Equals    = if ($NextEntry -and $NextEntry.Key -eq 'Equals') {
            $NextEntry.Value
            $NextIndex = if ($NextIndex -lt $Path._Entries.Count -1) { $NextIndex + 1 }
        }
        switch ($Entry.Key) {
            Root {
                $Node = $this.RootNode
                if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                else { $NodeTable[$Node.get_PathName()] = $Node }
            }
            Ancestor {
                $Node = $this
                for($i = $Entry.Value; $i -gt 0 -and $Node.ParentNode; $i--) { $Node = $Node.ParentNode }
                if ($i -eq 0) { # else: reached root boundary
                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                    else { $NodeTable[$Node.get_PathName()] = $Node }
                }
            }
            Index {
                if ($this -is [PSListNode] -and [Int]::TryParse($Entry.Value, [Ref]$Null)) {
                    $Node = $this.GetChildNode([Int]$Entry.Value)
                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                    else { $NodeTable[$Node.get_PathName()] = $Node }
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
                            else { $NodeTable[$Node.get_PathName()] = $Node }
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

Class PSLeafNode : PSNode {

    hidden PSLeafNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    [Int]GetHashCode() {
        if ($Null -ne $this._Value) { return $this._Value.GetHashCode() } else { return '$Null'.GetHashCode() }
    }
}

Class PSCollectionNode : PSNode {
    hidden static PSCollectionNode() { Use-ClassAccessors }

    hidden [bool]MaxDepthReached() {
        $MaxDepthReached = $this.Depth -ge $this.RootNode._MaxDepth
        if ($MaxDepthReached -and -not $this.WarnedMaxDepth) {
            Write-Warning "$($this.Path) reached the maximum depth of $($this.RootNode._MaxDepth)."
            $this.WarnedMaxDepth = $True
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
        Write-Warning "Expected $SelectionName to be a $CollectionType selector for: <Object>$($Node.PathName)"
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

    [List[PSNode]]GetChildNodes($Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        $NodeList = [List[PSNode]]::new()
        $this.CollectChildNodes($NodeList, $Levels, $NodeOrigin, $Leaf)
        return $NodeList
    }
    [List[PSNode]]GetChildNodes()                                       { return $this.GetChildNodes(0, 0, $False) }
    [List[PSNode]]GetChildNodes([Int]$Levels)                           { return $this.GetChildNodes($Levels, 0, $False) }
    [List[PSNode]]GetChildNodes([PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) { return $this.GetChildNodes(0, $NodeOrigin, $Leaf) }

    hidden [PSNode[]]get_ChildNodes()      { return $this.GetChildNodes(0,  0,      $False) }
    hidden [PSNode[]]get_ListChildNodes()  { return [PSNode[]]$this.GetChildNodes(0,  'List', $False) }
    hidden [PSNode[]]get_MapChildNodes()   { return [PSNode[]]$this.GetChildNodes(0,  'Map',  $False) }
    hidden [PSNode[]]get_DescendantNodes() { return $this.GetChildNodes(-1, 0,      $False) }
    hidden [PSNode[]]get_LeafNodes()       { return $this.GetChildNodes(-1, 0,      $True) }
    hidden [PSNode]_($Name)                { return $this.GetChildNode($Name) }       # CLI Shorthand ("alias") for GetChildNode (don't use in scripts)
    # hidden [Object]Get($Path)                { return $this.GetDescendantNode($Path) }  # CLI Shorthand ("alias") for GetDescendantNode (don't use in scripts)
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

    [Bool]Contains($Index) {
       return $Index -ge 0 -and $Index -lt $this.get_Count()
    }

    [Object]GetItem($Index) {
            return $this._Value[$Index]
    }

    SetItem($Index, $Value) {
        $this._Value[$Index] = $Value
    }

    hidden CollectChildNodes($NodeList, [Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        if (-not $this.MaxDepthReached()) {
            for ($Index = 0; $Index -lt $this._Value.get_Count(); $Index++) {
                $Node = $this.Append($this._Value[$Index])
                $Node._Name = $Index
                if ($NodeOrigin -in 0, 'List' -and (-not $Leaf -or $Node -is [PSLeafNode])) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'Map')) { # $NodeOrigin -eq 'Map' --> Member Access Enumeration
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $Node.CollectChildNodes($NodeList, $Levels_1, $NodeOrigin, $Leaf)
                }
            }
        }
    }

    [Object]GetChildNode([Int]$Index) {
        if ($this.MaxDepthReached()) { return $Null }
        $Count = $this._Value.get_Count()
        if ($Index -lt -$Count -or $Index -ge $Count) {
            throw "The <Object>$($this.PathName) doesn't contain a child index: $Index"
        }
        $Node = $this.Append($this._Value[$Index])
        $Node._Name = $Index
        return $Node
    }

    [Int]GetHashCode() {
        $HashCode = '@()'.GetHashCode()
        foreach ($Node in $this.GetChildNodes(-1)) {
            $HashCode = $HashCode -bxor $Node.GetHashCode()
        }
        # Shift the bits to make the level unique
        $HashCode = if ($HashCode -band 1) { $HashCode -shr 1 } else { $HashCode -shr 1 -bor 1073741824 }
        return $HashCode -bxor 0xa5a5a5a5
    }
}

Class PSMapNode : PSCollectionNode {
    hidden static PSMapNode() { Use-ClassAccessors }

    [Int]GetHashCode() {
        $HashCode = '@{}'.GetHashCode()
        foreach ($Node in $this.GetChildNodes(-1)) {
            $HashCode = $HashCode -bxor "$($Node._Name)=$($Node.GetHashCode())".GetHashCode()
        }
        return $HashCode
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

    [Bool]Contains($Key) {
        return $this._Value.Contains($Key)
    }

    [Object]GetItem($Key) {
        return $this._Value[$Key]
    }

    SetItem($Key, $Value) {
        $this._Value[$Key] = $Value
    }

    hidden CollectChildNodes($NodeList, [Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        if (-not $this.MaxDepthReached()) {
            foreach($Key in $this._Value.get_Keys()) {
                $Node = $this.Append($this._Value[$Key])
                $Node._Name = $Key
                if ($NodeOrigin -in 0, 'Map' -and (-not $Leaf -or $Node -is [PSLeafNode])) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'List')) {
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $Node.CollectChildNodes($NodeList, $Levels_1, $NodeOrigin, $Leaf)
                }
            }
        }
    }

    [Object]GetChildNode($Key) {
        if ($this.MaxDepthReached()) { return $Null }
        if (-not $this._Value.Contains($Key)) {
            Throw "The <Object>$($this.PathName) doesn't contain a child named: $Key"
        }
        $Node = $this.Append($this._Value[$Key])
        $Node._Name = $Key
        return $Node
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

    [Bool]Contains($Name) {
        return $this._Value.PSObject.Properties[$Name]
    }

    [Object]GetItem($Name) {
        return $this._Value.PSObject.Properties[$Name].Value
    }

    SetItem($Name, $Value) {
        $this._Value.PSObject.Properties[$Name].Value = $Value
    }

    hidden CollectChildNodes($NodeList, [Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        if (-not $this.MaxDepthReached()) {
            foreach($Property in $this._Value.PSObject.Properties) {
                $Node = $this.Append($Property.Value)
                $Node._Name = $Property.Name
                if ($NodeOrigin -in 0, 'Map' -and (-not $Leaf -or $Node -is [PSLeafNode])) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'List')) {
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $Node.CollectChildNodes($NodeList, $Levels_1, $NodeOrigin, $Leaf)
                }
            }
        }
    }

    [Object]GetChildNode([String]$Name) {
        if ($this.MaxDepthReached()) { return $Null }
        if ($Name -NotIn $this._Value.PSObject.Properties.Name) {
            Throw "The <Object>$($this.PathName) doesn't contain a child named: $Name"
        }
        $Node = $this.Append($this._Value.PSObject.Properties[$Name].Value)
        $Node._Name = $Name
        return $Node
    }
}

Update-TypeData -TypeName PSNode -DefaultDisplayPropertySet Path, Name, Depth, Value -Force
