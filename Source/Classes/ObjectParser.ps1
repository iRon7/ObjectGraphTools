<#
# Object Parser

This class provides general properties and method to recursively
iterate through to PowerShell Object Graph nodes.

## Example "Iterate trough each recursive node and return it property path"

The following function recursively iterates through all the property nodes (`PSNodes`)
of an object-graph and returns the path to each object.

```PowerShell
function Iterate([PSNode]$Node) { # Basic iterator
    $Node.PathName
    if ($Node -is [PSCollectionNode]) {
        $Node.ChildNodes.foreach{ Iterate $_ }
    }
}

$Object = $Json | ConvertFrom-Json
$PSNode = [PSNode]::ParseInput($Object)
Iterate $PSNode
```

## Class hierarchy

The general class is called `[PSNode]`and has a hierarchy of sub-classes

```plaintext
         [PSLeafNode]
        /
[PSNode]                    [PSListNode]
        \                  /
         [PSCollectionNode]             [PSDictionaryNode]
                           \           /
                            [PSMapNode]
                                       \
                                        [PSObjectNode]
```

### `[PSNode]`

The base type of a PSNode. Each PSNode will have at least 1 additional PSNode derivative
listed below.

### `[PSLeafNode]`

A PSLeafNode terminates a PSNode branch and doesn't have any child nodes attached.
A value embedded by a PSLeafNode is not enumerable and doesn't contain any object properties.

### `[PSCollectionNode]`

A PSCollectionNode represents a PSNode containing a collection child nodes.
A value embedded by a PSCollectionNode is enumerable or contains object properties.

### `[PSListNode]`

A PSListNode represents a  PSNode listing any number (or none) child nodes.
A value embedded by a PSListNode supports the `IList` interface but excludes any value that.
support the IDictionary interface.

### `[PSMapNode]`

A PSMapNode represents a PSNode containing any number (or none) child nodes.
A value embedded by a PSMapNode supports the IDictionary interface or contains object properties.

### `[PSDictionaryNode]`

A PSDictionaryNode represents a PSNode containing any number (or none) child nodes.
A value embedded by a PSDictionaryNode supports the IDictionary interface.

### `[PSObjectNode]`

A PSObjectNode represents a PSNode containing any number (or none) child nodes.
A value embedded by a PSObjectNode contains object properties meaning that it is either of type
`[PSCustomObject]` or `[ComponentModel.Component]`.

## Constructors

There are no noteworthy constructors.
To create a new PSNode instance, use the static `[PSNode]::ParseInput(<Object-Graph>)]`
method or the `ChildNodes` property or `GetChildNode(<name>)` of an existing PSNode
instance

## Properties

### `Name` (ReadOnly)

The name of the embedded property defined by its parent.
The name is `$Null` if the embedded node is the root node.

### `Value`

The actual object, item, property or value embedded by the PSNode.
The value might be modified but should be of the same structure (`[PSLeafNode]`, `[PSListNode]`,
`[PSDictionaryNode]` or `[PSObjectNode]`) as the original node type.

### `Depth` (ReadOnly)

The depth where the current PSNode resides in the PSNode hierarchy (aka tree).
An error will occur if the depth exceed the `MaxDepth` setting.

### `MaxDepth`

The maximum iteration depth of the embedded graph object.
The `MaxDepth` value can be read at every level but can only be set on the root node:
`[PSNode].RootNode.MaxDepth = <Maximum Depth>`

### `ValueType` (ReadOnly)

The type of the value embedded by the PSNode.
`$Null` if the embedded value is `$Null`

### `NodeOrigin` (ReadOnly)

Defines whether the parent node is a `[PSListNode]` type, a `[PSMapNode]` type.
The NodeOrigin is `Root` if the current node has no parent node.

### `ParentNode` (ReadOnly)

Refers to node containing the current PSNode and possible siblings.

### `RootNode` (ReadOnly)

Refers to the top node containing the current PSNode and all its decedents.

### `ChildNodes` (ReadOnly) (`[PSCollectionNodes]` only)

