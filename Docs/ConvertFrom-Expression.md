<!-- markdownlint-disable MD033 -->
# ConvertFrom-Expression

Deserializes a PowerShell expression to an object.

## Syntax

```PowerShell
ConvertFrom-Expression
    -InputObject <String>
    [-LanguageMode <PSLanguageMode> = 'Restricted']
    [-ListAs <Object>]
    [-MapAs <Object>]
    [<CommonParameters>]
```

## Description

The `ConvertFrom-Expression` cmdlet safely converts a PowerShell formatted expression to an object-graph
existing of a mixture of nested arrays, hash tables and objects that contain a list of strings and values.

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">&lt;String&gt;</a></a>

Specifies the PowerShell expressions to convert to objects. Enter a variable that contains the string,
or type a command or expression that gets the string. You can also pipe a string to ConvertFrom-Expression.

The **InputObject** parameter is required, but its value can be an empty string.
The **InputObject** value can't be `$null` or an empty string.

```powershell
Name:                       -InputObject
Aliases:                    -Expression
Type:                       [String]
Value (default):            # Undefined
Parameter sets:             # All
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-languagemode">`-LanguageMode` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.PSLanguageMode">&lt;PSLanguageMode&gt;</a></a>

Defines which object types are allowed for the deserialization, see: [About language modes][2]

* Any type that is not allowed by the given language mode, will be omitted leaving a bare `[ValueType]`,

```PowerShell
`[String]`, `[Array]` or `[HashTable]`.
```

* Any variable that is not `$True`, `$False` or `$Null` will be converted to a literal string, e.g. `$Test`.

> [!Caution]
>
> In full language mode, `ConvertTo-Expression` permits all type initializers. Cmdlets, functions,
> CIM commands, and workflows will *not* be invoked by the `ConvertFrom-Expression` cmdlet.
>
> Take reasonable precautions when using the `Invoke-Expression -LanguageMode Full` command in scripts.
> Verify that the class types in the expression are safe before instantiating them. In general, it is
> best to design your configuration expressions with restricted or constrained classes, rather than
> allowing full freeform expressions.

```powershell
Name:                       -LanguageMode
Aliases:                    # None
Type:                       [PSLanguageMode]
Value (default):            'Restricted'
Parameter sets:             # All
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-listas">`-ListAs` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

If supplied, the array subexpression `@( )` syntaxes without an type initializer or with an unknown
or denied type initializer will be converted to the given list type.

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

If supplied, the Hash table literal syntax `@{ }` syntaxes without an type initializer or with an unknown
or denied type initializer will be converted to the given map (dictionary or object) type.

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

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
