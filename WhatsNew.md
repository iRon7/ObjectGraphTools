## 2024-02-22 0.0.19 (iRon)
  - Fixed
    - `ConvertTo-Expression` adding `$Null` entries

  - Enhancements
    - Use reflection for `Use-ClassAccessors`, see: https://github.com/iRon7/Use-ClassAccessors/issues/4

## 2024-02-22 0.0.18 (iRon)
  - Break changes (fixes)
    - Changed naming Descendent --> Descendant
    - Remove leading dot from `PathName`, use: `.GetPathName('$MyObject')` or `.GetPathName('')` to get a relative path
    - Depleted `.GetDescendantNode(<Path>)`, use: `.GetNode(<XdnPath>)`

  - Fixed
    - #17 The call to MergeObject used incorrect `Depth` parameter
    - #46 Sort-ObjectGraph: Out of range error

  - Enhancements
    - Increased: [PSNode]::DefaultMaxDepth = 20
    - Prerelease: Extended-Dot-Notation Path (`XdnPath` Class)
    - Prerelease: ConvertTo-Expression (based on `PSNode` class)

## 2024-02-04 0.0.16 (iRon)
  - Fixed
    - #40 Numeric keys don't convert to PSCustomObject

  - Enhancements
    - Add Windows&Core test

## 2024-02-01 0.0.15 (iRon)
  - Break changes
    - (compared to 0.0.14) removed `Get-NodeWhere` cmdlet as it appears easier to use `Where-Object` on a leaf node and select its parent

  - Fixed
    - #20 Compare-ObjectGraph seems to be case sensitive, even when not using the MatchCase parameter
    - #23 #Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}
    - #38 Some methods as get_MaxDepth and get_Name supposed to be hidden

## 2024-01-30 0.0.14 (iRon)
  - Fixes
    - #36 Multiple `Get-ChildNode -Include` and `-Exclude` pattern don't work

  - Enhancements
    - if `$MaxDepth` (in `[PSNode]::ParseInput($InputObject, $MaxDepth)`) is 0 or less, the current/default maximum depth is used.
    - Added [`Get-NodeWhere` cmdlet](./Docs/Get-NodeWhere.md)

## 2024-01-30 0.0.13 (iRon)
  - Fixes
    - If no path is supplied for the `Get-Node` cmdlet, the root node is returned

  - Enhancements
    - Get-Node: Added (commented) [help](./Docs/Get-Node.md)
    - Get-ChildNode: Added (commented) [help](./Docs/Get-ChildNode.md)

## 2024-01-29 0.0.12 (iRon)
  - Fixes
    - #31 ComponentModel.Component does not parse correctly

  - Enhancements
    - Improved `PathName` property performance

## 2024-01-27 0.0.11 (iRon)
  - Break changes
    - rename `-LeafNode` parameter from `Get-ChildNode` to just `-Leaf` to be consistent with `-ListChild`considering that the word `Node` is al ready in the cmdlet noun.

  - Enhancements
    - Object parser: uniform `MaxDepth` property (might only be set at the root node)
    - Object parser: added: `GetDescendentNode(<path>)` (alias: `Get(<path>)`) method
    - Object parser: added [help](./Docs/ObjectParser.md)
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
