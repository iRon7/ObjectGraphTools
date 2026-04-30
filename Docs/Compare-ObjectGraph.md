<!-- markdownlint-disable MD033 -->
# Compare-ObjectGraph

Compare Object Graph

## Syntax

```PowerShell
Compare-ObjectGraph
    -InputObject <Object>
    -Reference <Object>
    [-PrimaryKey <String[]>]
    [-IsEqual]
    [-MatchCase]
    [-MatchType]
    [-IgnoreListOrder]
    [-MatchMapOrder]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Deep compares two Object Graph and lists the differences between them.

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The input object that will be compared with the reference object (see: [`-Reference`](#-reference) parameter).

> [!NOTE]
> Multiple input object might be provided via the pipeline.
> The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
> To avoid a list of (root) objects to unroll, use the **comma operator**:

```PowerShell
,$InputObject | Compare-ObjectGraph $Reference.
```

```powershell
Name:                       -InputObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-reference">`-Reference` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The reference that is used to compared with the input object (see: [`-InputObject`](#-inputobject) parameter).

```powershell
Name:                       -Reference
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-primarykey">`-PrimaryKey` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">&lt;String[]&gt;</a></a>

If supplied, dictionaries (including PSCustomObject or Component Objects) in a list are matched
based on the values of the `-PrimaryKey` supplied.

```powershell
Name:                       -PrimaryKey
Aliases:                    # None
Type:                       [String[]]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-isequal">`-IsEqual`</a>

If set, the cmdlet will return a boolean (`$true` or `$false`).
As soon a Discrepancy is found, the cmdlet will immediately stop comparing further properties.

```powershell
Name:                       -IsEqual
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-matchcase">`-MatchCase`</a>

Unless the `-MatchCase` switch is provided, string values are considered case insensitive.

> [!NOTE]
> Dictionary keys are compared based on the `$Reference`.
> if the `$Reference` is an object (PSCustomObject or component object), the key or name comparison
> is case insensitive otherwise the comparer supplied with the dictionary is used.

```powershell
Name:                       -MatchCase
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-matchtype">`-MatchType`</a>

Unless the `-MatchType` switch is provided, a loosely (inclusive) comparison is done where the
`$Reference` object is leading. Meaning `$Reference -eq $InputObject`:

```PowerShell
'1.0' -eq 1.0 # $false
1.0 -eq '1.0' # $true (also $false if the `-MatchType` is provided)
```

```powershell
Name:                       -MatchType
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-ignorelistorder">`-IgnoreListOrder`</a>

```powershell
Name:                       -IgnoreListOrder
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-matchmaporder">`-MatchMapOrder`</a>

By default, items in dictionary (including properties of an PSCustomObject or Component Object) are
matched by their key name (independent of the order).
If the `-MatchMapOrder` switch is supplied, each entry is also validated by the position.

> [!NOTE]
> A `[HashTable]` type is unordered by design and therefore, regardless the `-MatchMapOrder` switch,
the order of the `[HashTable]` (defined by the `$Reference`) are always ignored.

```powershell
Name:                       -MatchMapOrder
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-maxdepth">`-MaxDepth` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">&lt;Int32&gt;</a></a>

The maximal depth to recursively compare each embedded property (default: 10).

```powershell
Name:                       -MaxDepth
Aliases:                    -Depth
Type:                       [Int32]
Value (default):            [PSNode]::DefaultMaxDepth
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
