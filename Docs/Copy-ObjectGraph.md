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

### Example 1: Deep copy a complete object graph into a new object graph


```PowerShell
$NewObjectGraph = Copy-ObjectGraph $ObjectGraph
```

### Example 2: Copy (convert) an object graph using common PowerShell arrays and PSCustomObjects


```PowerShell
$PSObject = Copy-ObjectGraph $Object -ListAs [Array] -DictionaryAs PSCustomObject
```

### Example 3: Convert a Json string to an object graph with (case insensitive) ordered dictionaries


```PowerShell
$PSObject = $Json | ConvertFrom-Json | Copy-ObjectGraph -DictionaryAs ([Ordered]@{})
```

## Parameters

### <a id="-inputobject">**`-InputObject <Object>`**</a>

The input object that will be recursively copied.

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-listas">**`-ListAs <Object>`**</a>

If supplied, lists will be converted to the given type (or type of the supplied object example).

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-mapas">**`-MapAs <Object>`**</a>

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">Object</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-excludeleafs">**`-ExcludeLeafs`**</a>

If supplied, only the structure (lists, dictionaries, [`PSCustomObject`][1] types and [`Component`][2] types will be copied.
If omitted, each leaf will be shallow copied

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter">SwitchParameter</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-maxdepth">**`-MaxDepth <Int32>`**</a>

<table>
<tr><td>Type:</td><td><a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">Int32</a></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[PSNode]::DefaultMaxDepth</code></td></tr>
<tr><td>Accept pipeline input:</td><td>False</td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Related Links

* 1: [PSCustomObject Class][1]
* 2: [Component Class][2]

[1]: https://learn.microsoft.com/dotnet/api/system.management.automation.pscustomobject "PSCustomObject Class"
[2]: https://learn.microsoft.com/dotnet/api/system.componentmodel.component "Component Class"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
