<!-- markdownlint-disable MD033 -->
# Invoke-SortObjectGraph

Sort an object graph

## Syntax

```PowerShell
Invoke-SortObjectGraph
    -InputObject <Object>
    [-PrimaryKey <String[]>]
    [-MatchCase]
    [-Descending]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Recursively sorts an object graph.

> [!WARNING](#warning)
> `Sort-ObjectGraph` is an alias for `Invoke-SortObjectGraph` but to avoid "unapproved verb" warnings during the
> module import a different cmdlet name used. See:
> [Give the script author the ability to disable the unapproved verbs warning][https://github.com/PowerShell/PowerShell/issues/25642]

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The input object that will be recursively sorted.

> [!NOTE](#note)
> Multiple input object might be provided via the pipeline.
> The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
> To avoid a list of (root) objects to unroll, use the **comma operator**:

```PowerShell
,$InputObject | Sort-Object.
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

### <a id="-primarykey">`-PrimaryKey` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String[]">&lt;String[]&gt;</a></a>

Any primary key defined by the [`-PrimaryKey`](#-primarykey) parameter will be put on top of [`-InputObject`](#-inputobject)
independent of the (descending) sort order.

It is allowed to supply multiple primary keys.

```powershell
Name:                       -PrimaryKey
Aliases:                    -By
Type:                       [String[]]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-matchcase">`-MatchCase`</a>

(Alias `-CaseSensitive`) Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

```powershell
Name:                       -MatchCase
Aliases:                    -CaseSensitive
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-descending">`-Descending`</a>

Indicates that Sort-Object sorts the objects in descending order. The default is ascending order.

> [!NOTE](#note)
> Primary keys (see: [`-PrimaryKey`](#-primarykey)) will always put on top.

```powershell
Name:                       -Descending
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
