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

using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

enum XdnPredecessor { Root; Parent; Ancestor }
enum XdnType { Root; Ancestor; Index; Child; Descendant }

class Literal {
    hidden [String]$_String

    Literal([String]$String) {
        $this._String = $String
    }

    [String] ToString() {
        return $this._String
    }

    [String] Quoted() {
        return "'" + $this._String.Replace("'", "''") + "'"
    }
}

class XdnPath {
    hidden static $_PSReadLineOption
    hidden static $Verbatim = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices

    hidden $_Entries = [List[KeyValuePair[XdnType, Object]]]::new()

    hidden [Object]get_Entries() { return ,$this._Entries }

    Add ([XdnType]$XdnType, $Value) {
        $KeyValuePair = [KeyValuePair[XdnType, Object]]::new($XdnType, $Value)
        $this._Entries.Add($KeyValuePair)
    }

    XdnPath ([String]$Path) {
        if (-not $this._Entries.Count -and $Path -notmatch '^(?<=([^`]|^)(``)*)[\.]') { $this.Add('Root', $Null) }
        $Length = [Int]::MaxValue
        [XdnPredecessor]$Predecessor = 'Root'
        while ($Path) {
            if ($Path.Length -ge $Length) { break }
            $Length = $Path.Length
            if ($Path[0] -in "'", '"') {
                $Ast = [Parser]::ParseInput($Path, [ref]$Null, [ref]$Null)
                $StringAst = $Ast.EndBlock.Statements.PipelineElements.Find({ $args[0] -is [StringConstantExpressionAst] }, $false)[0]
                if ($Null -ne $StringAst) {
                    if ($Predecessor -eq 'Ancestor') { $this.Add('Descendant', [Literal]$StringAst.Value) }
                    else { $this.Add('Child', [Literal]$StringAst.Value) }
                    $Path = $Path.SubString($StringAst.Extent.EndOffset)
                }
                else { # Likely a quoting error
                    if ($Predecessor -eq 'Ancestor') { $this.Add('Descendant', [Literal]$Path) }
                    else { $this.Add('Child', [Literal]$Path) }
                    $Path = $Null
                }
            }
            else {
                $Match = [regex]::Match($Path, '(?<=([^`]|^)(``)*)[\.\[\-]')
                if ($Match.Success -and $Match.Index -eq 0) {
                    $IndexEnd  = if ($Match.Value -eq '[') { $Path.IndexOf(']') }
                    $Ancestors = if ($Match.Value -eq '.' -and $Path -Match '^\.\.+') { $Matches[0].Length - 1 }
                    if ($IndexEnd -gt 0 -and $Predecessor -ne 'Ancestor') {
                        $Index = $Path.SubString(1, ($IndexEnd - 1))
                        $CommandAst = [Parser]::ParseInput($Index, [ref]$Null, [ref]$Null).EndBlock.Statements.PipelineElements
                        if ($CommandAst -is [CommandExpressionAst]) { $Index = $CommandAst.expression.Value }
                        $this.Add('Index', $Index)
                        $Path = $Path.SubString(($IndexEnd + 1))
                    }
                    elseif ($Ancestors) {
                        $Predecessor = 'Parent'
                        $this.Add('Ancestor', $Ancestors)
                        $Path = $Path.Substring($Ancestors + 1)
                    }
                    elseif ($Match.Value -eq '.') {
                        $Predecessor = 'Parent'
                        $Path = $Path.Substring(1)
                    }
                    elseif ($Match.Value -eq '-' -and ($this._Entries.Count -and $this._Entries[-1].Key -ne 'Descendant')) {
                        $Predecessor = 'Ancestor'
                        $Path = $Path.Substring(1)
                    }
                    else { # Likely a selector error
                        if ($Predecessor -eq 'Ancestor') { $this.Add('Descendant', $Match.Value) } else { $this.Add('Child', $Match.Value) }
                        $Path = $Path.Substring(1)
                    }
                }
                elseif ($Match.Success) {
                    $Name = $Path.SubString(0, $Match.Index)
                    if ($Predecessor -eq 'Ancestor') { $this.Add('Descendant', $Name) } else { $this.Add('Child', $Name) }
                    $Path = $Path.SubString($Match.Index)
                }
                else {
                    if ($Predecessor -eq 'Ancestor') { $this.Add('Descendant',$Path) } else { $this.Add('Child', $Path) }
                    $Path = $Null
                }
            }
        }
    }
    [String] ToString([String]$VariableName, [Bool]$Color) {
        if ($Null -eq [XdnPath]::_PSReadLineOption) {
            if (Get-Command Get-PSReadLineOption -ErrorAction SilentlyContinue) {
                [XdnPath]::_PSReadLineOption = Get-PSReadLineOption
            }
            else { [XdnPath]::_PSReadLineOption = $false }
        }

        $Option = [XdnPath]::_PSReadLineOption
        if (-not $Option) { $Color = $false }
        $RegularColor  = if ($Color) { $Option.VariableColor }
        $WildcardColor = if ($Color) { $Option.EmphasisColor }
        $SpecialColor  = if ($Color) { $option.CommandColor }
        $ErrorColor    = if ($Color) { $Option.ErrorColor }
        $ResetColor    = if ($Color) { [char]0x1b + '[39m' }

        $Path = [System.Text.StringBuilder]::new()
        $PreviousEntry = $Null
        foreach ($Entry in $this._Entries) {
            $Value = $Entry.Value
            $Append = Switch ($Entry.Key) {
                Root {
                    "$SpecialColor$VariableName$ResetColor"
                }
                Ancestor {
                    "$SpecialColor$('.' * $Value)$ResetColor"
                }
                Index {
                    $Dot = if (-not $PreviousEntry -or $PreviousEntry.Key -eq 'Ancestor') { "$SpecialColor." }
                    if ([int]::TryParse($Value, [Ref]$Null)) { "$Dot$RegularColor[$Value]$ResetColor" }
                    else { "$ErrorColor[$Value]$ResetColor" }
                }
                Child {
                    if ($Value -is [Literal])                     { "$RegularColor.$($Value.Quoted())$ResetColor" }
                    elseif ($Value -NotMatch [XdnPath]::Verbatim) { "$ErrorColor.$Value$ResetColor" }
                    elseif ($Value -Match '[\?\*]')               { "$WildcardColor.$Value$ResetColor" }
                    else                                          { "$RegularColor.$Value$ResetColor" }
                }
                Descendant {
                    if ($Value -is [Literal])                     { "$SpecialColor-$ErrorColor$($Value.Quoted())$ResetColor" }
                    elseif ($Value -NotMatch [XdnPath]::Verbatim) { "$SpecialColor-$ErrorColor$Value$ResetColor" }
                    elseif ($Value -Match '[\?\*]')               { "$SpecialColor-$WildcardColor$Value$ResetColor" }
                    else                                          { "$SpecialColor-$RegularColor$Value$ResetColor" }
                }
            }
            $Path.Append($Append)
            $PreviousEntry = $Entry
        }
        return $Path.ToString()
    }
    [String] ToString()                           { return $this.ToString($Null        , $false)}
    [String] ToString([String]$VariableName)      { return $this.ToString($VariableName, $false)}
    [String] ToColorString()                      { return $this.ToString($Null,         $true)}
    [String] ToColorString([String]$VariableName) { return $this.ToString($VariableName, $true)}

