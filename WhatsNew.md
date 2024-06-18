## 2024-05-04 0.1.6 (iRon)
  - Break changes
    - ConvertFrom-Expression parameters: `-ArrayAs` --> `-ListAs`, `-HashTableAs` --> `-MapAs`
    - Compare-ObjectGraph:
      - split `-MatchOrder` switch in `-IgnoreListOrder` and `-MatchMapOrder`

  - Enhancements
    - Created PSListNodeComparer and PSMapNodeComparer
    - Sorting and added <PSNode>.Sort() method
    - Improved GetHashCode() method

  - Implemented
    - #82 Phase out static GetPSNodeType method
    - #83 $ObjectGraph | Get-Node $PSNodePath should work
    - #84 PSNodePath should implement Equals (PSNodePath or String)

  - Documentation
    - Updated commented help of several cmdlets
    - #65 Update ObjectParser.md with respect to PathName deprecation documentation

## 2024-04-27 0.1.5 (iRon)
  - Fixes
    - #80 Unknown PSNode type (Import-Module issues)

## 2024-04-20 0.1.4 (iRon)
  - Fixes
    - Copy-ObjectGraph `-ListAs`/`-MapAs` parameter bug
    - #78 Copy-Object -MapAs @{} should not me case sensitive

  - Enhancements
    - Added `ConvertFrom-Expression` `-ArrayAs`/`-HashTableAs` parameters
    - Added `Import-ObjectGraph`
    - Added `Export-ObjectGraph`

## 2024-04-11 0.1.3 (iRon)
  - Enhancements
    - Added `ConvertFrom-Expression`
      - Also supporting a `-LanguageMode` parameter

## 2024-04-04 0.1.2 (iRon)
  - Enhancements
    - Full implementation of `ConvertTo-Expression`
      (still requires some code improvements with regards to hardcoded roundtrip properties)
      Improved performance and added parameters:
      `-LanguageMode` Restricted, Constrained, Full
      `-ExpandDepth` Expands up till this level (collapse the rest)
      `-Explicit` Add explicit type name
      `-FullTypeName` Use full type name
      `-HighFidelity` Explore all underlying properties
      `-ExpandSingleton` Expand collection nodes with a single item

## 2024-03-09 0.1.1 (iRon)
  - Fixes
    - #45 Improved internal nodes collector
    - #58 Fix issue where literal name is not found before `Equal` operator
    - #62 Parameter tables are not properly filled
    - #64 Update main Readme.md with Xdn
    - #65 Update ObjectParser.md with respect to PathName deprecation

## 2024-03-08 0.1.0 (iRon)
  - Break changes
    - #55 `Get-Node` retrieves no long the path but the Object/Node from the pipeline
    - #56 Removed -Path parameter from Get-ChildNode (Use: `<Object-Graph or PSNode> | Get-Node <XdnPath> | Get-ChildNode ...` )

  - Enhancements
    - Full **Extended dot notation** (`Xdn`) implementation (see: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Xdn.md)
    - #57 Added `-Literal` parameter to `Get-Node`
    - Added `Xdn` document
    - Added `Xdn` Tests
    - Added `[PSNodePath]` class for `[PSNode]$Node.Path`
    - Added `Get-Node` tests

  - Fixed
    - #59 ConvertTo-Expression quoting bug

## 2024-02-28 0.0.20 (iRon)
  - Fixed
    - `ConvertTo-Expression` adding `$Null` entries
    - #50 Copy-ObjectGraph -ListAs Array gives error
    - #51 Document (markdown) issue in: Copy-ObjectGraph.md (fixed `Get-MarkdownHelp`))

  - Enhancements
    - Improved .ChildNode and related properties by one-by-one collecting sub nodes
    - #53 return a warning (rather than an error) when Get-ChildNode is a leaf node

## 2024-02-26 0.0.19 (iRon)
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
