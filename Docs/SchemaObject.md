# Schema Object

### Definition

A schema object is a PowerShell object used by the [`Test-Object`][1] cmdlet to validate any PowerShell - or
.Net object. The schema object has the following major features:

* Independent of the object notation (as e.g. [Json (JavaScript Object Notation)][2] or [PowerShell Data Files][3])
* Each test node is at the same level as the input node being validated
* Complex node requirements (as mutual exclusive nodes) might be selected using a logical formula

## Test nodes

Each recursive test node in the schema object describes the input node at the same level in the input object.
There are two types of test nodes items:
1. Assert nodes
2. Child nodes

By default, each assert node is prefixed by a single at-sign (`@`) and defines the constrains of the input node
value (see [assert nodes](#Assert-nodes) for more details). Any other node object in the test node collection
further defines any child nodes in the schema object branch (see [child nodes](#Child-nodes) for more details).

## Child nodes

Any test node property that has no assert node prefix (by default, a single at-sign `@`) is considered a child node
definition. This might be a **collection which directly defines** the constrains of the opposite child node from
the input object or a **scalar (usually a string type) that indirectly references** a test definition in any of
the ancestors's [`@References`](#@References) assert nodes.
The child node collection might be any collection or [PSCustomObject][4], meaning a list node (`[PSListNode]`) or
a mapping node, where a dictionary node or an object node are treated equally under the `[PSMapNode]` type.
For details on the `[PSNode]` structure and members, see the [object parser][5].
By default, a child node **list** (`[PSListNode]`) at the schema side expects a child node **list** at the input
object side and a child node **mapping** (`[PSMapNode]`) at the schema side expects a child node **mapping** at
the input object side, but this might be overruled by the [`@Type`](#@Type) assert node. If a **mapping** child
node collection is used against a **mapping** type, the node is **validated *by name***. This means that each child
node at the input object side is validated against each each child node at the schema object based on its name.
In any other situation (where the child node collection at the input object side or schema object side is a
**list**), the node is **validated *by value***, the condition defined in the **value** of the schema node is used
to validate the **value** input node.

| input node | test node | validation |
| ---------- | --------- | ---------- |
| map        | map       | by name    |
| list       | list      | by value   |
| list       | map       | by value   |
| map        | list      | n/a        |

> [!TIP]
> Validating a **input list node** with a **test mapping node**, might come at hand when defining a list of
> required nodes (see: the [`@RequiredNodes`](#@RequiredNodes) assert node).

> [!NOTE]
> Validating a **input mapping node** with a **test list node** isn't possible as a **test list node** can't
> contain a `@Type` assert to overrule a list with a mapping type.

> [!WARNING]
> Validating optional nodes **by value** might get expensive as each *decedents* input node value is validated
> against the given test node condition.

## Assert nodes

The list of existing assert nodes is limited to:
* `AssertTestPrefix`
* `@Description`
* `@References`
* `@Type`
* `@NotType`
* `@CaseSensitive`
* `@Required`
* `@Unique`
* `@ExclusiveMaximum`
* `@Maximum`
* `@ExclusiveMinimum`
* `@Minimum`
* `@Like`
* `@Match`
* `@NotLike`
* `@NotMatch`
* `@Ordered`
* `@RequiredNodes`
* `@AllowExtraNodes`

* Each assert node describes or constrains the allowed opposite input object node or value as follows:

#### `AssertTestPrefix`

By default, each assert node is prefixed by a single at-sign (`@`) and defines the constrains of the input node
value (see [assert nodes](#Assert-nodes) for more details). Any other node object in the test node collection
further defines any child nodes in the schema object branch (see [child nodes](#Child-nodes) for more details).

> [!NOTE]
> This "assert node" directive is only accepted at the top level of the schema object and is used to determine
> the test node prefix for all other assert nodes. The name of this "assert node" directive might be overruled
> by the `Test-Object -AssertTestPrefix` cmdlet parameter.

| Name        | AssertTestPrefix                              |
| ----------- | --------------------------------------------- |
| Description | Defines the assert prefix of each assert node |
| Type        | `String`                                      |
| Default     | `"@"`                                         |
| Applies to  | Assert test name                              |

#### `Description`

Defines the Description of the test node and has no further meaning.

| Name        | @Description            |
| ----------- | ----------------------- |
| Description | Describes the test node |
| Type        | `String`                |
| Default     |                         |
| Applies to  | Test node               |

#### `References`

The `@References` assert node contains a map of references which might be used for repeating or recursive child
nodes. Each reference is defined as follows:

```PowerShell
@References = @{
    <reference name> = <test node definition>
}
```

**example:**
This example shows a schema object with an `Id` and  `Address` reference:

```PowerShell
@{
    '@References' = @{
        Id = @{ '@Type' = 'String'; '@Match' = 'ID\d{6}' }
        Address = @{
            '@Type' = [PSMapNode]
            Street     = @{ '@Type' = 'String' }
            City       = @{ '@Type' = 'String' }
            State      = @{ '@Type' = 'String' }
            PostalCode = @{ '@Type' = 'String' }
        }
    }
}
```

| Name        | @References                          |
| ----------- | ------------------------------------ |
| Description | Contains a list of assert references |
| Type        | `PSMapNode`                          |
| Default     |                                      |
| Applies to  | Test child node                      |

#### `Type`

Tests whether the value or the node (derived from `[PSNode]`) is of a certain type.
The value of the `@Type` assert might contain multiple types where the input node matches any of the types.
The value might be a runtime type (`[<typename>]`), any other type value will be considered to be a string
representing the required type.
A `$null` or an empty value might be defined as `$null`, `[null]` (`'null'`) or `[void]` (`'void'`).

**example:**

```PowerShell
@{
    MiddleName = @{ '@Type' = $Null, 'String' } # The middle name might be $null or a string
}
```

| Name        | @Type                        |
| ----------- | ---------------------------- |
| Description | The node or value is of type |
| Type        | `String[]` or `Type[]`       |
| Default     |                              |
| Applies to  | Value or node                |

#### `NotType`

Tests whether the value or the node (derived from `[PSNode]`) is *not* of a certain type.
The value of the `@Type` assert might contain multiple types where the input node should *not* match any of the types.
The value might be a runtime type (`[<typename>]`), any other type value will be considered to be a string
representing the required type.
A `$null` or an empty value might be defined as `$null`, `[null]` (`'null'`) or `[void]` (`'void'`).

**example:**

```PowerShell
@{
    MoreNodes = @{ '@NotType' = [PSLeafNode] } # The node should contain more child nodes
}
```

| Name        | @NotType                         |
| ----------- | -------------------------------- |
| Description | The node or value is not of type |
| Type        | `String[]` or `Type[]`           |
| Default     |                                  |
| Applies to  | Value or node                    |

#### `CaseSensitive`

When set, the current node and any decedent node values are considered case sensitive.

> [!NOTE]
> This only applies to the value of the nodes that are validated against `@ExclusiveMaximum`, `@Maximum`,
> `@ExclusiveMinimum`, `@Minimum`, `@Like`, `@Match`, `@NotLike` `@NotMatch` or `@Unique` values.
> The case sensitivity of dictionary key name is determined by the comparer of the test node dictionary.

**example:**

```PowerShell
@{
    '@CaseSensitive' = $true
    Id = @{ '@Match' = '^ID\d{6}$' } # The ID###### value is case sensitive
}
```

| Name        | @CaseSensitive                                             |
| ----------- | ---------------------------------------------------------- |
| Description | The (descendant) node values are considered case sensitive |
| Type        | `Bool`                                                     |
| Default     | `False` (Case insensitive)                                 |
| Applies to  | Test assert that apply to values                           |

#### `Required`

When set, the specific node is required. If the parent node has already a [`@RequiredNodes`](#@RequiredNodes)
assert node, the specific required nodes are added (`and`) to the required nodes (`@RequiredNodes`) definition.

**example:**

```PowerShell
@{
    Id = @{ '@Match' = '^ID\d{6}$'; '@Required' = $true } # The ID node is a required
}
```

| Name        | @Required            |
| ----------- | -------------------- |
| Description | The node is required |
| Type        | `Bool`               |
| Default     | `False` (optional)   |
| Applies to  | Node                 |

#### `Unique`

When set, the specific node *value* is unique. meaning that none of the sibling nodes should contain the same
value.

> [!WARNING]
> Validating whether a unique node is unique might get expensive as each sibling and its *decedents* is tested
> against the input node value.

| Name        | @Unique            |
| ----------- | ------------------ |
| Description | The node is unique |
| Type        | `Bool`             |
| Default     | `False`            |
| Applies to  | Node               |

#### `Minimum`

Defines the minimum allowed value of a node (including the minimum value).

**example:**

```PowerShell
@{
    Age = @{ '@Type' = [Int]; '@ExclusiveMinimum' = 16; '@Maximum' = 99 } # Define an age range
}
```

| Name        | @Minimum                                                          |
| ----------- | ----------------------------------------------------------------- |
| Description | The minimum allowed value of a node (including the minimum value) |
| Type        | `Int`                                                             |
| Default     |                                                                   |
| Applies to  | Value                                                             |

#### `ExclusiveMinimum`

Defines the minimum allowed value of a node (excluding the minimum value).

| Name        | @ExclusiveMinimum                                                 |
| ----------- | ----------------------------------------------------------------- |
| Description | The minimum allowed value of a node (excluding the minimum value) |
| Type        | `Int`                                                             |
| Default     |                                                                   |
| Applies to  | Value                                                             |

#### `ExclusiveMaximum`

Defines the maximum allowed value of a node (excluding the maximum value).

| Name        | @ExclusiveMaximum                                                 |
| ----------- | ----------------------------------------------------------------- |
| Description | The minimum allowed value of a node (excluding the maximum value) |
| Type        | `Int`                                                             |
| Default     |                                                                   |
| Applies to  | Value                                                             |

#### `Maximum`

Defines the maximum allowed value of a node (including the maximum value).

| Name        | @Maximum                                                          |
| ----------- | ----------------------------------------------------------------- |
| Description | The minimum allowed value of a node (including the maximum value) |
| Type        | `Int`                                                             |
| Default     |                                                                   |
| Applies to  | Value                                                             |

#### `MinimumLength`

Defines the minimum allowed (converted to) string length of the node value.

| Name        | @MinimumLength                                   |
| ----------- | ------------------------------------------------ |
| Description | The minimum allowed (converted to) string length |
| Type        | `Int`                                            |
| Default     |                                                  |
| Applies to  | (Scalar) value                                   |

#### `Length`

Defines the (converted to) string length of the node value.

| Name        | @Length                                |
| ----------- | -------------------------------------- |
| Description | The exact (converted to) string length |
| Type        | `Int`                                  |
| Default     |                                        |
| Applies to  | (Scalar) value                         |

#### `MaximumLength`

Defines the minimum allowed (converted to) string length of the node value.

| Name        | @MaximumLength                                   |
| ----------- | ------------------------------------------------ |
| Description | The maximum allowed (converted to) string length |
| Type        | `Int`                                            |
| Default     |                                                  |
| Applies to  | (Scalar) value                                   |

#### `MinimumCount`

Defines the minimum allowed (converted to) string length of the node value.

| Name        | @MinimumCount                        |
| ----------- | ------------------------------------ |
| Description | The minimum allowed collection count |
| Type        | `Int`                                |
| Default     |                                      |
| Applies to  | Collection                           |

#### `Count`

Defines the allowed (converted to) string length of the node value.

| Name        | @Count                             |
| ----------- | ---------------------------------- |
| Description | The exact allowed collection count |
| Type        | `Int`                              |
| Default     |                                    |
| Applies to  | Collection                         |

#### `MaximumCount`

Defines the maximum allowed (converted to) string length of the node value.

| Name        | @MaximumCount                        |
| ----------- | ------------------------------------ |
| Description | The maximum allowed collection count |
| Type        | `Int`                                |
| Default     |                                      |
| Applies to  | Collection                           |

#### `Like`

The value of the input node should be like any of the values of this assert node.

**example:**

```PowerShell
@{
    CN = @{ '@Like' = 'PC_??????', 'User_??????' }
}
```

| Name        | @Like                         |
| ----------- | ----------------------------- |
| Description | The value is like the pattern |
| Type        | `String[]`                    |
| Default     |                               |
| Applies to  | Value                         |

#### `Match`

The value of the input node should match any of the values of this assert node.

**example:**

```PowerShell
@{
    EMail = @{ '@Match' = '^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})*$' }
}
```

| Name        | @Match                                   |
| ----------- | ---------------------------------------- |
| Description | The value matches the regular expression |
| Type        | `String[]`                               |
| Default     |                                          |
| Applies to  | Value                                    |

#### `NotLike`

The value of the input node should *not* be like any of the values of this assert node.

| Name        | @NotLike                          |
| ----------- | --------------------------------- |
| Description | The value is not like the pattern |
| Type        | `String[]`                        |
| Default     |                                   |
| Applies to  | Value                             |

#### `NotMatch`

The value of the input node should *not* match any of the values of this assert node.

| Name        | @NotMatch                                         |
| ----------- | ------------------------------------------------- |
| Description | The value does not matches the regular expression |
| Type        | `String[]`                                        |
| Default     |                                                   |
| Applies to  | Value                                             |

#### `Ordered`

The nodes in the input node collection should be in the same order as the child nodes (excluding the assert nodes)
in the test node collection.

| Name        | @Ordered               |
| ----------- | ---------------------- |
| Description | The nodes are in order |
| Type        | `Bool`                 |
| Default     | `False`                |
| Applies to  | Child nodes            |

#### `RequiredNodes`

Defines the required child nodes in node collection where the input collection could be either a list node
(`[PSListNode]`) or a mapping node (`[PSMapNode]`), see also [child nodes](#child-nodes). The value of the
`@RequiredNodes` assert might contain a list of nodes or a string containing a  **logical expression**
which the defines which node are required.

A **logical expression** recognizes the following operators:

* `And` (or `,` or `*`)
* `Or` (or `|` or `+`)
* `Xor`
* `Not` (or `|`)

* Any term in between is considered an operand (which refers to a name of a specific test node).
* Names with special characters might be single - or double quoted.
* Sub-expressions should be surrounded by parenthesis (`(...)`).

**example**

```PowerShell
@{
    EMail = @{ '@Match' = '^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})*$' }
    Phone = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
    '@RequiredNodes' = 'EMail or Phone' # The current object requires at least a valid EMail - or Phone node
}
```

> [!NOTE]
> Any test child node that isn't listed in the `@RequiredNodes` condition (even negated, as e.g.: `-Not NodeName`)
> is considered an optional node

> [!NOTE]
> Any specifically required child nodes (that have the `@Required` assert set) are added (`and`) to the list of
> required nodes (`@RequiredNodes`).

| Name        | @RequiredNodes                      |
| ----------- | ----------------------------------- |
| Description | List or formula with required nodes |
| Type        | `String[]`                          |
| Default     |                                     |
| Applies to  | Child nodes                         |

#### `AllowExtraNodes`

**Optional test nodes** are test nodes that are not covered in the [`@RequiredNodes`](#@RequiredNodes) condition
(even *negated*, as e.g.: `not NodeName`) or node that have the [`@Required`](#@Required) assert node set.

If the `@AllowExtraNodes` assert **is *not* set** (default, or `false`), the following applies:

* Each input node needs to match the required node condition
* The rest of the input nodes should match with *any* of the optional test nodes
* There should be no input nodes leftover from the required - or optional nodes

In case the `@AllowExtraNodes` assert **is set** (`true`), the following applies:
* Each input node needs to match the required node condition
* The rest of the input nodes are matched with *all* the optional test nodes
  * All test child nodes should be applied to the input node collection
* There should be no input nodes leftover from the required - or optional nodes

[!NOTE]
> If a value specific assert test is applied on a collection node (e.g. `@Match`), each input child node is
> validated against the test node condition and the `@AllowExtraNodes` assert node is automatically set.

| Name        | @AllowExtraNodes                   |
| ----------- | ---------------------------------- |
| Description | Additional child nodes are allowed |
| Type        | `Bool`                             |
| Default     | `False`                            |
| Applies to  | Child nodes                        |

## Compulsory list vs natural lists

In several implementations along with the [PowerShell pipeline][6] it is common that an array with a single item
"unrolls" in a scalar. It is possible to test for for either a **compulsory list** (even it contains a single item)
or test for an **natural list** in your schema accordingly:

Assuming the following input object:

```PowerShell
@{
    Word = 'Hello', 'World' # The Word node contains a list of two words
}
```

### compulsory list

To test for a list node even it contains a single item (meaning `@{ Word = @('Hello') }`):

```PowerShell
@{ Word = @(@{ '@Match' = '^\w+$' }) } # The Word node should contain a list of zero, one or multiple words
```

### natural list

To test for a list node that is allowed to unroll a single item (e.g. `@{ Word = 'Hello' }`):

```PowerShell
@{ Word = @{ '@Match' = '^\w+$' } } # The Word node might contain a list or a string
```

[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Test-Object.md "Test-Object cmdlet"
[2]: https://en.wikipedia.org/wiki/JSON "Json (JavaScript Object Notation"
[3]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_data_files "PowerShell Data Files"
[4]: https://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-pscustomobject "PSCustomObject"
[5]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "Object parser"
[6]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_pipelines "PowerShell pipeline"