Returns all the child nodes contained by the current PSNode.
To retrieve a specific child node, use the `GetChildNode(<Name>)` method.

### `DescendantNodes` (ReadOnly) (`[PSCollectionNodes]` only)

Returns all the descendant nodes (up and till the `$MaxDepth` level) contained
by the current PSNode.

### `Count` (ReadOnly) (`[PSCollectionNodes]` only)

Returns the number of items or properties contained by the embedded value.
This number is equal to the number of child nodes contained by the current node.

### `Names` (ReadOnly) (`[PSCollectionNodes]` only)

Returns the property or key names of the embedded value. If the PSNode is of
`[PSListNode]` type list a indices (starting from zero) is returned.
The name of each child node is equal to the name (or index) that identifies item
of the embedded value

### `Values` (ReadOnly) (`[PSCollectionNodes]` only)

Returns all the value of the items or properties of the embedded value.
A PSNode derived from a `[PSLeafNode]` type doesn't have a `Values` property.

### `Path` (ReadOnly)

Returns all the branch of PSNodes starting from the root PSNode up and till
the current PSNode

### `PathName` (ReadOnly)

Returns an unique path (string) identifying the current node in the PSNode tree
starting from the root node.
The path might be used to directly target the property or item of a object-graph
aka the value contained by the root node.

## Methods

### `[PSNode]::ParseInput(<object-graph> [, <maximal depth = 10>])`

This static method converts a object-graph to a [PSNode] structure and supplies access
to the underlying child nodes.
The `<maximal depth>` argument, set the maximal depth of the properties  that will be
recursively retrieve. When the maximal depth is reached, an error is throw.
The default maximal depth is defined by the static property `[PSNode]::MaxDepth` (default: 10)

### `GetChildNode(<name>)` (`[PSCollectionNodes]` only)

Returns a specific child node (`[PSNode]`) selected by the name (or index) of the embedded

> [!Note]
> The `GetChildNode` has a Shorthand ("alias"): `_(<name>)` which shouldn't be used
> in scripts as the its name or functionality might change in the future

### `GetDescendentNode(<path>)` (`[PSCollectionNodes]` only)

Returns a specific child node (`[PSNode]`) selected by the path of the embedded object
The path might be either:

* As [String] a "dot-property" selection as defined by the `PathName` property a specific node.
* A array of strings (dictionary keys or Property names) and/or Integers (list indices).
* A object (`PSNode[]`) list where each `Name` property defines the path

> [!Note]
> The `GetDescendentNode` has a Shorthand ("alias"): `Get(<name>)` which shouldn't be used
> in scripts as the its name or functionality might change in the future

### `GetDescendentNodes(<generations>)` (`[PSCollectionNodes]` only)

Returns all descendant nodes of the current node for a the defined number of generations.

> [!Note]
> The number of generations will not surpass the `MaxDepth` defined at the root.

### `GetItem(<name>)` (`[PSCollectionNodes]` only)

Returns the value of a specific item identified by `<name>` of the embedded collection
or object.

### `SetItem(<name>, <value>)` (`[PSCollectionNodes]` only)

Sets the value of a specific item identified by `<name>` of the embedded collection
or object. The new value should be of the same structure (`[PSLeafNode]`, `[PSListNode]`,
`[PSDictionaryNode]` or `[PSObjectNode]`) as the original node type.

### `Contains(<name>)` (`[PSCollectionNodes]` only)

Determines whether a specific item identified by `<name>` is contained by th embedded
collection or object.
#>

Using NameSpace System.Management.Automation.Language
enum PSNodeOrigin { Root; List; Map}

