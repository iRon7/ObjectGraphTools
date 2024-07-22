Each schema definition requires at least one `map` node and a possible additional collection node to hold the child items.
This means:

* The validation of a **Leaf** node requires a single schema `map` node, e.g.:

```PowerShell
@{ Type = 'String' }
```

* The validation of a **list** node requires a single schema `map` node that contains an embedded `list` node named "**items**", e.g.:

```PowerShell
@{
    Type = 'Array'
    Items = @(
        ...
    )
}
```

* The validation of a **map** node requires a single schema `map` node that contains another embedded `map` node named "**items**", e.g.:

```PowerShell
@{
    Type = 'Array'
    Items = @{
        ...
    }
}
```

The object-graph schema depth required to describe every node in an given object requires `2 * (maximum object depth) - 1`.