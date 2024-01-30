## 2024-01-29 0.0.12 (iRon)
  - Fixes
    - #31 "ComponentModel.Component does not parse correctly"

  - Enhancements
    - Improved `PathName` property performance

## 2024-01-27 0.0.11 (iRon)
  - Break changes
    - rename `-LeafNode` parameter from `Get-ChildNode` to just `-Leaf` to be consistent with `-ListChild`considering that the word `Node` is al ready in the cmdlet noun.

  - Enhancements
    - Object parser: uniform `MaxDepth` property (might only be set at the root node)
    - Object parser: added: `GetDescendentNode(<path>)` (alias: `Get(<path>)`) method
    - Object parser: added [help](https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md)
    - Get-ChildNode: Added `-Path` parameter
    - Get-ChildNode: Added `-AtDepth` parameter
    - Get-ChildNode: Added `-IncludeSelf` parameter


## 2023-01-25 0.0.10 (iRon)
  - Break changes
    - Single property `Name` for both list `Index` and map `Key`

  - Enhancements
    - Included class accessor support: https://github.com/iRon7/Use-ClassAccessors
      - Add (readonly) properties as e.g. `Type`
      - Ability to change the embedded object property from the `Value` property
    - Default display names: `Path`, `Name`, `Depth`, `Value`