    static XdnPath() { # https://stackoverflow.com/questions/77752014/how-to-type-convert-a-derived-class
        $FormatData = @'
        <Configuration>
        <ViewDefinitions>
            <View>
            <Name>XdnPath</Name>
            <OutOfBand />
            <ViewSelectedBy>
                <TypeName>XdnPath</TypeName>
            </ViewSelectedBy>
                <CustomControl>
                <CustomEntries>
                    <CustomEntry>
                    <CustomItem>
                        <ExpressionBinding>
                        <ScriptBlock>
                            <![CDATA[$_.ToColorString('<Root>')]]>
                        </ScriptBlock>
                        </ExpressionBinding>
                    </CustomItem>
                    </CustomEntry>
                </CustomEntries>
                </CustomControl>
            </View>
            </ViewDefinitions>
        </Configuration>
'@
        $TempFile = [IO.Path]::GetTempPath() + "XdnPath.ps1xml"
        Out-File -InputObject $FormatData -LiteralPath $TempFile -Encoding ASCII
        Update-FormatData -PrependPath $TempFile
    }
}

enum PSNodeOrigin { Root; List; Map }


Class PSNode {
    static [int]$DefaultMaxDepth = 20
    hidden $_Name
    [Int]$Depth
    hidden $_Value
    hidden [Int]$_MaxDepth = [PSNode]::DefaultMaxDepth
    hidden [PSNodeOrigin]$_NodeOrigin
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this               # This will be overwritten by the Append method
    hidden [PSNode[]]$_Path = @()
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
        $Node.RootNode    = $this.RootNode
        $Node.ParentNode  = $this
        $Node._NodeOrigin = if ($this -is [PSListNode]) { 'List' } elseif ($this -is [PSMapNode]) { 'Map' }
        return $Node
    }

    hidden [List[PSNode]] get_Path() {
        if ($this._Path.Count -eq 0) {
            if ($this.ParentNode) { $ParentPath = $this.ParentNode.get_Path() } else { $ParentPath =  @() }
            $this._Path = $ParentPath + $this # This will shallow copy the parent path
        }
        return $this._Path
    }

    [String] GetPathName() {
        if ($Null -eq $this._PathName) {
            $ParentPathName = if ($this.ParentNode) { $this.ParentNode.GetPathName() }
            $Name =
                if ($this._NodeOrigin -eq 'List') {
                    "[$($this._Name)]"
                }
                elseif ($this._NodeOrigin -eq 'Map') {
                    $Dot = if ($this.ParentNode.ParentNode) { '.' }
                    if     ($this.Name -is [ValueType])        { "$Dot$($this._Name)" }
                    elseif ($this.Name -isnot [String])        { "$Dot[$($this._Name.GetType())]'$($this._Name)'" }
                    elseif ($this.Name -Match '^[_,a-z]+\w*$') { "$Dot$($this._Name)" }
                    else                                       { "$Dot'$($this._Name)'" }
                }
            $this._PathName = $ParentPathName + $Name
        }
        return $this._PathName
    }

    [String] GetPathName($VariableName) {
        $PathName = $this.GetPathName()
        if ($PathName -and $PathName[0] -in '.', '-', '[' ) {
            return "$VariableName$PathName"
        }
        else {
            return "$VariableName.$PathName"
        }
    }
    hidden [String] get_PathName() { return $this.GetPathName() }

    hidden CollectNodes($PathNodes, [XdnPath]$Path, [Int]$PathIndex) {
        $Entry = $Path._Entries[$PathIndex]
        $NextIndex = if ($PathIndex -lt $Path._Entries.Count -1) { $PathIndex + 1 }
        switch ($Entry.Key) {
            Root {
                $Node = $this.RootNode
                if ($NextIndex) { $Node.CollectNodes($PathNodes, $Path, $NextIndex) }
                else { $PathNodes[$Node.get_PathName()] = $Node }
            }
            Ancestor {
                $Node = $this
                for($i = $Entry.Value; $i -gt 0 -and $Node.ParentNode; $i--) { $Node = $Node.ParentNode }
                if ($i -eq 0) { # else: reached root boundary
                    if ($NextIndex) { $Node.CollectNodes.GetNode($PathNodes, $Path, $NextIndex) }
                    else { $PathNodes[$Node.get_PathName()] = $Node }
                }
            }
            Index {
                if ($this -is [PSListNode] -and [Int]::TryParse($Entry.Value, [Ref]$Null)) {
                    $Node = $this.GetChildNode([Int]$Entry.Value)
                    if ($NextIndex) { $Node.CollectNodes($PathNodes, $Path, $NextIndex) }
                    else { $PathNodes[$Node.get_PathName()] = $Node }
                }
            }
            Default { # Child, Descendant
                if ($this -is [PSListNode]) { # Member access enumeration
                    foreach ($Node in $this.get_ChildNodes()) {
                        $Node.CollectNodes($PathNodes, $Path, $PathIndex)
                    }
                }
                elseif ($this -is [PSMapNode]) {
                    $Found = $False
                    $ChildNodes = $this.get_ChildNodes()
                    foreach ($Node in $ChildNodes) {
                        $Exists = if ($Entry.Value -is [Literal]) { $Node.Name -eq $Entry.Value } else { $Node.Name -like $Entry.Value }
                        if ($Exists) {
                            $Found = $True
                            if ($NextIndex) { $Node.CollectNodes($PathNodes, $Path, $NextIndex) }
                            else { $PathNodes[$Node.get_PathName()] = $Node }
                        }
                    }
                    if (-not $Found -and $Entry.Key -eq 'Descendant') {
                        foreach ($Node in $ChildNodes) {
                            $Node.CollectNodes($PathNodes, $Path, $PathIndex)
                        }
                    }
                }
            }
        }
    }

    [Object] GetNode([XdnPath]$Path) {
        $PathNodes = [system.collections.generic.dictionary[String, PSNode]]::new() # Case sensitive (case insensitive map nodes use the same name)
        $this.CollectNodes($PathNodes, $Path, 0)
        if ($PathNodes.Count -eq 0) { return @() }
        if ($PathNodes.Count -eq 1) { return $PathNodes[$PathNodes.Keys] }
        else                        { return [PSNode[]]$PathNodes.Values }
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
    hidden [bool]MaxDepthReached() {
        $MaxDepthReached = $this.Depth -ge $this.RootNode._MaxDepth
        if ($MaxDepthReached -and -not $this.WarnedMaxDepth) {
            Write-Warning "$($this.Path) reached the maximum depth of $($this.RootNode._MaxDepth)."
            $this.WarnedMaxDepth = $true
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

    [List[PSNode]]GetNodes() {
        return $this.GetNodes(0, 0, $false)
    }
    [List[PSNode]]GetNodes([Int]$Levels) {
        return $this.GetNodes($Levels, 0, $false)
    }
    [List[PSNode]]GetNodes([PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        return $this.GetNodes(0, $NodeOrigin, $Leaf)
    }
    hidden [Object]get_ChildNodes()      { return [PSNode[]]$this.GetNodes(0,  0,      $false) }
    hidden [Object]get_ListChildNodes()  { return [PSNode[]]$this.GetNodes(0,  'List', $false) }
    hidden [Object]get_MapChildNodes()   { return [PSNode[]]$this.GetNodes(0,  'Map',  $false) }
    hidden [Object]get_DescendantNodes() { return [PSNode[]]$this.GetNodes(-1, 0,      $false) }
    hidden [Object]get_LeafNodes()       { return [PSNode[]]$this.GetNodes(-1, 0,      $true) }
    hidden [Object]_($Name)              { return [PSNode]$this.GetChildNode($Name) }       # CLI Shorthand ("alias") for GetChildNode (don't use in scripts)
    # hidden [Object]Get($Path)                { return $this.GetDescendantNode($Path) }  # CLI Shorthand ("alias") for GetDescendantNode (don't use in scripts)
}

Class PSListNode : PSCollectionNode {
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

    [List[PSNode]]GetNodes([Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        $List = [List[PSNode]]::new()
        if (-not $this.MaxDepthReached()) {
            for ($Index = 0; $Index -lt $this._Value.Get_Count(); $Index++) {
                $Node = $this.Append($this._Value[$Index])
                $Node._Name = $Index
                if ($NodeOrigin -in 0, 'List' -or ($Leaf -and $Node -is [PSLeafNode])) { $List.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'Map')) { # $NodeOrigin -eq 'Map' --> Member Access Enumeration
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $list.AddRange($Node.GetNodes($Levels_1, $NodeOrigin, $Leaf))
                }
            }
        }
        return $List
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
        foreach ($Node in $this.GetNodes(-1)) {
            $HashCode = $HashCode -bxor $Node.GetHashCode()
        }
        # Shift the bits to make the level unique
        $HashCode = if ($HashCode -band 1) { $HashCode -shr 1 } else { $HashCode -shr 1 -bor 1073741824 }
        return $HashCode -bxor 0xa5a5a5a5
    }
}

Class PSMapNode : PSCollectionNode {

    [Int]GetHashCode() {
        $HashCode = '@{}'.GetHashCode()
        foreach ($Node in $this.GetNodes(-1)) {
            $HashCode = $HashCode -bxor "$($Node._Name)=$($Node.GetHashCode())".GetHashCode()
        }
        return $HashCode
    }
}

Class PSDictionaryNode : PSMapNode {
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

    [List[PSNode]]GetNodes([Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        $List = [List[PSNode]]::new()
        if (-not $this.MaxDepthReached()) {
            foreach($Key in $this._Value.get_Keys()) {
                $Node = $this.Append($this._Value[$Key])
                $Node._Name = $Key
                if ($NodeOrigin -in 0, 'Map' -or ($Leaf -and $Node -is [PSLeafNode])) { $List.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'List')) {
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $list.AddRange($Node.GetNodes($Levels_1, $NodeOrigin, $Leaf))
                }
            }
        }
        return $List
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

    [List[PSNode]]GetNodes([Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        $List = [List[PSNode]]::new()
        if (-not $this.MaxDepthReached()) {
            foreach($Property in $this._Value.PSObject.Properties) {
                $Node = $this.Append($Property.Value)
                $Node._Name = $Property.Name
                if ($NodeOrigin -in 0, 'Map' -or ($Leaf -and $Node -is [PSLeafNode])) { $List.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'List')) {
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $list.AddRange($Node.GetNodes($Levels_1, $NodeOrigin, $Leaf))
                }
            }
        }
        return $List
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

Use-ClassAccessors -Force

Update-TypeData -TypeName PSNode -DefaultDisplayPropertySet PathName, Name, Depth, Value -Force
