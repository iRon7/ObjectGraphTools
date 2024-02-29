<!-- markdownlint-disable MD033 -->
# ConvertTo-Expression

Serializes an object to a PowerShell expression.

## Syntax

```PowerShell
ConvertTo-Expression
    -InputObject <Object>
    [-Expand <Int32> = [Int]::MaxValue]
    [-IndentSize <Int32> = 4]
    [-IndentChar <String> = ' ']
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

The ConvertTo-Expression cmdlet converts (serializes) an object to a
PowerShell expression. The object can be stored in a variable,  file or
any other common storage for later use or to be ported to another
system.

An expression can be restored to an object using the native
Invoke-Expression cmdlet:

```PowerShell
$Object = Invoke-Expression ($Object | ConvertTo-Expression)
```

Or Converting it to a [ScriptBlock](#scriptblock) and invoking it with cmdlets
along with Invoke-Command or using the call operator (&):

```PowerShell
$Object = &([ScriptBlock]::Create($Object | ConvertTo-Expression))
```

An expression that is stored in a PowerShell (.ps1) file might also
be directly invoked by the PowerShell dot-sourcing technique,  e.g.:

```PowerShell
$Object | ConvertTo-Expression | Out-File .\Expression.ps1
$Object = . .\Expression.ps1
```

Warning: Invoking partly trusted input with Invoke-Expression or
[ScriptBlock](#scriptblock)::Create() methods could be abused by malicious code
injections.

## Parameter

### <a id="-inputobject">**`-InputObject <Object>`**</a>

Specifies the objects to convert to a PowerShell expression. Enter a
variable that contains the objects,  or type a command or expression
that gets the objects. You can also pipe one or more objects to
ConvertTo-Expression.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>True</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-expand">**`-Expand <Int32>`**</a>

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[Int]::MaxValue</code></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-indentsize">**`-IndentSize <Int32>`**</a>

Specifies how many IndentChars to write for each level in the hierarchy.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>4</code></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-indentchar">**`-IndentChar <String>`**</a>

Specifies which character to use for indenting.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>' '</code></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

### <a id="-maxdepth">**`-MaxDepth <Int32>`**</a>

Specifies how many levels of contained objects are included in the
PowerShell representation. The default value is 9.

<table>
<tr><td>Type:</td><td></td></tr>
<tr><td>Mandatory:</td><td>False</td></tr>
<tr><td>Position:</td><td>Named</td></tr>
<tr><td>Default value:</td><td><code>[PSNode]::DefaultMaxDepth</code></td></tr>
<tr><td>Accept pipeline input:</td><td></td></tr>
<tr><td>Accept wildcard characters:</td><td>False</td></tr>
</table>

## Inputs

Any. Each objects provided through the pipeline will converted to an
expression. To concatenate all piped objects in a single expression,
use the unary comma operator,  e.g.: ,$Object | ConvertTo-Expression

## Outputs

String[]. ConvertTo-Expression returns a PowerShell [String](#string) expression
for each input object.

## Related Links

* https://www.powershellgallery.com/packages/ConvertFrom-Expression

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
