<!-- markdownlint-disable MD033 -->
# Object Parser

This class provides general properties and method to recursively
iterate through to PowerShell Object Graph nodes.

## Example "Iterate trough each recursive node and return it property path"

The following function recursively iterates through all the property nodes (`PSNodes`)
of an object-graph and returns the path to each object.

```PowerShell
function Iterate([PSNode]$Node) { # Basic iterator
    $Node.Path
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

Defines whether the parent node is a list (`[PSListNode]` type) or a map (`[PSMapNode]` type).
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

Returns a `PSNodePath` object that the PSNode path starting from the root PSNode
up and till the current PSNode. By default the `Path` class will act like a string
but in fact, it contains all the nodes: `$Node.Path.Nodes`.

### `PathName` (ReadOnly)

> [!Caution]
> The `PathName` property has been deprecated.
> Use `[String]$Node.Path` or `$Node.GetPathName('$Object')` instead.

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