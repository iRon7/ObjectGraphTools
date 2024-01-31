<!-- markdownlint-disable MD033 -->
# Get-NodeWhere

Get node where

## Syntax

```PowerShell
Get-NodeWhere
    [-InputNode <PSObject>]
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -FilterScript <ScriptBlock>
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CContains
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CEQ
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -NE
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CNE
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -GT
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CGT
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -LT
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CLT
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -GE
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CGE
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -LE
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CLE
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -Like
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CLike
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -NotLike
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CNotLike
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -Match
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CMatch
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -NotMatch
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CNotMatch
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -Contains
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    [-EQ]
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -NotContains
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CNotContains
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -In
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CIn
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -NotIn
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -CNotIn
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -Is
    [<CommonParameters>]
```

```PowerShell
Get-NodeWhere
    -Property <String>
    [-Value <Object>]
    -IsNot
    [<CommonParameters>]
```

## Description

Selects nodes from a object or `[PSNode]` collection based on their property values.

This cmdlet is based on the native `Microsoft.PowerShell.Core\Where-Object` cmdlet.
It differs in the fact that it a returns a collection of [`PSNode`][1] instances where the condition is applied on the embedded object value contained by a supplied input nodes.

## Parameter

### <a id="-inputnode">**`-InputNode <PSObject>`**</a>

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-filterscript">**`-FilterScript <ScriptBlock>`**</a>

Specifies the script block that's used to filter the nodes by its contained value. Enclose the script block in braces (`{}`).

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-property">**`-Property <String>`**</a>

Specifies the name of an node value property. The parameter name, `-Property`, is optional.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-value">**`-Value <Object>`**</a>

Specifies a property value of the node's embedded object value. The parameter name, `-Value`, is optional. This parameter accepts wildcard characters when used with the following comparison parameters:

* [-CLike](#-clike)
* [-CNotLike](#-cnotlike)
* [-Like](#-like)
* [-NotLike](#-notlike)

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-eq">**`-EQ`**</a>

Indicates that this cmdlet gets nodes if the value property is the same as the specified value.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ceq">**`-CEQ`**</a>

Indicates that this cmdlet gets nodes if the value property is the same as the specified value. This operation is case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ne">**`-NE`**</a>

Indicates that this cmdlet gets nodes if the value property is different than the specified value.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cne">**`-CNE`**</a>

Indicates that this cmdlet gets nodes if the value property is different than the specified value. This operation is case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-gt">**`-GT`**</a>

Indicates that this cmdlet gets nodes if the value property is greater than the specified value.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cgt">**`-CGT`**</a>

Indicates that this cmdlet gets nodes if the value property is greater than the specified value. This operation is case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-lt">**`-LT`**</a>

Indicates that this cmdlet gets nodes if the value property is less than the specified value.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-clt">**`-CLT`**</a>

Indicates that this cmdlet gets nodes if the value property is less-than the specified value. This operation is case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ge">**`-GE`**</a>

Indicates that this cmdlet gets nodes if the value property is greater than or equal to the specified value.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cge">**`-CGE`**</a>

Indicates that this cmdlet gets nodes if the value property is greater than or equal to the specified value. This operation is case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-le">**`-LE`**</a>

Indicates that this cmdlet gets nodes if the value property is less than or equal to the specified value.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cle">**`-CLE`**</a>

Indicates that this cmdlet gets nodes if the value property is less-than or equal to the specified value. This operation is case-sensitive.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-like">**`-Like`**</a>

Indicates that this cmdlet gets node if the value property matches a value that includes wildcard characters (*).

For example: `... | Get-NodeWhere Name -Like "*Joe"`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-clike">**`-CLike`**</a>

Indicates that this cmdlet gets nodes if the value property matches a value that includes wildcard characters (*). This operation is case-sensitive.

For example: `... | Get-NodeWhere Name -CLike Joe*`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-notlike">**`-NotLike`**</a>

Indicates that this cmdlet gets nodes if the value property doesn't match a value that includes wildcard characters (*).

For example: `... | Get-NodeWhere Name -NotLike "Joe*"`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cnotlike">**`-CNotLike`**</a>

Indicates that this cmdlet gets nodes if the value property doesn't match a value that includes wildcard characters. This operation is case-sensitive.

For example: `... | Get-NodeWhere Name -CNotLike "*Joe"`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-match">**`-Match`**</a>

Indicates that this cmdlet gets nodes if the value property matches the specified regular expression. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

For example: `... | Get-NodeWhere Name -Match "Joe/d*"`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cmatch">**`-CMatch`**</a>

Indicates that this cmdlet gets nodes if the value property matches the specified regular expression. This operation is case-sensitive. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

For example: `... | Get-NodeWhere Name -CMatch 'Joe\d*'`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-notmatch">**`-NotMatch`**</a>

Indicates that this cmdlet gets nodes when the value property value doesn't match the specified regular expression. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

For example: `... | Get-NodeWhere Name -NotMatch "Joe/d*"`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cnotmatch">**`-CNotMatch`**</a>

Indicates that this cmdlet gets nodes if the value property doesn't match the specified regular expression. This operation is case-sensitive. When the input is a single node, the matched value is saved in the `$Matches` automatic variable.

For example: `... | Get-NodeWhere Name -CNotMatch "Joe/d*"`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-contains">**`-Contains`**</a>

Indicates that this cmdlet gets nodes if any item in the value property of the object is an exact match for the specified value.

For example: `...| Get-NodeWhere Name -Contains Joe`

If the input is a single node, PowerShell converts it to a collection of one node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-ccontains">**`-CContains`**</a>

Indicates that this cmdlet gets nodes from a collection if the property value of the node is an exact match for the specified value. This operation is case-sensitive.

For example: `...| Get-NodeWhere Name -CContains Joe`

`CContains` refers to a collection of values and is true if the collection contains a node value property that is an exact match for the specified value.
If the node is a single object, PowerShell converts it to a collection of one node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-notcontains">**`-NotContains`**</a>

Indicates that this cmdlet gets nodes if none of the items in the value property is an exact match for the specified value.

For example: `... | Get-NodeWhere Name -NotContains Joe`

`NotContains` refers to a collection of values and is true if the collection doesn't contain any items that are an exact match for the specified value. If the input is a single node, PowerShell converts it to a collection of one node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cnotcontains">**`-CNotContains`**</a>

Indicates that this cmdlet gets nodes if the value property of the object isn't an exact match for the specified value. This operation is case-sensitive.

For example: `... | Get-NodeWhere Name -CNotContains Joe`

`NotContains` and `CNotContains` refer to a collection of nodes and are true when the collection doesn't contain any node items that are an exact match for the specified value. If the input is a single node, PowerShell converts it to a collection of one node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-in">**`-In`**</a>

Indicates that this cmdlet gets nodes if the value property matches any of the specified values. For example:

```PowerShell
... | Get-NodeWhere -Property Name -in -Value "Joe", "John", "iRon"
```

If the input is a single node, PowerShell converts it to a collection of one node.

If the value property of a node is an array, PowerShell uses reference equality to determine a match. `Get-NodeWhere` returns the node only if the value of the **Property** parameter and any value of the embedded **value property** are the same instance of a node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cin">**`-CIn`**</a>

Indicates that this cmdlet gets nodes if the value property includes the specified value. This operation is case-sensitive.

For example: `... | Get-NodeWhere -Value Joe -CIn Name`

[CIn](#cin) resembles [CContains](#ccontains), except that the property and value positions are reversed. For example, the following statements are both true.

```PowerShell
"abc", "def" -CContains "abc"

"abc" -CIn "abc", "def"
```

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-notin">**`-NotIn`**</a>

Indicates that this cmdlet gets nodes if the value property isn't an exact match for any of the specified values.

For example: `... | Get-NodeWhere -Value Joe -NotIn -Property Name`

If the value of Value is a single node, PowerShell converts it to a collection of one node.

If the value property of an node is an array, PowerShell uses reference equality to determine a match. `Get-NodeWhere` returns the node only if the value of the **Property** parameter and any value of the embedded **value property** are the same instance of a node.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-cnotin">**`-CNotIn`**</a>

Indicates that this cmdlet gets nodes if the value property isn't an exact match for the specified value. This operation is case-sensitive.

For example: `... | Get-NodeWhere -Value "Joe" -CNotIn -Property Name`

`NotIn` and `CNotIn` operators resemble `NotContains` and `CNotContains`, except that the property and value positions are reversed. For example, the following statements are true.

```PowerShell
"abc", "def" -CNotContains "Abc"

"abc" -CNotIn "Abc", "def"
```

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-is">**`-Is`**</a>

Indicates that this cmdlet gets nodes if the value property is an instance of the specified .NET type. Enclose the type name in square brackets.

For example: `... | Get-NodeWhere StartTime -Is [DateTime]`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-isnot">**`-IsNot`**</a>

Indicates that this cmdlet gets nodes if the value property isn't an instance of the specified .NET type.

For example: `... | Get-NodeWhere StartTime -IsNot [DateTime]`

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Related Links

* 1: [PowerShell Object Parser][1]

[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
