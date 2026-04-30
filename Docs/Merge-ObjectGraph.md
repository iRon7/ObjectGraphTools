<!-- markdownlint-disable MD033 -->
# Merge-ObjectGraph

Merges two object graphs into one

## Syntax

```PowerShell
Merge-ObjectGraph
    -InputObject <Object>
    -Template <Object>
    [-PrimaryKey <String[]>]
    [-MatchCase]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Recursively merges two object graphs into a new object graph.

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The input object that will be merged with the template object (see: [`-Template`](#-template) parameter).

> [!NOTE]
> Multiple input object might be provided via the pipeline.
> The common PowerShell behavior is to unroll any array (aka list) provided by the pipeline.
> To avoid a list of (root) objects to unroll, use the **comma operator**:

```PowerShell
,$InputObject | Compare-ObjectGraph $Template.
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

### <a id="-template">`-Template` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The template that is used to merge with the input object (see: [`-InputObject`](#-inputobject) parameter).

```powershell
Name:                       -Template
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

In case of a list of dictionaries or PowerShell objects, the PowerShell key is used to
link the items or properties: if the PrimaryKey exists on both the [`-Template`](#-template) and the
[`-InputObject`](#-inputobject) and the values are equal, the dictionary or PowerShell object will be merged.
Otherwise (if the key can't be found or the values differ), the complete dictionary or
PowerShell object will be added to the list.

It is allowed to supply multiple primary keys where each primary key will be used to
check the relation between the [`-Template`](#-template) and the [`-InputObject`](#-inputobject).

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

### <a id="-matchcase">`-MatchCase`</a>

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

### <a id="-maxdepth">`-MaxDepth` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">&lt;Int32&gt;</a></a>

The maximal depth to recursively compare each embedded node.
The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

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