Class PSNode {
    static [int]$DefaultMaxDepth = 10
    hidden $_Name
    [Int]$Depth
    hidden $_Value
    hidden [Int]$_MaxDepth = [PSNode]::DefaultMaxDepth
    hidden [PSNodeOrigin]$_NodeOrigin
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this               # This will be overwritten by the Append method
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

    [Object] get_Name() {
        return ,$this._Name
    }

    [Object] get_MaxDepth() {
        return $this.RootNode._MaxDepth
    }

    hidden set_MaxDepth($MaxDepth) {
        if ($this.NodeOrigin -eq 'Root') {
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

    hidden static [String]getPSNodeType($Object) {
            if ($Object -is [Management.Automation.PSCustomObject]) { return 'PSObjectNode' }
        elseif ($Object -is [ComponentModel.Component])             { return 'PSObjectNode' }
        elseif ($Object -is [Collections.IDictionary])              { return 'PSDictionaryNode' }
        elseif ($Object -is [Collections.ICollection])              { return 'PSListNode' }
        else                                                        { return 'PSLeafNode' }
    }

    static [PSNode] ParseInput($Object) {
        if     ($Object -is [PSNode]) { return $Object }
        switch ([PSNode]::getPSNodeType($object)) {
            'PSObjectNode'     { return [PSObjectNode]$Object }
            'PSDictionaryNode' { return [PSDictionaryNode]$Object }
            'PSListNode'       { return [PSListNode]$Object }
            Default            { return [PSLeafNode]$Object }
        }
        Throw 'Unknown structure'
    }

    static [PSNode] ParseInput($Object, [int]$MaxDepth) {
        $Node = [PSNode]::parseInput($Object)
        $Node.RootNode  = $Node
        $Node._MaxDepth = $MaxDepth
        return $Node
    }

    hidden [PSNode] Append($Object) {
        $Node = [PSNode]::ParseInput($Object)
        $Node.Depth      = $this.Depth + 1
        $Node.RootNode   = $this.RootNode
        $Node.ParentNode = $this

        return $Node
    }

    hidden [System.Collections.Generic.List[PSNode]] get_Path() {
        if ($this.ParentNode) { $Path = $this.ParentNode.get_Path() }
        else { $Path = [System.Collections.Generic.List[PSNode]]::new() }
        $Path.Add($this)
        return $Path
    }

    hidden [String] get_PathName() {
        return -Join @($this.get_Path()).foreach{
            if ($_._NodeOrigin -eq 'List') {
                "[$($_._Name)]"
            }
            elseif ($_._NodeOrigin -eq 'Map') {
                if     ($_.Name -is [ValueType])        { ".$($_._Name)" }
                elseif ($_.Name -isnot [String])        { ".[$($_._Name.GetType())]'$($_._Name)'" }
                elseif ($_.Name -Match '^[_,a-z]+\w*$') { ".$($_._Name)" }
                else                                         { ".'$($_._Name)'" }
            }
        }
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

    hidden[Collections.Generic.List[Ast]] GetAstSelectors ($Ast) {
        $List = [Collections.Generic.List[Ast]]::new()
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

    [Object]GetDescendentNode($Path) {
        if ($Path -is [String]) {
            $String = if ($Path.StartsWith('.') -or $Path.StartsWith('[')) { "`$_$Path"} else { "`$_.$Path"}
            $Ast  = [Parser]::ParseInput($String, [ref]$Null, [ref]$Null)
            $Ast = $Ast.EndBlock.Statements.PipeLineElements.Expression
            $Selectors = $this.GetAstSelectors($Ast)
        }
        elseif ($Path -is [PSNode]) { $Selectors = $Path.Path }
        else { $Selectors = $Path }
        $Node = $this
        foreach ($Selector in $Selectors) {
            if ($Node -is [PSLeafNode]) {
                Throw "Can not select child node in <object>$($Node.PathName) as it is a leaf node."
            }
            elseif ($Selector -is [IndexExpressionAst]) {
                $Name = $Selector.Index.Value
                if ($Node -isnot [PSListNode]) { $this.WarnSelector($Node, $Name) }
            }
            elseif ($Selector -is [MemberExpressionAst]) {
                $Name = $Selector.Member.Value
                if ($Node -isnot [PSMapNode]) { $this.WarnSelector($Node, $Name) }
            }
            else {
                $Name = if ($Selector.PSObject.Properties['Name']) { $Selector.Name } else { $Selector }
                if ($Selector -is [PSNode]) {
                    if ($Selector.PSNodeOrigin -eq 'List' -and  $Node -isnot [PSListNode]) { $this.WarnSelector($Node, $Name) }
                    if ($Selector.PSNodeOrigin -eq 'Map'  -and  $Node -isnot [PSMapNode])  { $this.WarnSelector($Node, $Name) }
                }
                elseif ($Name -is [Int]) {
                    if ($Node.ValueType.IsGenericType -and $Node.ValueType.GetGenericArguments()[0].Name -eq 'String') { $this.WarnSelector($Node, $Name) }
                }
                else {
                    if ($Node -isnot [PSMapNode]) {$this.WarnSelector($Node, $Name) }
                }
            }
            if ($Null -ne $Name) { $Node = $Node.GetChildNode($Name) } # Not sure yet whether $Null should selected the current node or the root node...
        }
        return $Node
    }

    [Collections.Generic.List[PSNode]]GetDescendentNodes() { return $this.GetDescendentNodes(0) }
    hidden [Object]get_ChildNodes()      { return ,[PSNode[]]@($this.GetDescendentNodes(0)) }
    hidden [Object]get_DescendantNodes() { return ,[PSNode[]]@($this.GetDescendentNodes(-1)) }
    hidden [Object]_($Name)              { return $this.GetChildNode($Name) }       # CLI Shorthand ("alias") for GetChildNode (don't use in scripts)
    hidden [Object]Get($Path)            { return $this.GetDescendentNode($Path) }  # CLI Shorthand ("alias") for GetDescendentNode (don't use in scripts)
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

    [Collections.Generic.List[PSNode]]GetDescendentNodes([Int]$Levels) {
        $List = [Collections.Generic.List[PSNode]]::new()
        if (-not $this.MaxDepthReached()) {
            for ($Index = 0; $Index -lt $this._Value.Get_Count(); $Index++) {
                $Node = $this.Append($this._Value[$Index])
                $Node._NodeOrigin = 'List'
                $Node._Name = $Index
                $List.Add($Node)
                if ($Levels -ne 0 -and $Node -is [PSCollectionNode]) {
                    $list.AddRange($Node.GetDescendentNodes($Levels - 1))
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
        $Node._NodeOrigin = 'List'
        $Node._Name = $Index
        return $Node
    }

    [Int]GetHashCode() {
        $HashCode = '@()'.GetHashCode()
        foreach ($Node in $this.GetDescendentNodes(-1)) {
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
        foreach ($Node in $this.GetDescendentNodes(-1)) {
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

    [Collections.Generic.List[PSNode]]GetDescendentNodes([Int]$Levels) {
        $List = [Collections.Generic.List[PSNode]]::new()
        if (-not $this.MaxDepthReached()) {
            foreach($Key in $this._Value.get_Keys()) {
                $Node = $this.Append($this._Value[$Key])
                $Node._NodeOrigin = 'Map'
                $Node._Name = $Key
                $List.Add($Node)
                if ($Levels -ne 0 -and $Node -is [PSCollectionNode]) {
                    $list.AddRange($Node.GetDescendentNodes(($Levels - 1)))
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
        $Node._NodeOrigin = 'Map'
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

    [Collections.Generic.List[PSNode]]GetDescendentNodes([Int]$Levels) {
        $List = [Collections.Generic.List[PSNode]]::new()
        if (-not $this.MaxDepthReached()) {
            foreach($Property in $this._Value.PSObject.Properties) {
                $Node = $this.Append($Property.Value)
                $Node._NodeOrigin = 'Map'
                $Node._Name = $Property.Name
                $List.Add($Node)
                if ($Levels -ne 0 -and $Node -is [PSCollectionNode]) {
                    $list.AddRange($Node.GetDescendentNodes($Levels - 1))
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
        $Node._NodeOrigin = 'Map'
        $Node._Name = $Name
        return $Node
    }
}

Use-ClassAccessors -Force

Update-TypeData -TypeName PSNode -DefaultDisplayPropertySet PathName, Name, Depth, Value -Force
