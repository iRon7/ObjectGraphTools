<!-- markdownlint-disable MD033 -->
# Copy-ObjectGraph

Copy object graph

## Syntax

```PowerShell
Copy-ObjectGraph
    -InputObject <Object>
    [-ListAs <Object>]
    [-MapAs <Object>]
    [-ExcludeLeafs]
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Recursively ("deep") copies a object graph.

## Examples

### <a id="example-1"><a id="example-deep-copy-a-complete-object-graph-into-a-new-object-graph">Example 1: Deep copy a complete object graph into a new object graph</a></a>


```PowerShell
$NewObjectGraph = Copy-ObjectGraph $ObjectGraph
```

### <a id="example-2"><a id="example-copy-convert-an-object-graph-using-common-powershell-arrays-and-pscustomobjects">Example 2: Copy (convert) an object graph using common PowerShell arrays and PSCustomObjects</a></a>


```PowerShell
$PSObject = Copy-ObjectGraph $Object -ListAs [Array] -DictionaryAs PSCustomObject
```

### <a id="example-3"><a id="example-convert-a-json-string-to-an-object-graph-with-case-insensitive-ordered-dictionaries">Example 3: Convert a Json string to an object graph with (case insensitive) ordered dictionaries</a></a>


```PowerShell
$PSObject = $Json | ConvertFrom-Json | Copy-ObjectGraph -DictionaryAs ([Ordered]@{})
```

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

The input object that will be recursively copied.

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

### <a id="-listas">`-ListAs` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

If supplied, lists will be converted to the given type (or type of the supplied object example).

```powershell
Name:                       -ListAs
Aliases:                    -ArrayAs
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-mapas">`-MapAs` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

```powershell
Name:                       -MapAs
Aliases:                    -DictionaryAs
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-excludeleafs">`-ExcludeLeafs`</a>

If supplied, only the structure (lists, dictionaries, [`PSCustomObject`][1] types and [`Component`][2] types will be copied.
If omitted, each leaf will be shallow copied

```powershell
Name:                       -ExcludeLeafs
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

## Related Links

* [PSCustomObject Class](https://learn.microsoft.com/dotnet/api/system.management.automation.pscustomobject)
* [Component Class](https://learn.microsoft.com/dotnet/api/system.componentmodel.component)
<!-- -->


[1]: https://learn.microsoft.com/dotnet/api/system.management.automation.pscustomobject "PSCustomObject Class"
[2]: https://learn.microsoft.com/dotnet/api/system.componentmodel.component "Component Class"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
