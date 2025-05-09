#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]

param()

Describe 'Test-Object' {

    BeforeAll {

        Set-StrictMode -Version Latest

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
    }

    Context 'Existence Check' {

        It 'Help' {
            Test-Object -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Type (as string)' {

        It 'Report' {
            $True | Test-Object @{ '@Type' = 'Bool' } | Should -BeNullOrEmpty
            $Report = 123 | Test-ObjectGraph @{ '@Type' = 'Bool' } -Elaborate
            $Report.ObjectNode.Value | Should -Be 123
            $Report.Valid            | Should -Be $False
            $Report.Issue            | Should -Not -BeNullOrEmpty
        }

        It 'Bool' {
            $True  | Test-Object @{ '@Type' = 'Bool' } -ValidateOnly | Should -BeTrue
            'True' | Test-Object @{ '@Type' = 'Bool' } -ValidateOnly | Should -BeFalse
        }

        It 'Int' {
            123    | Test-Object @{ '@Type' = 'Int' } -ValidateOnly | Should -BeTrue
            '123'  | Test-Object @{ '@Type' = 'Int' } -ValidateOnly | Should -BeFalse
        }

        It 'String' {
            'True' | Test-Object @{ '@Type' = 'String' } -ValidateOnly | Should -BeTrue
            '123'  | Test-Object @{ '@Type' = 'String' } -ValidateOnly | Should -BeTrue
            123    | Test-Object @{ '@Type' = 'String' } -ValidateOnly | Should -BeFalse
        }

        It 'Array' {
            ,@(1,2)    | Test-Object @{ '@Type' = 'Array'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@(1)      | Test-Object @{ '@Type' = 'Array'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@()       | Test-Object @{ '@Type' = 'Array' }                             -ValidateOnly | Should -BeTrue
            'Test'     | Test-Object @{ '@Type' = 'Array'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-Object @{ '@Type' = 'Array'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
        }

        It 'HashTable' {
            @{ a = 1 } | Test-Object @{ '@Type' = 'HashTable'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            @{}        | Test-Object @{ '@Type' = 'HashTable' }                             -ValidateOnly | Should -BeTrue
            'Test'     | Test-Object @{ '@Type' = 'HashTable'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            ,@(1, 2)   | Test-Object @{ '@Type' = 'HashTable'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Type (as type)' {

        It 'Report' {
            $True | Test-Object @{ '@Type' = [Bool] } | Should -BeNullOrEmpty
            123   | Test-Object @{ '@Type' = [Bool] } -Elaborate | ForEach-Object {
                $_.ObjectNode.Value | Should -Be 123
                $_.Valid            | Should -Be $False
                $_.Issue            | Should -Not -BeNullOrEmpty
            }
        }

        It 'Bool' {
            $True  | Test-Object @{ '@Type' = [Bool] }    -ValidateOnly | Should -BeTrue
            'True' | Test-Object @{ '@Type' = [Bool] }    -ValidateOnly | Should -BeFalse
        }

        It 'Int' {
            123    | Test-Object @{ '@Type' = [Int] }     -ValidateOnly | Should -BeTrue
            '123'  | Test-Object @{ '@Type' = [Int] }     -ValidateOnly | Should -BeFalse
        }

        It 'String' {
            'True' | Test-Object @{ '@Type' = [String] } -ValidateOnly | Should -BeTrue
            '123'  | Test-Object @{ '@Type' = [String] } -ValidateOnly | Should -BeTrue
            123    | Test-Object @{ '@Type' = [String] } -ValidateOnly | Should -BeFalse
        }

        It 'Array' {
            ,@(1,2)    | Test-Object @{ '@Type' = [Array]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@(1)      | Test-Object @{ '@Type' = [Array]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@()       | Test-Object @{ '@Type' = [Array] }                             -ValidateOnly | Should -BeTrue
            'Test'     | Test-Object @{ '@Type' = [Array]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-Object @{ '@Type' = [Array]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
        }

        It 'HashTable' {
            @{ a = 1 } | Test-Object @{ '@Type' = [HashTable]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            @{}        | Test-Object @{ '@Type' = [HashTable] }                             -ValidateOnly | Should -BeTrue
            'Test'     | Test-Object @{ '@Type' = [HashTable]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            ,@(1, 2)   | Test-Object @{ '@Type' = [HashTable]; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Not Type (as string)' {

        It 'Bool' {
            'True' | Test-Object @{ '@NotType' = 'Bool' }    -ValidateOnly | Should -BeTrue
            $True  | Test-Object @{ '@NotType' = 'Bool' }    -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Not Type (as type)' {

        It 'Not Bool' {
            'True' | Test-Object @{ '@NotType' = [Bool] }    -ValidateOnly | Should -BeTrue
            $True  | Test-Object @{ '@NotType' = [Bool] }    -ValidateOnly | Should -BeFalse
        }
    }


    Context 'Multiple types' {

        It 'Any of type' {
            '123' | Test-Object @{ '@Type' = [Int], [String] } -ValidateOnly | Should -BeTrue
            $true | Test-Object @{ '@Type' = [Int], [String] } -ValidateOnly | Should -BeFalse
        }

        It 'None of type' {
            '123' | Test-Object @{ '@NotType' = [Int], [String] } -ValidateOnly | Should -BeFalse
            $true | Test-Object @{ '@NotType' = [Int], [String] } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'No type' {

        It '$Null' {
            @{ Test = '123' } | Test-Object @{ Test = @{ '@Type' = [Int], [String] } }         -ValidateOnly | Should -BeTrue
            @{ Test = $Null } | Test-Object @{ Test = @{ '@Type' = [Int], [String] } }         -ValidateOnly | Should -BeFalse
            @{ Test = $Null } | Test-Object @{ Test = @{ '@Type' = [Int], [String], [Void] } } -ValidateOnly | Should -BeTrue
            @{ Test = $Null } | Test-Object @{ Test = @{ '@Type' = [Int], [String], 'Null' } } -ValidateOnly | Should -BeTrue
            @{ Test = $Null } | Test-Object @{ Test = @{ '@Type' = [Int], [String], $Null } }  -ValidateOnly | Should -BeTrue
            @{ Test = '123' } | Test-Object @{ Test = @{ '@Type' = [Int], [Void] } }           -ValidateOnly | Should -BeFalse
        }
    }

    Context 'PSNode Type' {

        It 'Value' {
            'String' | Test-Object @{ '@Type' = 'PSNode' }           -ValidateOnly | Should -BeTrue
            'String' | Test-Object @{ '@Type' = 'PSLeafNode' }       -ValidateOnly | Should -BeTrue
            'String' | Test-Object @{ '@Type' = 'PSCollectionNode' } -ValidateOnly | Should -BeFalse
            'String' | Test-Object @{ '@Type' = 'PSListNode' }       -ValidateOnly | Should -BeFalse
            'String' | Test-Object @{ '@Type' = 'PSMapNode' }        -ValidateOnly | Should -BeFalse
            'String' | Test-Object @{ '@Type' = 'PSObjectNode' }     -ValidateOnly | Should -BeFalse
        }

        It 'Array' {
            ,@(1,2,3) | Test-Object @{ '@Type' = 'PSNode';           '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@(1,2,3) | Test-Object @{ '@Type' = 'PSLeafNode';       '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            ,@(1,2,3) | Test-Object @{ '@Type' = 'PSCollectionNode'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@(1,2,3) | Test-Object @{ '@Type' = 'PSListNode';       '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            ,@(1,2,3) | Test-Object @{ '@Type' = 'PSMapNode';        '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            ,@(1,2,3) | Test-Object @{ '@Type' = 'PSObjectNode';     '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
        }

        It 'Dictionary' {
            @{ a = 1 } | Test-Object @{ '@Type' = 'PSNode';           '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-Object @{ '@Type' = 'PSLeafNode';       '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-Object @{ '@Type' = 'PSCollectionNode'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-Object @{ '@Type' = 'PSListNode';       '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-Object @{ '@Type' = 'PSMapNode';        '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-Object @{ '@Type' = 'PSObjectNode';     '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
        }

        It 'Object' {
            $Person | Test-Object @{ '@Type' = 'PSNode';           '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            $Person | Test-Object @{ '@Type' = 'PSLeafNode';       '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            $Person | Test-Object @{ '@Type' = 'PSCollectionNode'; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            $Person | Test-Object @{ '@Type' = 'PSListNode';       '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeFalse
            $Person | Test-Object @{ '@Type' = 'PSMapNode';        '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            $Person | Test-Object @{ '@Type' = 'PSObjectNode';     '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Natural list ' {
        BeforeAll {
            $Schema = @{ Word = @{ '@Match' = '^\w+$' } }
        }
        it 'No list'         { @{}                           | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it '$Null'           { @{ Word = $null }             | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Test'            { @{ Word = 'Test' }            | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Empty'           { @{ Word = @() }               | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Single'          { @{ Word = @('a') }            | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Multiple'        { @{ Word = @('a', 'b') }       | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'No match a b'    { @{ Word = @('a b') }          | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a, b c' { @{ Word = @('a', 'b c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a b, c' { @{ Word = @('a b', 'c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Dictionary'      { @{ Word = @{ a = 'b' } }      | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'IsWord item'     { @{ Word = @{ IsWord = 'b' } } | Test-Object $Schema -ValidateOnly | Should -BeTrue }
    }

    Context 'Compulsory list with unnamed items' {
        BeforeAll {
            $Schema = @{ Word = @(@{ '@Match' = '^\w+$' }) }
        }
        it 'No list'         { @{}                           | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it '$Null'           { @{ Word = $null }             | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Test'            { @{ Word = 'Test' }            | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Empty'           { @{ Word = @() }               | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Single'          { @{ Word = @('a') }            | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Multiple'        { @{ Word = @('a', 'b') }       | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'No match a b'    { @{ Word = @('a b') }          | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a, b c' { @{ Word = @('a', 'b c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a b, c' { @{ Word = @('a b', 'c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Dictionary'      { @{ Word = @{ a = 'b' } }      | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'IsWord item'     { @{ Word = @{ IsWord = 'b' } } | Test-Object $Schema -ValidateOnly | Should -BeFalse }
    }

    Context 'Compulsory list with named items' {
        BeforeAll {
            $Schema = @{ Word = @{ '@Type' = [PSListNode]; IsWord = @{ '@Match' = '^\w+$' } } }
        }
        it 'No list'         { @{}                           | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it '$Null'           { @{ Word = $null }             | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Test'            { @{ Word = 'Test' }            | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Empty'           { @{ Word = @() }               | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Single'          { @{ Word = @('a') }            | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Multiple'        { @{ Word = @('a', 'b') }       | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'No match a b'    { @{ Word = @('a b') }          | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a, b c' { @{ Word = @('a', 'b c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a b, c' { @{ Word = @('a b', 'c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Dictionary'      { @{ Word = @{ a = 'b' } }      | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'IsWord item'     { @{ Word = @{ IsWord = 'b' } } | Test-Object $Schema -ValidateOnly | Should -BeFalse }
    }

    Context 'Forced list with named items' {
        BeforeAll {
            $Schema = @{ Word = @{ '@Type' = [PSListNode]; '@Required' = $true; IsWord = @{ '@Match' = '^\w+$' } } }
        }
        it 'No list'         { @{}                           | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it '$Null'           { @{ Word = $null }             | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Test'            { @{ Word = 'Test' }            | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Empty'           { @{ Word = @() }               | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Single'          { @{ Word = @('a') }            | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'Multiple'        { @{ Word = @('a', 'b') }       | Test-Object $Schema -ValidateOnly | Should -BeTrue }
        it 'No match a b'    { @{ Word = @('a b') }          | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a, b c' { @{ Word = @('a', 'b c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'No match a b, c' { @{ Word = @('a b', 'c') }     | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'Dictionary'      { @{ Word = @{ a = 'b' } }      | Test-Object $Schema -ValidateOnly | Should -BeFalse }
        it 'IsWord item'     { @{ Word = @{ IsWord = 'b' } } | Test-Object $Schema -ValidateOnly | Should -BeFalse }
    }

    Context 'Multiple integer Limits' {

        It 'Maximum int' {
            ,@(17, 18, 19) | Test-Object @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            ,@(40, 41, 42) | Test-Object @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            ,@(17, 42, 99) | Test-Object @{ '@Maximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive maximum int' {
            ,@(17, 18, 19) | Test-Object @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeTrue
            ,@(40, 41, 42) | Test-Object @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
            ,@(17, 42, 99) | Test-Object @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum int' {
            ,@(97, 98, 99) | Test-Object @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            ,@(42, 43, 44) | Test-Object @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            ,@(17, 42, 99) | Test-Object @{ '@Minimum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive minimum int' {
            ,@(97, 98, 99) | Test-Object @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeTrue
            ,@(42, 43, 44) | Test-Object @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
            ,@(17, 42, 99) | Test-Object @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'String limits' {

        It 'Maximum string' {
            'Alpha' | Test-Object @{ '@Maximum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-Object @{ '@Maximum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Gamma' | Test-Object @{ '@Maximum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive maximum string' {
            'Alpha' | Test-Object @{ '@ExclusiveMaximum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-Object @{ '@ExclusiveMaximum' = 'Beta' } -ValidateOnly | Should -BeFalse
            'Gamma' | Test-Object @{ '@ExclusiveMaximum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum string' {
            'Gamma' | Test-Object @{ '@Minimum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-Object @{ '@Minimum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-Object @{ '@Minimum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive minimum string' {
            'Gamma' | Test-Object @{ '@ExclusiveMinimum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-Object @{ '@ExclusiveMinimum' = 'Beta' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-Object @{ '@ExclusiveMinimum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Integer Limits' {

        It 'Maximum int' {
            17 | Test-Object @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-Object @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            99 | Test-Object @{ '@Maximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive maximum int' {
            17 | Test-Object @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-Object @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
            99 | Test-Object @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum int' {
            99 | Test-Object @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-Object @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            17 | Test-Object @{ '@Minimum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive minimum int' {
            99 | Test-Object @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-Object @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
            17 | Test-Object @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
        }
    }


    Context 'Case sensitive string limits' {

        It 'Maximum string' {
            'alpha' | Test-Object @{ '@CaseSensitive' = $true; '@Maximum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@Maximum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@Maximum' = 'alpha' } -ValidateOnly | Should -BeFalse
        }

        It 'Maximum exclusive string' {
            'alpha' | Test-Object @{ '@CaseSensitive' = $true; '@ExclusiveMaximum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@ExclusiveMaximum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@ExclusiveMaximum' = 'alpha' } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum string' {
            'alpha' | Test-Object @{ '@CaseSensitive' = $true; '@Minimum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@Minimum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@Minimum' = 'alpha' } -ValidateOnly | Should -BeTrue
        }

        It 'Minimum exclusive string' {
            'alpha' | Test-Object @{ '@CaseSensitive' = $true; '@ExclusiveMinimum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@ExclusiveMinimum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-Object @{ '@CaseSensitive' = $true; '@ExclusiveMinimum' = 'alpha' } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'String length limits' {

        It 'Minimum length' {
            'abc'   | Test-Object @{ '@MinimumLength' = 4 } -ValidateOnly | Should -BeFalse
            'abcd'  | Test-Object @{ '@MinimumLength' = 4 } -ValidateOnly | Should -BeTrue
        }

        It 'Length' {
            'ab'    | Test-Object @{ '@Length' = 3 } -ValidateOnly | Should -BeFalse
            'abc'   | Test-Object @{ '@Length' = 3 } -ValidateOnly | Should -BeTrue
            'abcd'  | Test-Object @{ '@Length' = 3 } -ValidateOnly | Should -BeFalse
        }

        It 'Maximum length' {
            'abc'   | Test-Object @{ '@MaximumLength' = 3 } -ValidateOnly | Should -BeTrue
            'abcd'  | Test-Object @{ '@MaximumLength' = 3 } -ValidateOnly | Should -BeFalse
        }

        It 'Multiple values length' {
            ,@('12', '345', '6789') | Test-Object @{ '@MinimumLength' = 2 } -ValidateOnly | Should -BeTrue
            ,@('12', '345', '6789') | Test-Object @{ '@MinimumLength' = 3 } -ValidateOnly | Should -BeFalse
            ,@('123', '456', '789') | Test-Object @{ '@Length' = 3 }        -ValidateOnly | Should -BeTrue
            ,@('12', '345', '6789') | Test-Object @{ '@Length' = 3 }        -ValidateOnly | Should -BeFalse
            ,@('12', '345', '6789') | Test-Object @{ '@MaximumLength' = 4 } -ValidateOnly | Should -BeTrue
            ,@('12', '345', '6789') | Test-Object @{ '@MaximumLength' = 3 } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Patterns' {

        It 'Like' {
            'test' | Test-Object @{ '@Like' = 'T*t' } -ValidateOnly | Should -BeTrue
            'test' | Test-Object @{ '@Like' = 'T?t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not like' {
            'test' | Test-Object @{ '@NotLike' = 'T*t' } -ValidateOnly | Should -BeFalse
            'test' | Test-Object @{ '@NotLike' = 'T?t' } -ValidateOnly | Should -BeTrue
        }


        It 'Match' {
            'test' | Test-Object @{ '@Match' = 'T.*t' } -ValidateOnly | Should -BeTrue
            'test' | Test-Object @{ '@Match' = 'T.t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not match' {
            'test' | Test-Object @{ '@NotMatch' = 'T.*t' } -ValidateOnly | Should -BeFalse
            'test' | Test-Object @{ '@NotMatch' = 'T.t' }   -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Case sensitive patterns' {

        It 'Like' {
            'Test' | Test-Object @{ '@CaseSensitive' = $true; '@Like' = 'T*t' } -ValidateOnly | Should -BeTrue
            'test' | Test-Object @{ '@CaseSensitive' = $true; '@Like' = 'T*t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not like' {
            'Test' | Test-Object @{ '@CaseSensitive' = $true; '@notLike' = 'T*t' } -ValidateOnly | Should -BeFalse
            'test' | Test-Object @{ '@CaseSensitive' = $true; '@notLike' = 'T*t' } -ValidateOnly | Should -BeTrue
        }


        It 'Match' {
            'Test' | Test-Object @{ '@CaseSensitive' = $true; '@Match' = 'T..t' } -ValidateOnly | Should -BeTrue
            'test' | Test-Object @{ '@CaseSensitive' = $true; '@Match' = 'T..t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not match' {
            'Test' | Test-Object @{ '@CaseSensitive' = $true; '@notMatch' = 'T..t' } -ValidateOnly | Should -BeFalse
            'test' | Test-Object @{ '@CaseSensitive' = $true; '@notMatch' = 'T..t' } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Multiple patterns' {

        It 'Like' {
            'Two'  | Test-Object @{ '@Like' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
            'Four' | Test-Object @{ '@Like' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
        }

        It 'Not like' {
            'Two'  | Test-Object @{ '@NotLike' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
            'Four' | Test-Object @{ '@NotLike' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
        }


        It 'Match' {
            'Two'  | Test-Object @{ '@Match' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
            'Four' | Test-Object @{ '@Match' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
        }

        It 'Not match' {
            'Two'  | Test-Object @{ '@NotMatch' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
            'Four' | Test-Object @{ '@NotMatch' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
        }
    }


    Context 'No (child) Node' {

        It "[V] Leaf node" {
            'Test' | Test-Object @{} -ValidateOnly | Should -BeTrue
            'Test' | Test-Object @{} | Should -BeNullOrEmpty
        }

        It "[V] Empty list node" {
            ,@() | Test-Object @{} -ValidateOnly | Should -BeTrue
            ,@() | Test-Object @{} | Should -BeNullOrEmpty
        }

        It "[X] Simple list node" {
            ,@('Test') | Test-Object @{} -ValidateOnly | Should -BeFalse
            $Result = ,@('Test') | Test-Object @{}
            $Result                 | Should -BeOfType PSCustomObject
            $Result.Valid           | Should -BeFalse
            $Result.ObjectNode.Path | Should -BeNullOrEmpty
            $Result.Issue           | Should -BeLike '*not accepted*0*'
        }

        It "[X] Simple list node" {
            ,@('a', 'b') | Test-Object @{} -ValidateOnly | Should -BeFalse
            ,@('a', 'b') | Test-Object @{}| Should -not -BeNullOrEmpty
        }

        It "[V] Empty map node" {
            @{} | Test-Object @{} -ValidateOnly | Should -BeTrue
            @{} | Test-Object @{} | Should -BeNullOrEmpty
        }

        It "[X] Simple map node" {
            @{ a = 1 } | Test-Object @{} -ValidateOnly | Should -BeFalse
            $Result = @{ a = 1 } | Test-Object @{}
            $Result                 | Should -BeOfType PSCustomObject
            $Result.Valid           | Should -BeFalse
            $Result.ObjectNode.Path | Should -BeNullOrEmpty
            $Result.Issue           | Should -BeLike "*not accepted*a*"
        }

        It "[X] Complex object" {
            $Person | Test-Object @{} -ValidateOnly | Should -BeFalse
            $Result = $Person | Test-Object @{}
            $Result                 | Should -BeOfType PSCustomObject
            $Result.Valid           | Should -BeFalse
            $Result.ObjectNode.Path | Should -BeNullOrEmpty
            $Result.Issue           | Should -BeLike "*not accepted*FirstName*LastName*"
        }


        It "[X] Complex map node" {
            $Person | Test-Object @{ '@type' = [PSMapNode] } -ValidateOnly | Should -BeFalse
            $Result = $Person | Test-Object @{ '@type' = [PSMapNode] }
            $Result                 | Should -BeOfType PSCustomObject
            $Result.Valid           | Should -BeFalse
            $Result.ObjectNode.Path | Should -BeNullOrEmpty
            $Result.Issue           | Should -BeLike "*not accepted*FirstName*LastName*"
        }
    }

    Context 'Any (child) Node' {

        It "[V] Leaf node" {
            'Test' | Test-Object @() -ValidateOnly | Should -BeTrue
            'Test' | Test-Object @() | Should -BeNullOrEmpty
        }

        It "[V] Empty list node" {
            ,@() | Test-Object @() -ValidateOnly | Should -BeTrue
            ,@() | Test-Object @() | Should -BeNullOrEmpty
        }

        It "[V] Simple list node" {
            ,@('Test') | Test-Object @() -ValidateOnly | Should -BeTrue
            ,@('Test') | Test-Object @() | Should -BeNullOrEmpty
        }

        It "[V] Simple list node" {
            ,@('a', 'b') | Test-Object @() -ValidateOnly | Should -BeTrue
            ,@('a', 'b') | Test-Object @() | Should -BeNullOrEmpty
        }

        It "[V] Empty map node" {
            @{} | Test-Object @() -ValidateOnly | Should -BeTrue
            @{} | Test-Object @() | Should -BeNullOrEmpty
        }

        It "[V] Simple map node" {
            @{ a = 1 } | Test-Object @() -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-Object @() | Should -BeNullOrEmpty
        }

        It "[V] Complex object" {
            $Person | Test-Object @() -ValidateOnly | Should -BeTrue
            $Person | Test-Object @() | Should -BeNullOrEmpty
        }


        It "[V] Complex map node" {
            $Person | Test-Object @{ '@type' = [PSMapNode]; '*' = @() } -ValidateOnly | Should -BeFalse
            $Person | Test-Object @{ '@type' = [PSMapNode]; '@AllowExtraNodes' = $true } | Should -BeNullOrEmpty
        }
    }

    Context 'Map nodes' {

        It "[V] Single name" {
            $Person | Test-Object @{ Age = @{ '@Type' = 'Int' }; '@AllowExtraNodes' = $true } -ValidateOnly | Should -BeTrue
            $Person | Test-Object @{ Age = @{ '@Type' = 'Int' }; '@AllowExtraNodes' = $true } | Should -BeNullOrEmpty
        }

        It "[V] Multiple names" {
            $Schema = @{
                FirstName = @{ '@Type' = 'String' }
                LastName  = @{ '@Type' = 'String' }
                IsAlive   = @{ '@Type' = 'Bool' }
                Birthday  = @{ '@Type' = 'DateTime' }
                Age       = @{ '@Type' = 'Int' }
                '@AllowExtraNodes' = $true
            }
            $Person | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] All (root) names defined" {
            $Schema = @{
                FirstName = @{ '@Type' = 'String' }
                LastName  = @{ '@Type' = 'String' }
                IsAlive   = @{ '@Type' = 'Bool' }
                Birthday  = @{ '@Type' = 'DateTime' }
                Age       = @{ '@Type' = 'Int' }
                Address   = @{ '@Type' = 'PSMapNode',  $Null; '@AllowExtraNodes' = $true }
                Phone     = @{ '@Type' = 'PSMapNode',  $Null; '@AllowExtraNodes' = $true }
                Children  = @{ '@Type' = 'PSListNode', $Null; '@AllowExtraNodes' = $true }
                Spouse    = @{ '@Type' = 'String',     $Null }
            }
            $Person | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-Object $Schema | Should -BeNullOrEmpty
        }
    }

    Context 'List nodes' {

        BeforeAll {

            $Data = @{
                fruits = @(
                    'apple',
                    'orange',
                    'pear'
                )
                vegetables = @(
                    @{
                        veggieName = 'potato'
                        veggieLike = $True
                    },
                    @{
                        veggieName = 'broccoli'
                        veggieLike = $False
                    }
                )
            }

            $Data2 = @{
                fruits = @(
                    'apple',
                    'orange',
                    'pear'
                )
                vegetables = @(
                    @{
                        veggieName = 'potato'
                        veggieLike = $True
                    },
                    @{
                        veggieName = 'broccoli'
                        veggieLike = $False
                    },
                    @{ # Duplicate node
                        veggieName = 'potato'
                        veggieLike = $True
                    }
                )
            }
        }

        It "[X] One specific node, not allowing extra nodes" {
            $Schema = @{
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Data | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        It "[V] One specific node and allowing extra nodes" {
            $Schema = @{
                '@AllowExtraNodes' = $true
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] One specific node and allowing extra nodes" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    '@AllowExtraNodes' = $true
                    veggie = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Single node that match a test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[X] Multiple nodes that match at least one single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        '@AllowExtraNodes' = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match a single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match a single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie1 = @{
                        '@Type' = [PSMapNode]
                        '@Unique' = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                    veggie2 = @{
                        '@Type' = [PSMapNode]
                        '@Unique' = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match a single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Match at least one node in a single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        '@AllowExtraNodes' = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Duplicate nodes that match a single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    '@AllowExtraNodes' = $true
                    veggie = @{
                        '@Type' = [PSMapNode]
                        '@Unique' = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[X] Duplicate nodes that match a single test definition" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie = @{
                        '@Type' = [PSMapNode]
                        '@Unique' = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Data2 | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match equal test definitions" {
            $Schema = @{
                fruits = @{
                    '@Type' = [PSListNode]
                    fruit = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie1 = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                    veggie2 = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                    veggie3 = @{
                        '@Type' = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It "[V] Full assert test" {
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
            $Person | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-Object $Schema | Should -BeNullOrEmpty
        }
    }

    Context 'Required node' {

        $Schema = @{
            Id = @{ '@Type' = 'Int'; '@Required' = $true }
            Data = @{ '@Type' = 'String' }
        }

        @{ Id = 42 }                | Test-Object $Schema -ValidateOnly | Should -BeTrue
        @{ Id = 42; Data = 'Test' } | Test-Object $Schema -ValidateOnly | Should -BeTrue
        @{ Data = 'Test' }          | Test-Object $Schema -ValidateOnly | Should -BeFalse
        @{ Id = 42; Test = 'Test' } | Test-Object $Schema -ValidateOnly | Should -BeFalse
    }

    Context 'Required nodes formula' {

        it 'Not' {
            $Schema = @{
                a = @{ '@Type' = 'Int' }
                '@RequiredNodes' = 'not a'
            }
            @{ a = 1 }   | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1 }   | Test-Object $Schema | Should -not -BeNullOrEmpty
            @{ a = '1' } | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = '1' } | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        it 'And' {
            $Schema = @{
                a = @{ '@Type' = 'Int' }
                b = @{ '@Type' = 'Int' }
                '@RequiredNodes' = 'a and b'
            }
            @{ a = 1 }          | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1 }          | Test-Object $Schema | Should -not -BeNullOrEmpty
            @{ b = 2 }          | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ b = 2 }          | Test-Object $Schema | Should -not -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1; b = 2 }   | Test-Object $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        it 'Or' {
            $Schema = @{
                a = @{ '@Type' = 'Int' }
                b = @{ '@Type' = 'Int' }
                '@RequiredNodes' = 'a or b'
            }
            @{ a = 1 }          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1 }          | Test-Object $Schema | Should -BeNullOrEmpty
            @{ b = 2 }          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ b = 2 }          | Test-Object $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1; b = 2 }   | Test-Object $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        it 'Xor' {
            $Schema = @{
                a = @{ '@Type' = 'Int' }
                b = @{ '@Type' = 'Int' }
                '@RequiredNodes' = 'a xor b'
            }
            @{ a = 1 }          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1 }          | Test-Object $Schema | Should -BeNullOrEmpty
            @{ b = 2 }          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ b = 2 }          | Test-Object $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = 2 }   | Test-Object $Schema | Should -not -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        it 'Rambling Xor' {
            $Schema = @{
                a = @{ '@Type' = 'Int' }
                b = @{ '@Type' = 'Int' }
                '@RequiredNodes' = '(a and not b) or (not a and b)'
            }
            @{ a = 1 }          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1 }          | Test-Object $Schema | Should -BeNullOrEmpty
            @{ b = 2 }          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            @{ b = 2 }          | Test-Object $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = 2 }   | Test-Object $Schema | Should -not -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-Object $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-Object $Schema | Should -not -BeNullOrEmpty
        }
    }

    Context 'Unique child nodes' {

        it 'Unique' {
            $Schema = @{
                '@Type' = [PSListNode]
                Children = @{'@Type' = [String]; '@Unique' = $true }
            }
            ,@('a', 'b', 'c') | Test-Object $Schema -ValidateOnly | Should -BeTrue
            ,@('a', 'b', 'c') | Test-Object $Schema | Should -BeNullOrEmpty
            ,@('a', 'b', 'a') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            ,@('a', 'b', 'a') | Test-Object $Schema | Should -not -BeNullOrEmpty
        }

        it 'Unique collection' {
            $Schema = @{
                EnabledServers  = @(@{'@Type' = 'String'; '@Unique' = 'Server' })
                DisabledServers = @(@{'@Type' = 'String'; '@Unique' = 'Server' })
            }
            $Servers = @{
                EnabledServers  = 'NL1234', 'NL1235', 'NL1236'
                DisabledServers = 'NL1237', 'NL1238', 'NL1239'
            }
            $Servers | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Servers = @{
                EnabledServers  = 'NL1234', 'NL1235', 'NL1236'
                DisabledServers = 'NL1237', 'NL1235', 'NL1239'
            }
            $Servers | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Results = $Servers | Test-ObjectGraph $Schema
            $Results[0].Issue | Should -BeLike '*equal to the node*'
        }

        it 'Unique decedents' {
            $Schema = @{
                BookStore = @(
                    @{
                        Book = @{
                            Title = @{ '@Type' = 'String'; '@Unique' = 'Title' }
                            Price = @{ '@Type' = 'Double' }
                        }
                    }
                )
            }
            $Books = @{
                BookStore = @(
                    @{
                        Book = @{
                            Title = 'Harry Potter'
                            Price = 29.99
                        }
                    },
                    @{
                        Book = @{
                            Title = 'Learning PowerShell'
                            Price = 39.95
                        }
                    }
                )
            }
            $Books | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Books = @{
                BookStore = @(
                    @{
                        Book = @{
                            Title = 'Harry Potter'
                            Price = 29.99
                        }
                    },
                    @{
                        Book = @{
                            Title = 'Learning PowerShell'
                            Price = 39.95
                        }
                    },
                    @{
                        Book = @{
                            Title = 'Harry Potter'
                            Price = 24.99
                        }
                    }
                )
            }
            $Books | Test-Object $Schema -ValidateOnly | Should -BeFalse
        }
    }

    Context 'References' {

        BeforeAll {

            $Schema = @{
                '@Type' = [PSMapNode]
                '@References' = @{
                    Name = @{ '@Type' = 'String'; '@Match' = '\w{3,16}' }
                    Address = @{
                        '@Type' = [PSMapNode]
                        Street     = @{ '@Type' = 'String' }
                        City       = @{ '@Type' = 'String' }
                        State      = @{ '@Type' = 'String' }
                        PostalCode = @{ '@Type' = 'String' }
                    }
                }
                Buyer = @{
                    '@Type' = [PSMapNode]
                    FirstName = 'Name'
                    LastName  = 'Name'
                    ShippingAddress = 'Address'
                    BillingAddress  = 'Address'
                }
            }

            $RecurseSchema = @{
                '@References' = @{
                    Item = @{
                        '@AllowExtraNodes' = $true
                        Id = @{ '@Match' = '^ID\d{6}$'; '@Required' = $true }
                        Data = 'Item'
                    }
                }
                Test = 'Item'
            }
        }

        it '[V] Buyer' {

            $Data =
                @{
                    Buyer = @{
                        FirstName = 'John'
                        LastName  = 'Doe'
                        ShippingAddress = @{
                            Street     = '123 Main St'
                            City       = 'AnyTown'
                            State      = 'CA'
                            PostalCode = '12345'
                        }
                        BillingAddress  = @{
                            Street     = '456 Elm St'
                            City       = 'OtherTown'
                            State      = 'CA'
                            PostalCode = '67890'
                        }
                    }
                }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        it '[X] Buyer - incorrect LastName' {

            $Data =
                @{
                    Buyer = @{
                        FirstName = 'John'
                        LastName  = 'Do'  # Required 3-16 chars
                        ShippingAddress = @{
                            Street     = '123 Main St'
                            City       = 'AnyTown'
                            State      = 'CA'
                            PostalCode = '12345'
                        }
                        BillingAddress  = @{
                            Street     = '456 Elm St'
                            City       = 'OtherTown'
                            State      = 'CA'
                            PostalCode = '67890'
                        }
                    }
                }
            $Data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Result = $Data | Test-Object $Schema
            $Result | Should -not -BeNullOrEmpty
            $Result.ObjectNode.Path  | Should -Contain 'Buyer.LastName'
            $Result.ObjectNode.Value | Should -Contain 'Do'
        }

        it '[V] Recursive reference' {
            $Data = @{
                Test = @{
                    Id = 'ID000001'
                    Data = @{
                        Id = 'ID000002'
                        Data = @{
                            Id = 'ID000003'
                        }
                    }
                }
            }

           $Data | Test-Object $RecurseSchema -ValidateOnly | Should -be $true
        }

        it '[V] Recursive object' -Skip:$($PSVersionTable.PSVersion -lt '6.0') {
            $Schema = @{
                '@References' = @{
                    RecursePSDrive = @{
                        '@AllowExtraNodes' = $true
                        Name     = @{ '@Type' = [String] }
                        Root     = @{ '@Type' = [String] }
                        Used     = @{ '@Type' = [Long] }
                        Provider = @{
                            '@AllowExtraNodes' = $true
                            Drives = @{
                                '@Type' = [PSListNode]
                                '@AllowExtraNodes' = $true
                                Drive = 'RecursePSDrive'
                            }
                        }
                    }
                }
                '@AllowExtraNodes' = $true
                Mode               = @{ '@Like' = '?????' }
                LastWriteTime      = @{ '@Type' = [DateTime] }
                Exists             = @{ '@Type' = [Bool] }
                Name               = @{ '@Type' = [String] }
                PSDrive            = 'RecursePSDrive'
            }

            Get-Item / | Test-Object $Schema -Depth 5 -ValidateOnly -WarningAction SilentlyContinue | Should -BeTrue
            $Result = Get-Item / | Test-Object $Schema -Depth 5 -Elaborate -WarningAction SilentlyContinue
            $Result.ObjectNode.Path | Should -Contain 'PSDrive.Provider.Drives[0].Name'
        }
    }

    Context 'Different Assert Test Prefix' {

        It "[V] AssertTestPrefix = '^'" {
            $Schema = @{
                AssertTestPrefix = '^'
                FirstName = @{ '^Type' = 'String' }
                LastName  = @{ '^Type' = 'String' }
                IsAlive   = @{ '^Type' = 'Bool' }
                Birthday  = @{ '^Type' = 'DateTime' }
                Age       = @{
                    '^Type' = 'Int'
                    '^Minimum' = 0
                    '^Maximum' = 99
                }
                Address = @{
                    '^Type' = 'PSMapNode'
                    Street     = @{ '^Type' = 'String' }
                    City       = @{ '^Type' = 'String' }
                    State      = @{ '^Type' = 'String' }
                    PostalCode = @{ '^Type' = 'String' }
                }
                Phone = @{
                    '^Type' = 'PSMapNode',  $Null
                    Home    = @{ '^Type' = 'String', 'PSListNode'; '^Match' = '^\d{3} \d{3}-\d{4}$'; '^AllowExtraNodes' = $true }
                    Mobile  = @{ '^Type' = 'String', 'PSListNode'; '^Match' = '^\d{3} \d{3}-\d{4}$'; '^AllowExtraNodes' = $true }
                    Work    = @{ '^Type' = 'String', 'PSListNode'; '^Match' = '^\d{3} \d{3}-\d{4}$'; '^AllowExtraNodes' = $true }
                }
                Children  = @(@{ '^Type' = 'String', $Null })
                Spouse    = @{ '^Type' = 'String', $Null }
            }
            $Person | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-Object $Schema | Should -BeNullOrEmpty
        }

    }
}