<!-- markdownlint-disable MD033 -->
# Test-ObjectGraph

Tests the properties of an object-graph.

## Syntax

```PowerShell
Test-ObjectGraph
    -InputObject <Object>
    -SchemaObject <Object>
    [-ValidateOnly]
    [-AssertTestPrefix <String> = 'AssertTestPrefix']
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

```PowerShell
Test-ObjectGraph
    -InputObject <Object>
    -SchemaObject <Object>
    [-Elaborate]
    [-AssertTestPrefix <String> = 'AssertTestPrefix']
    [-MaxDepth <Int32> = [PSNode]::DefaultMaxDepth]
    [<CommonParameters>]
```

## Description

Tests an object-graph against a schema object by verifying that the properties of the object-graph
meet the constrains defined in the schema object.

The schema object has the following major features:

* Independent of the object notation (as e.g. [Json (JavaScript Object Notation)][2] or [PowerShell Data Files][3])
* Each test node is at the same level as the input node being validated
* Complex node requirements (as mutual exclusive nodes) might be selected using a logical formula

## Examples

### <a id="example-1"><a id="example-test-whether-a-person-object-meats-the-schema-requirements">Example 1: Test whether a `$Person` object meats the schema requirements.</a></a>


```PowerShell
$Person = [PSCustomObject]@{
    FirstName = 'John'
    LastName  = 'Smith'
    IsAlive   = $True
    Birthday  = [DateTime]'Monday,  October 7,  1963 10:47:00 PM'
    Age       = 27
    Address   = [PSCustomObject]@{
        Street     = '21 2nd Street'
        City       = 'New York'
        State      = 'NY'
        PostalCode = '10021-3100'
    }
    Phone = @{
        Home   = '212 555-1234'
        Mobile = '212 555-2345'
        Work   = '212 555-3456', '212 555-3456', '646 555-4567'
    }
    Children = @('Dennis', 'Stefan')
    Spouse = $Null
}

$Schema = @{
    FirstName = @{ '@Type' = 'String' }
    LastName  = @{ '@Type' = 'String' }
    IsAlive   = @{ '@Type' = 'Bool' }
    Birthday  = @{ '@Type' = 'DateTime' }
    Age       = @{
        '@Type' = 'Int'
        '@Minimum' = 0
        '@Maximum' = 99
    }
    Address = @{
        '@Type' = 'PSMapNode'
        Street     = @{ '@Type' = 'String' }
        City       = @{ '@Type' = 'String' }
        State      = @{ '@Type' = 'String' }
        PostalCode = @{ '@Type' = 'String' }
    }
    Phone = @{
        '@Type' = 'PSMapNode',  $Null
        Home    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
        Mobile  = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
        Work    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
    }
    Children  = @(@{ '@Type' = 'String', $Null })
    Spouse    = @{ '@Type' = 'String', $Null }
}

$Person | Test-Object $Schema | Should -BeNullOrEmpty
```

## Parameters

### <a id="-inputobject">`-InputObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

Specifies the object to test for validity against the schema object.
The object might be any object containing embedded (or even recursive) lists, dictionaries, objects or scalar
values received from a application or an object notation as Json or YAML using their related `ConvertFrom-*`
cmdlets.

```powershell
Name:                       -InputObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             ValidateOnly, ResultList
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-schemaobject">`-SchemaObject` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Object">&lt;Object&gt;</a></a>

Specifies a schema to validate the JSON input against. By default, if any discrepancies, toy will be reported
in a object list containing the path to failed node, the value whether the node is valid or not and the issue.
If no issues are found, the output is empty.

For details on the schema object, see the [schema object definitions][1] documentation.

```powershell
Name:                       -SchemaObject
Aliases:                    # None
Type:                       [Object]
Value (default):            # Undefined
Parameter sets:             ValidateOnly, ResultList
Mandatory:                  True
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-validateonly">`-ValidateOnly`</a>

If set, the cmdlet will stop at the first invalid node and return the test result object.

```powershell
Name:                       -ValidateOnly
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             ValidateOnly
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-elaborate">`-Elaborate`</a>

If set, the cmdlet will return the test result object for all tested nodes, even if they are valid
or ruled out in a possible list node branch selection.

```powershell
Name:                       -Elaborate
Aliases:                    # None
Type:                       [SwitchParameter]
Value (default):            # Undefined
Parameter sets:             ResultList
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-asserttestprefix">`-AssertTestPrefix` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.String">&lt;String&gt;</a></a>

The prefix used to identify the assert test nodes in the schema object. By default, the prefix is `AssertTestPrefix`.

```powershell
Name:                       -AssertTestPrefix
Aliases:                    # None
Type:                       [String]
Value (default):            'AssertTestPrefix'
Parameter sets:             ValidateOnly, ResultList
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

### <a id="-maxdepth">`-MaxDepth` <a href="https://docs.microsoft.com/en-us/dotnet/api/System.Int32">&lt;Int32&gt;</a></a>

The maximal depth to recursively test each embedded node.
The default value is defined by the PowerShell object node parser (`[PSNode]::DefaultMaxDepth`, default: `20`).

```powershell
Name:                       -MaxDepth
Aliases:                    -Depth
Type:                       [Int32]
Value (default):            [PSNode]::DefaultMaxDepth
Parameter sets:             ValidateOnly, ResultList
Mandatory:                  False
Position:                   # Named
Accept pipeline input:      False
Accept wildcard characters: False
```

## Related Links

* [Schema object definitions](https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/SchemaObject.md)
<!-- -->


[1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/SchemaObject.md "Schema object definitions"

[comment]: <> (Created with Get-MarkdownHelp: Install-Script -Name Get-MarkdownHelp)
