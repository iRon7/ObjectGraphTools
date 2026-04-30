#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
param(
    [alias("Path")]$PrototypePath
)

Describe 'Test-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        if ($PrototypePath) {
            $Content = Get-Content -Raw -LiteralPath $PrototypePath
            $CommandName = [io.path]::GetFileNameWithoutExtension($PSCommandPath) -replace '\.Tests$'
            # New-Item -Path Function:$CommandName -Value $Content -Force
            Mock $CommandName ([ScriptBlock]::Create($Content))
        }

        function Select-Issue {
            param( [Parameter(Mandatory = $true, ValueFromPipeLine = $true)][PSCustomObject]$InputObject )
            process { $InputObject.Issue -replace '\x1b\[[0-9;]*m' }
        }


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
            Phone     = @{
                Home   = '212 555-1234'
                Mobile = '212 555-2345'
                Work   = '212 555-3456', '212 555-3456', '646 555-4567'
            }
            Children  = @('Dennis', 'Stefan')
            Spouse    = $Null
        }
    }

    Context 'Existence Check' {

        It 'Help' -Skip:$($null -ne $PrototypePath) {
            Test-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Type (as string)' {

        It 'Report' {
            $True | Test-ObjectGraph @{ '@Type' = 'Bool' } | Should -BeNullOrEmpty
            $Report = 123 | Test-ObjectGraph @{ '@Type' = 'Bool' }
            $Report.ObjectNode.Value | Should -Be 123
            $Report.Valid            | Should -Be $False
            $Report.Issue            | Should -Not -BeNullOrEmpty
        }

        It 'Bool' {
            $True  | Test-ObjectGraph @{ '@Type' = 'Bool' } -ValidateOnly | Should -BeTrue
            'True' | Test-ObjectGraph @{ '@Type' = 'Bool' } -ValidateOnly | Should -BeFalse
        }

        It 'Int' {
            123    | Test-ObjectGraph @{ '@Type' = 'Int' } -ValidateOnly | Should -BeTrue
            '123'  | Test-ObjectGraph @{ '@Type' = 'Int' } -ValidateOnly | Should -BeFalse
        }

        It 'String' {
            'True' | Test-ObjectGraph @{ '@Type' = 'String' } -ValidateOnly | Should -BeTrue
            '123'  | Test-ObjectGraph @{ '@Type' = 'String' } -ValidateOnly | Should -BeTrue
            123    | Test-ObjectGraph @{ '@Type' = 'String' } -ValidateOnly | Should -BeFalse
        }

        It 'Array' {
            , @(1, 2)    | Test-ObjectGraph @{ '@Type' = 'Array'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @(1)      | Test-ObjectGraph @{ '@Type' = 'Array'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @()       | Test-ObjectGraph @{ '@Type' = 'Array' }                   -ValidateOnly | Should -BeTrue
            'Test'     | Test-ObjectGraph @{ '@Type' = 'Array'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'Array'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
        }

        It 'HashTable' {
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'HashTable'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            @{}        | Test-ObjectGraph @{ '@Type' = 'HashTable' }                   -ValidateOnly | Should -BeTrue
            'Test'     | Test-ObjectGraph @{ '@Type' = 'HashTable'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            , @(1, 2)   | Test-ObjectGraph @{ '@Type' = 'HashTable'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Type (as type)' {

        It 'Report' {
            $True | Test-ObjectGraph @{ '@Type' = [Bool] } | Should -BeNullOrEmpty
            123   | Test-ObjectGraph @{ '@Type' = [Bool] } -Elaborate | ForEach-Object {
                $_.ObjectNode.Value | Should -Be 123
                $_.Valid            | Should -Be $False
                $_.Issue            | Should -Not -BeNullOrEmpty
            }
        }

        It 'Bool' {
            $True  | Test-ObjectGraph @{ '@Type' = [Bool] } -ValidateOnly | Should -BeTrue
            'True' | Test-ObjectGraph @{ '@Type' = [Bool] } -ValidateOnly | Should -BeFalse
        }

        It 'Int' {
            123    | Test-ObjectGraph @{ '@Type' = [Int] } -ValidateOnly | Should -BeTrue
            '123'  | Test-ObjectGraph @{ '@Type' = [Int] } -ValidateOnly | Should -BeFalse
        }

        It 'String' {
            'True' | Test-ObjectGraph @{ '@Type' = [String] } -ValidateOnly | Should -BeTrue
            '123'  | Test-ObjectGraph @{ '@Type' = [String] } -ValidateOnly | Should -BeTrue
            123    | Test-ObjectGraph @{ '@Type' = [String] } -ValidateOnly | Should -BeFalse
        }

        It 'Array' {
            , @(1, 2)    | Test-ObjectGraph @{ '@Type' = [Array]; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @(1)      | Test-ObjectGraph @{ '@Type' = [Array]; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @()       | Test-ObjectGraph @{ '@Type' = [Array] }                   -ValidateOnly | Should -BeTrue
            'Test'     | Test-ObjectGraph @{ '@Type' = [Array]; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = [Array]; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
        }

        It 'HashTable' {
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = [HashTable]; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            @{}        | Test-ObjectGraph @{ '@Type' = [HashTable] }                   -ValidateOnly | Should -BeTrue
            'Test'     | Test-ObjectGraph @{ '@Type' = [HashTable]; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            , @(1, 2)   | Test-ObjectGraph @{ '@Type' = [HashTable]; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Not Type (as string)' {

        It 'Bool' {
            'True' | Test-ObjectGraph @{ '@NotType' = 'Bool' }    -ValidateOnly | Should -BeTrue
            $True  | Test-ObjectGraph @{ '@NotType' = 'Bool' }    -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Not Type (as type)' {

        It 'Not Bool' {
            'True' | Test-ObjectGraph @{ '@NotType' = [Bool] }    -ValidateOnly | Should -BeTrue
            $True  | Test-ObjectGraph @{ '@NotType' = [Bool] }    -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Multiple types' {

        It 'Any of type' {
            '123' | Test-ObjectGraph @{ '@Type' = [Int], [String] } -ValidateOnly | Should -BeTrue
            $true | Test-ObjectGraph @{ '@Type' = [Int], [String] } -ValidateOnly | Should -BeFalse
        }

        It 'None of type' {
            '123' | Test-ObjectGraph @{ '@NotType' = [Int], [String] } -ValidateOnly | Should -BeFalse
            $true | Test-ObjectGraph @{ '@NotType' = [Int], [String] } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'No type' {

        It '$Null' {
            @{ Test = '123' } | Test-ObjectGraph @{ Test = @{ '@Type' = [Int], [String] } }         -ValidateOnly | Should -BeTrue
            @{ Test = $Null } | Test-ObjectGraph @{ Test = @{ '@Type' = [Int], [String] } }         -ValidateOnly | Should -BeFalse
            @{ Test = $Null } | Test-ObjectGraph @{ Test = @{ '@Type' = [Int], [String], [Void] } } -ValidateOnly | Should -BeTrue
            @{ Test = $Null } | Test-ObjectGraph @{ Test = @{ '@Type' = [Int], [String], 'Null' } } -ValidateOnly | Should -BeTrue
            @{ Test = $Null } | Test-ObjectGraph @{ Test = @{ '@Type' = [Int], [String], $Null } }  -ValidateOnly | Should -BeTrue
            @{ Test = '123' } | Test-ObjectGraph @{ Test = @{ '@Type' = [Int], [Void] } }           -ValidateOnly | Should -BeFalse
        }
    }

    Context 'PSNode Type' {

        It 'Value' {
            'String' | Test-ObjectGraph @{ '@Type' = 'PSNode' }           -ValidateOnly | Should -BeTrue
            'String' | Test-ObjectGraph @{ '@Type' = 'PSLeafNode' }       -ValidateOnly | Should -BeTrue
            'String' | Test-ObjectGraph @{ '@Type' = 'PSCollectionNode' } -ValidateOnly | Should -BeFalse
            'String' | Test-ObjectGraph @{ '@Type' = 'PSListNode' }       -ValidateOnly | Should -BeFalse
            'String' | Test-ObjectGraph @{ '@Type' = 'PSMapNode' }        -ValidateOnly | Should -BeFalse
            'String' | Test-ObjectGraph @{ '@Type' = 'PSObjectNode' }     -ValidateOnly | Should -BeFalse
        }

        It 'Array' {
            , @(1, 2, 3) | Test-ObjectGraph @{ '@Type' = 'PSNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @(1, 2, 3) | Test-ObjectGraph @{ '@Type' = 'PSLeafNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            , @(1, 2, 3) | Test-ObjectGraph @{ '@Type' = 'PSCollectionNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @(1, 2, 3) | Test-ObjectGraph @{ '@Type' = 'PSListNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            , @(1, 2, 3) | Test-ObjectGraph @{ '@Type' = 'PSMapNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            , @(1, 2, 3) | Test-ObjectGraph @{ '@Type' = 'PSObjectNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
        }

        It 'Dictionary' {
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'PSNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'PSLeafNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'PSCollectionNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'PSListNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'PSMapNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-ObjectGraph @{ '@Type' = 'PSObjectNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
        }

        It 'Object' {
            $Person | Test-ObjectGraph @{ '@Type' = 'PSNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph @{ '@Type' = 'PSLeafNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            $Person | Test-ObjectGraph @{ '@Type' = 'PSCollectionNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph @{ '@Type' = 'PSListNode'; '@AnyName' = @() } -ValidateOnly | Should -BeFalse
            $Person | Test-ObjectGraph @{ '@Type' = 'PSMapNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph @{ '@Type' = 'PSObjectNode'; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Map (name based) test' {

        BeforeAll { $Schema = @{ Foo = @{ '@Like' = 'Bar' } } }

        It '@Like' {
            @{}                           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @($null)                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @())                      | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@{})                       | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @('Bar'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(, @('Baz'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @('Bar')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @('Baz')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Bar', 'Bar'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(@('Bar', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Baz', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Baz') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = 'Baz' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Bar', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Baz', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Foo') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = 'Foo' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Bar'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Baz = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar'; Baz = 'Bar' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
        }
    }

    Context 'List (value based) test' {

        BeforeAll { $Schema = @(@{ '@Like' = 'Bar' }) }

        It '@Like' {
            @{}                           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @($null)                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @())                      | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@{})                       | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @('Bar'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(, @('Baz'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @('Bar')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @('Baz')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Bar', 'Bar'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(@('Bar', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Baz', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Baz') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = 'Baz' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Bar', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Baz', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Baz = @('Foo') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Baz = 'Foo' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Baz = @('Bar', 'Foo') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Foo', 'Foo') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Bar'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Baz = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar'; Baz = 'Bar' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Map (name based) test allowing addition names' {

        BeforeAll { $Schema = @{ Foo = @{ '@Like' = 'Bar' }; '@AnyName' = @() } }

        It '@Like' {
            @{}                           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @($null)                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @())                      | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@{})                       | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @('Bar'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(, @('Baz'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @('Bar')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @('Baz')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Bar', 'Bar'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(@('Bar', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(@('Baz', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Baz') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = 'Baz' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Bar', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Baz', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Foo') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = 'Foo' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar', 'Foo') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Foo', 'Foo') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Bar'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Baz = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar'; Baz = 'Bar' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
        }
    }

    Context 'List (value based) test allowing additional values' {

        BeforeAll { $Schema = @(@{ '@Like' = 'Bar'; '@AnyName' = @() }) }

        It '@Like' {
            @{}                           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @($null)                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @())                      | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@{})                       | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(, @('Bar'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(, @('Baz'))                 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @('Bar')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @('Baz')                     | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Bar', 'Bar'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @(@('Bar', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @(@('Baz', 'Baz'))           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Baz') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = 'Baz' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Foo = @('Bar', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = @('Baz', 'Baz') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = $null }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @() }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @{} }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Baz = @('Foo') }           | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = 'Bar' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Baz = 'Foo' }              | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Bar', 'Bar') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Baz = @('Bar', 'Foo') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Baz = @('Foo', 'Foo') }    | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Bar'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Foo = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Bar = 'Foo'; Baz = 'Baz' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Foo = 'Bar'; Baz = 'Bar' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Multiple integer Limits' {

        It 'Maximum int' {
            , @(17, 18, 19) | Test-ObjectGraph @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            , @(40, 41, 42) | Test-ObjectGraph @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            , @(17, 42, 99) | Test-ObjectGraph @{ '@Maximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive maximum int' {
            , @(17, 18, 19) | Test-ObjectGraph @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeTrue
            , @(40, 41, 42) | Test-ObjectGraph @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
            , @(17, 42, 99) | Test-ObjectGraph @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum int' {
            , @(97, 98, 99) | Test-ObjectGraph @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            , @(42, 43, 44) | Test-ObjectGraph @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            , @(17, 42, 99) | Test-ObjectGraph @{ '@Minimum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive minimum int' {
            , @(97, 98, 99) | Test-ObjectGraph @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeTrue
            , @(42, 43, 44) | Test-ObjectGraph @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
            , @(17, 42, 99) | Test-ObjectGraph @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'String limits' {

        It 'Maximum string' {
            'Alpha' | Test-ObjectGraph @{ '@Maximum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-ObjectGraph @{ '@Maximum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Gamma' | Test-ObjectGraph @{ '@Maximum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive maximum string' {
            'Alpha' | Test-ObjectGraph @{ '@ExclusiveMaximum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-ObjectGraph @{ '@ExclusiveMaximum' = 'Beta' } -ValidateOnly | Should -BeFalse
            'Gamma' | Test-ObjectGraph @{ '@ExclusiveMaximum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum string' {
            'Gamma' | Test-ObjectGraph @{ '@Minimum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-ObjectGraph @{ '@Minimum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-ObjectGraph @{ '@Minimum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive minimum string' {
            'Gamma' | Test-ObjectGraph @{ '@ExclusiveMinimum' = 'Beta' } -ValidateOnly | Should -BeTrue
            'Beta'  | Test-ObjectGraph @{ '@ExclusiveMinimum' = 'Beta' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-ObjectGraph @{ '@ExclusiveMinimum' = 'Beta' } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Integer Limits' {

        It 'Maximum int' {
            17 | Test-ObjectGraph @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-ObjectGraph @{ '@Maximum' = 42 } -ValidateOnly | Should -BeTrue
            99 | Test-ObjectGraph @{ '@Maximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive maximum int' {
            17 | Test-ObjectGraph @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-ObjectGraph @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
            99 | Test-ObjectGraph @{ '@ExclusiveMaximum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum int' {
            99 | Test-ObjectGraph @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-ObjectGraph @{ '@Minimum' = 42 } -ValidateOnly | Should -BeTrue
            17 | Test-ObjectGraph @{ '@Minimum' = 42 } -ValidateOnly | Should -BeFalse
        }

        It 'Exclusive minimum int' {
            99 | Test-ObjectGraph @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeTrue
            42 | Test-ObjectGraph @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
            17 | Test-ObjectGraph @{ '@ExclusiveMinimum' = 42 } -ValidateOnly | Should -BeFalse
        }
    }


    Context 'Case sensitive string limits' {

        It 'Maximum string' {
            'alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Maximum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Maximum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Maximum' = 'alpha' } -ValidateOnly | Should -BeFalse
        }

        It 'Maximum exclusive string' {
            'alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@ExclusiveMaximum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@ExclusiveMaximum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@ExclusiveMaximum' = 'alpha' } -ValidateOnly | Should -BeFalse
        }

        It 'Minimum string' {
            'alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Minimum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Minimum' = 'Alpha' } -ValidateOnly | Should -BeTrue
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Minimum' = 'alpha' } -ValidateOnly | Should -BeTrue
        }

        It 'Minimum exclusive string' {
            'alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@ExclusiveMinimum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@ExclusiveMinimum' = 'Alpha' } -ValidateOnly | Should -BeFalse
            'Alpha' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@ExclusiveMinimum' = 'alpha' } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'String length limits' {

        It 'Minimum length' {
            'abc'   | Test-ObjectGraph @{ '@MinimumLength' = 4 } -ValidateOnly | Should -BeFalse
            'abcd'  | Test-ObjectGraph @{ '@MinimumLength' = 4 } -ValidateOnly | Should -BeTrue
        }

        It 'Length' {
            'ab'    | Test-ObjectGraph @{ '@Length' = 3 } -ValidateOnly | Should -BeFalse
            'abc'   | Test-ObjectGraph @{ '@Length' = 3 } -ValidateOnly | Should -BeTrue
            'abcd'  | Test-ObjectGraph @{ '@Length' = 3 } -ValidateOnly | Should -BeFalse
        }

        It 'Maximum length' {
            'abc'   | Test-ObjectGraph @{ '@MaximumLength' = 3 } -ValidateOnly | Should -BeTrue
            'abcd'  | Test-ObjectGraph @{ '@MaximumLength' = 3 } -ValidateOnly | Should -BeFalse
        }

        It 'Multiple values length' {
            , @('12', '345', '6789') | Test-ObjectGraph @{ '@MinimumLength' = 2 } -ValidateOnly | Should -BeTrue
            , @('12', '345', '6789') | Test-ObjectGraph @{ '@MinimumLength' = 3 } -ValidateOnly | Should -BeFalse
            , @('123', '456', '789') | Test-ObjectGraph @{ '@Length' = 3 }        -ValidateOnly | Should -BeTrue
            , @('12', '345', '6789') | Test-ObjectGraph @{ '@Length' = 3 }        -ValidateOnly | Should -BeFalse
            , @('12', '345', '6789') | Test-ObjectGraph @{ '@MaximumLength' = 4 } -ValidateOnly | Should -BeTrue
            , @('12', '345', '6789') | Test-ObjectGraph @{ '@MaximumLength' = 3 } -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Patterns' {

        It 'Like' {
            'test' | Test-ObjectGraph @{ '@Like' = 'T*t' } -ValidateOnly | Should -BeTrue
            'test' | Test-ObjectGraph @{ '@Like' = 'T?t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not like' {
            'test' | Test-ObjectGraph @{ '@NotLike' = 'T*t' } -ValidateOnly | Should -BeFalse
            'test' | Test-ObjectGraph @{ '@NotLike' = 'T?t' } -ValidateOnly | Should -BeTrue
        }


        It 'Match' {
            'test' | Test-ObjectGraph @{ '@Match' = 'T.*t' } -ValidateOnly | Should -BeTrue
            'test' | Test-ObjectGraph @{ '@Match' = 'T.t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not match' {
            'test' | Test-ObjectGraph @{ '@NotMatch' = 'T.*t' } -ValidateOnly | Should -BeFalse
            'test' | Test-ObjectGraph @{ '@NotMatch' = 'T.t' }   -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Case sensitive patterns' {

        It 'Like' {
            'Test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Like' = 'T*t' } -ValidateOnly | Should -BeTrue
            'test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Like' = 'T*t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not like' {
            'Test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@notLike' = 'T*t' } -ValidateOnly | Should -BeFalse
            'test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@notLike' = 'T*t' } -ValidateOnly | Should -BeTrue
        }


        It 'Match' {
            'Test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Match' = 'T..t' } -ValidateOnly | Should -BeTrue
            'test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@Match' = 'T..t' } -ValidateOnly | Should -BeFalse
        }

        It 'Not match' {
            'Test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@notMatch' = 'T..t' } -ValidateOnly | Should -BeFalse
            'test' | Test-ObjectGraph @{ '@CaseSensitive' = $true; '@notMatch' = 'T..t' } -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Multiple patterns' {

        It 'Like' {
            'Two'  | Test-ObjectGraph @{ '@Like' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
            'Four' | Test-ObjectGraph @{ '@Like' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
        }

        It 'Not like' {
            'Two'  | Test-ObjectGraph @{ '@NotLike' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
            'Four' | Test-ObjectGraph @{ '@NotLike' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
        }


        It 'Match' {
            'Two'  | Test-ObjectGraph @{ '@Match' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
            'Four' | Test-ObjectGraph @{ '@Match' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
        }

        It 'Not match' {
            'Two'  | Test-ObjectGraph @{ '@NotMatch' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeFalse
            'Four' | Test-ObjectGraph @{ '@NotMatch' = 'One', 'Two', 'Three' } -ValidateOnly | Should -BeTrue
        }
    }


    Context 'No (child) Node' {

        It "[V] Leaf node" {
            'Test' | Test-ObjectGraph @{} -ValidateOnly | Should -BeTrue
            'Test' | Test-ObjectGraph @{} | Should -BeNullOrEmpty
        }

        It "[V] Empty list node" {
            , @() | Test-ObjectGraph @{} -ValidateOnly | Should -BeTrue
            , @() | Test-ObjectGraph @{} | Should -BeNullOrEmpty
        }

        It "[X] Single list node" {
            , @('Test') | Test-ObjectGraph @{} -ValidateOnly | Should -BeFalse
            $Result = , @('Test') | Test-ObjectGraph @{}
            $Result                 | Should -BeOfType PSCustomObject
            $Result.Valid           | Should -BeFalse
            $Result.ObjectNode.Path | Should -BeNullOrEmpty
            $Result | Select-Issue  | Should -Be "@('Test') is not accepted"
        }

        It "[X] Simple list node" {
            , @('a', 'b') | Test-ObjectGraph @{} -ValidateOnly | Should -BeFalse
            , @('a', 'b') | Test-ObjectGraph @{} | Should -Not -BeNullOrEmpty
        }

        It "[V] Empty map node" {
            @{} | Test-ObjectGraph @{} -ValidateOnly | Should -BeTrue
            @{} | Test-ObjectGraph @{} | Should -BeNullOrEmpty
        }

        It "[X] Simple map node" {
            @{ a = 1 } | Test-ObjectGraph @{} -ValidateOnly | Should -BeFalse
            $Result = @{ a = 1 } | Test-ObjectGraph @{}
            $Result                 | Should -BeOfType PSCustomObject
            $Result.Valid           | Should -BeFalse
            $Result.ObjectNode.Path | Should -BeNullOrEmpty
            $Result.Issue           | Should -BeLike "Node 'a' is denied"
        }

        It "[X] Complex object" {
            $Person | Test-ObjectGraph @{} -ValidateOnly | Should -BeFalse
            $Result = $Person | Test-ObjectGraph @{}
            $Result                 | Should -BeOfType PSCustomObject
            $Result                 | Should -HaveCount 9
            $Result.Valid           | Should -BeFalse
            $Result.Issue           | Should -BeLike "Node * is denied"
        }


        It "[X] Complex map node" {
            $Person | Test-ObjectGraph @{ '@type' = [PSMapNode] } -ValidateOnly | Should -BeFalse
            $Result = $Person | Test-ObjectGraph @{ '@type' = [PSMapNode] }
            $Result                 | Should -BeOfType PSCustomObject
            $Result                 | Should -HaveCount 9
            $Result.Valid           | Should -BeFalse
            $Result.Issue           | Should -BeLike "Node * is denied"
        }
    }

    Context 'Any (child) Node' {

        It "[V] Leaf node" {
            'Test' | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            'Test' | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }

        It "[V] Empty list node" {
            , @() | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            , @() | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }

        It "[V] Simple list node" {
            , @('Test') | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            , @('Test') | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }

        It "[V] Simple list node" {
            , @('a', 'b') | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            , @('a', 'b') | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }

        It "[V] Empty map node" {
            @{} | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            @{} | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }

        It "[V] Simple map node" {
            @{ a = 1 } | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            @{ a = 1 } | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }

        It "[V] Complex object" {
            $Person | Test-ObjectGraph @() -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph @() | Should -BeNullOrEmpty
        }


        It "[V] Complex map node" {
            $Person | Test-ObjectGraph @{ '@type' = [PSMapNode]; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph @{ '@type' = [PSMapNode]; '@AnyName' = @() } | Should -BeNullOrEmpty
        }
    }

    Context 'Map nodes' {

        It "[V] Single name" {
            $Person | Test-ObjectGraph @{ Age = @{ '@Type' = 'Int' }; '@AnyName' = @() } -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph @{ Age = @{ '@Type' = 'Int' }; '@AnyName' = @() } | Should -BeNullOrEmpty
        }

        It "[V] Multiple names" {
            $Schema = @{
                FirstName  = @{ '@Type' = 'String' }
                LastName   = @{ '@Type' = 'String' }
                IsAlive    = @{ '@Type' = 'Bool' }
                Birthday   = @{ '@Type' = 'DateTime' }
                Age        = @{ '@Type' = 'Int' }
                '@AnyName' = @()
            }
            $Person | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] All (root) names defined" {
            $Schema = @{
                FirstName = @{ '@Type' = 'String' }
                LastName  = @{ '@Type' = 'String' }
                IsAlive   = @{ '@Type' = 'Bool' }
                Birthday  = @{ '@Type' = 'DateTime' }
                Age       = @{ '@Type' = 'Int' }
                Address   = @{ '@Type' = 'PSMapNode', $Null; '@AnyName' = @() }
                Phone     = @{ '@Type' = 'PSMapNode', $Null; '@AnyName' = @() }
                Children  = @{ '@Type' = 'PSListNode', $Null; '@AnyName' = @() }
                Spouse    = @{ '@Type' = 'String', $Null }
            }
            $Person | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }
    }

    Context 'List nodes' {

        BeforeAll {

            $Data = @{
                fruits     = @(
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
                fruits     = @(
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
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            $Data | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It "[V] One specific node and allowing extra nodes" {
            $Schema = @{
                '@AnyName' = @()
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] One specific node and allowing extra nodes" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type'    = [PSListNode]
                    '@AnyName' = @()
                    veggie     = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Single node that match a test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[X] Multiple nodes that match at least one single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        '@AnyName' = @()
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match a single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match a single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie1 = @{
                        '@Type'    = [PSMapNode]
                        '@Unique'  = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                    veggie2 = @{
                        '@Type'    = [PSMapNode]
                        '@Unique'  = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match a single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Match at least one node in a single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        '@AnyName' = @()
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Duplicate nodes that match a single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        '@Unique'  = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            $Data2 | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It "[X] Duplicate nodes that match a single test definition" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie  = @{
                        '@Type'    = [PSMapNode]
                        '@Unique'  = $true
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            $Data2 | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It "[V] Multiple nodes that match equal test definitions" {
            $Schema = @{
                fruits     = @{
                    '@Type' = [PSListNode]
                    fruit   = @{ '@Type' = [String] }
                }
                vegetables = @{
                    '@Type' = [PSListNode]
                    veggie1 = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                    veggie2 = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                    veggie3 = @{
                        '@Type'    = [PSMapNode]
                        veggieName = @{ '@Type' = [String] }
                        veggieLike = @{ '@Type' = [Bool] }
                    }
                }
            }
            $Data2 | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data2 | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It "[V] Full assert test" {
            $Schema = @{
                FirstName = @{ '@Type' = 'String' }
                LastName  = @{ '@Type' = 'String' }
                IsAlive   = @{ '@Type' = 'Bool' }
                Birthday  = @{ '@Type' = 'DateTime' }
                Age       = @{
                    '@Type'    = 'Int'
                    '@Minimum' = 0
                    '@Maximum' = 99
                }
                Address   = @{
                    '@Type'    = 'PSMapNode'
                    Street     = @{ '@Type' = 'String' }
                    City       = @{ '@Type' = 'String' }
                    State      = @{ '@Type' = 'String' }
                    PostalCode = @{ '@Type' = 'String' }
                }
                Phone     = @{
                    '@Type' = 'PSMapNode', $Null
                    Home    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
                    Mobile  = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
                    Work    = @{ '@Match' = '^\d{3} \d{3}-\d{4}$' }
                }
                Children  = @(@{ '@Type' = 'String', $Null })
                Spouse    = @{ '@Type' = 'String', $Null }
            }
            $Person | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }
    }

    Context 'Optional node' {

        It 'Required Id, Optional Data' {
            $Schema = @{
                Id   = @{ '@Type' = 'Int' }
                Data = @{ '@Type' = 'String'; '@Optional' = $true }
            }

            @{ Id = 42 }                | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Id = 42; Data = 'Test' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Data = 'Test' }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ Id = 42; Test = 'Test' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Single optional node' {

        It 'Required Id, Optional Data' {
            $Schema = @{
                One = @{ '@Type' = 'String'; '@Optional' = $true }
            }

            @{ One = 'Test' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Two = 'Test' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{}               | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
        }
    }

    Context 'Nodes condition' {

        It 'Not' {
            $Schema = @{
                a           = @{ '@Type' = 'Int' }
                '@Requires' = 'not a'
            }
            @{ a = 1 }   | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1 }   | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
            @{ a = '1' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = '1' } | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It 'And' {
            $Schema = @{
                a           = @{ '@Type' = 'Int' }
                b           = @{ '@Type' = 'Int' }
                '@Requires' = 'a and b'
            }
            @{ a = 1 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1 }          | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
            @{ b = 2 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ b = 2 }          | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It 'Or' {
            $Schema = @{
                a           = @{ '@Type' = 'Int' }
                b           = @{ '@Type' = 'Int' }
                '@Requires' = 'a or b'
            }
            @{ a = 1 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1 }          | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ b = 2 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ b = 2 }          | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It 'Xor' {
            $Schema = @{
                a           = @{ '@Type' = 'Int' }
                b           = @{ '@Type' = 'Int' }
                '@Requires' = 'a xor b'
            }
            @{ a = 1 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1 }          | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ b = 2 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ b = 2 }          | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It 'Rambling Xor' {
            $Schema = @{
                a           = @{ '@Type' = 'Int' }
                b           = @{ '@Type' = 'Int' }
                '@Requires' = '(a and not b) or (not a and b)'
            }
            @{ a = 1 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ a = 1 }          | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ b = 2 }          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ b = 2 }          | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = 2 }   | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            @{ a = 1; b = '2' } | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It 'Negate node branch' {
            $Schema = @{
                Parent = @{
                    anInt = @{ '@Type' = 'Int' }
                }
            }
            @{ Parent = 1, 2, 3 } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Parent = 1, 2, 3 } | Test-ObjectGraph $Schema | Should -BeNullOrEmpty

            $Schema = @{
                Parent = @{ # One of the nodes should not be a string
                    '@Requires' = 'Not aString'
                    '@AnyName'  = @()
                    aString     = @{ '@Type' = 'String' }
                }
            }
            @{ Parent = 1 , 2 , 3 } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Parent = '1', 2 , 3 } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Parent = '1', '2', 3 } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Parent = '1', '2', '3' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Ordered' {

        BeforeAll {
            $Schema = @{
                Parent = [PSCustomObject]@{
                    '@Ordered' = $True
                    1 = @{ '@Like' = 'One' }
                    2 = @{ '@Like' = 'Two' }
                    3 = @{ '@Like' = 'Three' }
                }
            }
        }

        It 'In order' {
            @{ Parent = 'One', 'Two', 'Three' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{ Parent = 'One', 'Two', 'Three' } | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

        It 'In order' {
            @{ Parent = 'Three', 'Two', 'One' } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            $Issues = @{ Parent = 'Three', 'Two', 'One' } | Test-ObjectGraph $Schema | Select-Issue
            $Issues.Count | Should -be 2
            $Issues | Should -Contain "The value 'Three' is not like 'One'"
            $Issues | Should -Contain "The value 'One' is not like 'Three'"
        }
    }

    Context 'Unique child nodes' {

        It 'Unique' {
            $Schema = @{
                '@Type'  = [PSListNode]
                Children = @{'@Type' = [String]; '@Unique' = $true }
            }
            , @('a', 'b', 'c') | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            , @('a', 'b', 'c') | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
            , @('a', 'b', 'a') | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            , @('a', 'b', 'a') | Test-ObjectGraph $Schema | Should -Not -BeNullOrEmpty
        }

        It 'Unique collection' {
            $Schema = @{
                EnabledServers  = @(@{'@Type' = 'String'; '@Unique' = 'Server' })
                DisabledServers = @(@{'@Type' = 'String'; '@Unique' = 'Server' })
            }
            $Servers = @{
                EnabledServers  = 'NL1234', 'NL1235', 'NL1236'
                DisabledServers = 'NL1237', 'NL1238', 'NL1239'
            }
            $Servers | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Servers = @{
                EnabledServers  = 'NL1234', 'NL1235', 'NL1236'
                DisabledServers = 'NL1237', 'NL1235', 'NL1239'
            }
            $Servers | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            $Results = $Servers | Test-ObjectGraph $Schema
            $Results[0].Issue | Should -BeLike '*equal to the node*'
        }

        It 'Unique decedents' {
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
            $Books | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
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
            $Books | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
        }
    }

    Context 'References' {

        BeforeAll {

            $Schema = @{
                '@Type'       = [PSMapNode]
                '@References' = @{
                    Name    = @{ '@Type' = 'String'; '@Match' = '\w{3,16}' }
                    Address = @{
                        '@Type'    = [PSMapNode]
                        Street     = @{ '@Type' = 'String' }
                        City       = @{ '@Type' = 'String' }
                        State      = @{ '@Type' = 'String' }
                        PostalCode = @{ '@Type' = 'String' }
                    }
                }
                Buyer         = @{
                    '@Type'         = [PSMapNode]
                    FirstName       = 'Name'
                    LastName        = 'Name'
                    ShippingAddress = 'Address'
                    BillingAddress  = 'Address'
                }
            }

            $PSSchema = $Schema | Copy-Object -MapAs PSCustomObject

            $RecurseSchema = @{
                '@References' = @{
                    Item = @{
                        '@Optional' = $true
                        '@AnyName'  = @()
                        Id          = @{ '@Match' = '^ID\d{6}$' }
                        Data        = 'Item'
                    }
                }
                Test          = 'Item'
            }
        }

        It '[V] Buyer' {

            $Data =
            @{
                Buyer = @{
                    FirstName       = 'John'
                    LastName        = 'Doe'
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
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $Schema | Should -BeNullOrEmpty

            $Data | Test-ObjectGraph $PSSchema -ValidateOnly | Should -BeTrue
            $Data | Test-ObjectGraph $PSSchema | Should -BeNullOrEmpty
        }

        It '[X] Buyer - incorrect LastName' {

            $Data =
            @{
                Buyer = @{
                    FirstName       = 'John'
                    LastName        = 'Do'  # Required 3-16 chars
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
            $Data | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
            $Result = $Data | Test-ObjectGraph $Schema
            $Result | Should -Not -BeNullOrEmpty
            $Result.ObjectNode.Path  | Should -Contain 'Buyer.LastName'
            $Result.ObjectNode.Value | Should -Contain 'Do'

            $Data | Test-ObjectGraph $PSSchema -ValidateOnly | Should -BeFalse
            $Result = $Data | Test-ObjectGraph $PSSchema
            $Result | Should -Not -BeNullOrEmpty
            $Result.ObjectNode.Path  | Should -Contain 'Buyer.LastName'
            $Result.ObjectNode.Value | Should -Contain 'Do'
        }

        It '[V] Recursive reference' {
            $Data = @{
                Test = @{
                    Id   = 'ID000001'
                    Data = @{
                        Id   = 'ID000002'
                        Data = @{
                            Id = 'ID000003'
                        }
                    }
                }
            }

            $Data | Test-ObjectGraph $RecurseSchema -ValidateOnly | Should -Be $true
        }

        It '[X] Recursive PSItem object (required Drives)' -Skip:$($PSVersionTable.PSVersion -lt '6.0') {
            $Schema = @{
                '@References' = @{
                    RecursePSDrive = @{
                        '@AnyName' = @()
                        Name       = @{ '@Type' = [String] }
                        Root       = @{ '@Type' = [String] }
                        Used       = @{ '@Type' = [Long], $Null }
                        Provider   = @{
                            '@AnyName' = @()
                            Drives     = @{
                                '@Type' = [PSListNode]
                                Drive   = 'RecursePSDrive'
                            }
                        }
                    }
                }
                '@AnyName'    = @()
                Mode          = @{ '@Like' = '?????' }
                LastWriteTime = @{ '@Type' = [DateTime] }
                Exists        = @{ '@Type' = [Bool] }
                Name          = @{ '@Type' = [String] }
                PSDrive       = 'RecursePSDrive'
            }

            $Warning = & { Get-Item / | Test-ObjectGraph $Schema -Depth 5 -ValidateOnly | Should -BeFalse } 3>&1
            $Warning | Should -BeLike '*reached the maximum depth of 5*'
            $Ref = @{ Result = $null }
            $Warning = & { $Ref.Result = Get-Item / | Test-ObjectGraph $Schema -Depth 5 } 3>&1
            $Warning | Should -BeLike '*reached the maximum depth of 5*'
            $Ref.Result.Count | Should -BeGreaterOrEqual 1
            $Ref.Result[0].ObjectNode.Path | Should -Be 'PSDrive.Provider.Drives[0].Provider'
            $Ref.Result[0].Valid | Should -BeFalse
            $Ref.Result[0].Issue | Should -BeLike "The requirement *'Drives'* is not met"
        }

        It '[V] Recursive PSItem object (optional Drives)' -Skip:$($PSVersionTable.PSVersion -lt '6.0') {
            $Schema = @{
                '@References' = @{
                    RecursePSDrive = @{
                        '@AnyName' = @()
                        Name       = @{ '@Type' = [String] }
                        Root       = @{ '@Type' = [String] }
                        Used       = @{ '@Type' = [Long], $Null }
                        Provider   = @{
                            '@AnyName' = @()
                            Drives     = @{
                                '@Type'     = [PSListNode]
                                '@Optional' = $true
                                Drive       = 'RecursePSDrive'
                            }
                        }
                    }
                }
                '@AnyName'    = @()
                Mode          = @{ '@Like' = '?????' }
                LastWriteTime = @{ '@Type' = [DateTime] }
                Exists        = @{ '@Type' = [Bool] }
                Name          = @{ '@Type' = [String] }
                PSDrive       = 'RecursePSDrive'
            }

            $Warning = & { Get-Item / | Test-ObjectGraph $Schema -Depth 5 -ValidateOnly | Should -BeTrue } 3>&1
            $Warning | Should -BeLike '*reached the maximum depth of 5*'
            $Ref = @{ Result = $null }
            $Warning = & { $Ref.Result = Get-Item / | Test-ObjectGraph $Schema -Depth 5 } 3>&1
            $Warning | Should -BeLike '*reached the maximum depth of 5*'
            $Ref.Result | Should -BeNullOrEmpty
        }

        It '[V] Recursive PSItem object -Elaborate' -Skip:$($PSVersionTable.PSVersion -lt '6.0') {
            $Schema = @{
                '@References' = @{
                    RecursePSDrive = @{
                        '@AnyName' = @()
                        Name       = @{ '@Type' = [String] }
                        Root       = @{ '@Type' = [String] }
                        Used       = @{ '@Type' = [Long], $Null }
                        Provider   = @{
                            '@AnyName' = @()
                            Drives     = @{
                                '@Type'     = [PSListNode]
                                '@Optional' = $true
                                Drive       = 'RecursePSDrive'
                            }
                        }
                    }
                }
                '@AnyName'    = @()
                Mode          = @{ '@Like' = '?????' }
                LastWriteTime = @{ '@Type' = [DateTime] }
                Exists        = @{ '@Type' = [Bool] }
                Name          = @{ '@Type' = [String] }
                PSDrive       = 'RecursePSDrive'
            }

            $Ref = @{ Result = $null }
            $Warning = & { $Ref.Result = Get-Item / | Test-ObjectGraph $Schema -Depth 5 -Elaborate } 3>&1
            # $Warning | Should -BeLike '*reached the maximum depth of 5*'
            $Ref.Result.Count | Should -BeGreaterThan 10
            $Ref.Result.Valid | Should -BeTrue
            $Ref.Result.ObjectNode.Path | Should -Contain 'PSDrive.Provider.Drives'
        }
    }

    Context 'Embedded keys' {

        It "Names" {

            $Schema = @{
                Names = @{
                    First  = @{ Id = @{ '@Like' = 'First' }; Value = @{ '@Type' = 'String' } }
                    Middle = @{ Id = @{ '@Like' = 'Middle' }; Value = @{ '@Type' = 'String' }; '@Optional' = $true }
                    Last   = @{ Id = @{ '@Like' = 'Last' }; Value = @{ '@Type' = 'String' } }
                }
            }

            @{Names = @(@{Id = 'First'; Value = 'John' }, @{Id = 'Last'; Value = 'Doe' }) }                          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{Names = @(@{Id = 'First'; Value = 'John' }, @{Id = 'Middle'; Value = 'M' }, @{Id = 'Last'; Value = 'Doe' }) } | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            @{Names = @(@{Id = 'First'; Value = 'John' }, @{Id = 'Middle'; Value = 'M' }) }                          | Test-ObjectGraph $Schema -ValidateOnly | Should -BeFalse
        }
    }

    Context 'Different Assert Test Prefix' {

        It "[V] AssertPrefix = '^'" {
            $Schema = @{
                AssertPrefix = '^'
                FirstName    = @{ '^Type' = 'String' }
                LastName     = @{ '^Type' = 'String' }
                IsAlive      = @{ '^Type' = 'Bool' }
                Birthday     = @{ '^Type' = 'DateTime' }
                Age          = @{
                    '^Type'    = 'Int'
                    '^Minimum' = 0
                    '^Maximum' = 99
                }
                Address      = @{
                    '^Type'    = 'PSMapNode'
                    Street     = @{ '^Type' = 'String' }
                    City       = @{ '^Type' = 'String' }
                    State      = @{ '^Type' = 'String' }
                    PostalCode = @{ '^Type' = 'String' }
                }
                Phone        = @{
                    '^Type' = 'PSMapNode', $Null
                    Home    = @{ '^Type' = 'String', 'PSListNode'; '^Match' = '^\d{3} \d{3}-\d{4}$'; '^AnyName' = @() }
                    Mobile  = @{ '^Type' = 'String', 'PSListNode'; '^Match' = '^\d{3} \d{3}-\d{4}$'; '^AnyName' = @() }
                    Work    = @{ '^Type' = 'String', 'PSListNode'; '^Match' = '^\d{3} \d{3}-\d{4}$'; '^AnyName' = @() }
                }
                Children     = @(@{ '^Type' = 'String', $Null })
                Spouse       = @{ '^Type' = 'String', $Null }
            }
            $Person | Test-ObjectGraph $Schema -ValidateOnly | Should -BeTrue
            $Person | Test-ObjectGraph $Schema | Should -BeNullOrEmpty
        }

    }

    Context 'Error handling' {

        It 'Unknown assert' {
            { 1 | Test-ObjectGraph @{ '@Type' = [int]; '@UnknownAssert' = $true } } | Should -Throw -ExpectedMessage "*Unknown Assert: 'UnknownAssert'"
        }
    }

    #Region Github issues

    Context '#126 [Test-ObjectGraph] Parents of failing item are also included in the output' {

        It 'IncorrectParameterName' {
            $data = @{
                NonNodeData = @{
                    AzureAD = @{
                        IncorrectParameterName = @(
                            @{
                                Param1 = 8
                            }
                        )
                    }
                }
            }

            $Schema = @{
                NonNodeData = @{
                    '@Type' = 'PSMapNode'
                    AzureAD = @{
                        '@Type' = 'PSMapNode'
                    }
                }
            }

            $data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Result = $data | Test-Object $Schema
            $Result | Should -HaveCount 1
        }
    }

    Context '#129 [Test-ObjectGraph] When the schema specifies that a parameter is required and another parameter is not correct, that other parameter is not listed as failed.' {

        It 'DefaultLength = [string]' {
            $Schema = @{
                NonNodeData = @{
                    '@Type' = 'PSMapNode'
                    AzureAD = @{
                        '@Type'                    = 'PSMapNode'
                        AuthenticationMethodPolicy = @(
                            @{
                                '@Type'                  = 'PSMapNode'
                                DefaultLength            = @{ '@Type' = 'Int' }
                                DefaultLifetimeInMinutes = @{ '@Type' = 'Int' }
                                Ensure                   = @{ '@Type' = 'String'; '@Optional' = $true }
                                Id                       = @{ '@Type' = 'String'; '@Optional' = $true }
                                IncludeTargets           = @{
                                    '@Optional' = $true
                                    target      = @{
                                        '@Type'    = 'PSMapNode'
                                        Id         = @{ '@Type' = 'String' }
                                        TargetType = @{ '@Type' = 'String' }
                                    }
                                }
                                IsUsableOnce             = @{ '@Type' = 'Bool'; '@Optional' = $true }
                                MaximumLifetimeInMinutes = @{ '@Type' = 'Int'; '@Optional' = $true }
                                MinimumLifetimeInMinutes = @{ '@Type' = 'Int'; '@Optional' = $true }
                                State                    = @{ '@Type' = 'String'; '@Optional' = $true }
                            }
                        )
                    }
                }
            }

            $data = @{
                NonNodeData = @{
                    AzureAD = @{
                        AuthenticationMethodPolicy = @(
                            @{
                                DefaultLength            = 'string'
                                DoesNotExist             = 'string'
                                DefaultLifetimeInMinutes = 10
                            }
                        )
                    }
                }
            }

            $data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = $data | Test-Object $Schema | Select-Issue
            $Issues.Count | Should -Be 2
            $Issues | Should -Contain "Node 'DoesNotExist' is denied"
            $Issues | Should -Contain "'string' is not of type 'Int'"
        }
    }

    Context '#129 Using @Requires' {

        It 'DefaultLength = [string]' {
            $Schema = @{
                NonNodeData = @{
                    '@Type' = 'PSMapNode'
                    AzureAD = @{
                        '@Type'                    = 'PSMapNode'
                        AuthenticationMethodPolicy = @(
                            @{
                                '@Type'                  = 'PSMapNode'
                                '@Requires'              = 'DefaultLength', 'DefaultLifetimeInMinutes'
                                DefaultLength            = @{ '@Type' = 'Int' }
                                DefaultLifetimeInMinutes = @{ '@Type' = 'Int' }
                                Ensure                   = @{ '@Type' = 'String' }
                                Id                       = @{ '@Type' = 'String' }
                                IncludeTargets           = @{
                                    target = @{
                                        '@Type'    = 'PSMapNode'
                                        Id         = @{ '@Type' = 'String' }
                                        TargetType = @{ '@Type' = 'String' }
                                    }
                                }
                                IsUsableOnce             = @{ '@Type' = 'Bool' }
                                MaximumLifetimeInMinutes = @{ '@Type' = 'Int' }
                                MinimumLifetimeInMinutes = @{ '@Type' = 'Int' }
                                State                    = @{ '@Type' = 'String' }
                            }
                        )
                    }
                }
            }

            $data = @{
                NonNodeData = @{
                    AzureAD = @{
                        AuthenticationMethodPolicy = @(
                            @{
                                DefaultLength            = 'string'
                                DoesNotExist             = 'string'
                                DefaultLifetimeInMinutes = 10
                            }
                        )
                    }
                }
            }

            $data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = $data | Test-Object $Schema | Select-Issue
            $Issues.Count | Should -Be 2
            $Issues | Should -Contain "Node 'DoesNotExist' is denied"
            $Issues | Should -Contain "'string' is not of type 'Int'"
        }

        It '#129 [V] A FMO application' {

            $Schema = @{
                Company = @{
                    '@Type'    = 'Array'
                    '@AnyName' = @()
                    FMO        = @{
                        Env = @{ '@Type' = 'String'; '@Like' = 'FMO' }
                        Id  = @{ '@Type' = 'Int'; '@Minimum' = 2000 }
                    }
                }
            }

            $Data = @{
                Company = @(
                    @{ Env = 'CMO'; Id = 1234 },
                    @{ Env = 'FMO'; Id = 1235 },
                    @{ Env = 'FMO'; Id = 2345 }
                )
            }

            $data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It '#129 [X] A FMO application' {

            $Schema = @{
                Company = @{
                    '@Type'    = 'Array'
                    '@AnyName' = @()
                    FMO        = @{
                        Env = @{ '@Type' = 'String'; '@Like' = 'FMO' }
                        Id  = @{ '@Type' = 'Int'; '@Minimum' = 2000 }
                    }
                }
            }

            $Data = @{
                Company = @(
                    @{ Env = 'CMO'; Id = 1234 },
                    @{ Env = 'FMO'; Id = 1235 },
                    @{ Env = 'XMO'; Id = 2345 } # Env name typo
                )
            }

            $Data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Data | Test-Object $Schema | Select-Issue | Should -Be "The requirement 'FMO' is missing"
        }

        It '#129 [V] A Company wide application' {

            $Schema = @{
                Company = @{
                    '@Type'     = 'Array'
                    '@Requires' = 'CMO or FMO'
                    CMO         = @{
                        Env = @{ '@Type' = 'String'; '@Like' = 'CMO' }
                        Id  = @{ '@Type' = 'Int'; '@Maximum' = 1999 }
                    }
                    FMO         = @{
                        Env = @{ '@Type' = 'String'; '@Like' = 'FMO' }
                        Id  = @{ '@Type' = 'Int'; '@Minimum' = 2000 }
                    }
                }
            }

            $Data = @{
                Company = @(
                    @{ Env = 'CMO'; Id = 1234 },
                    @{ Env = 'FMO'; Id = 2345 },
                    @{ Env = 'FMO'; Id = 3456 }
                )
            }

            $data | Test-Object $Schema -ValidateOnly | Should -BeTrue
            $Result = $data | Test-Object $Schema | Should -BeNullOrEmpty
        }

        It '#129 [X] A Company wide application' {

            $Schema = @{
                Company = @{
                    '@Type'     = 'Array'
                    '@Requires' = 'CMO or FMO'
                    CMO         = @{
                        Env = @{ '@Type' = 'String'; '@Like' = 'CMO' }
                        Id  = @{ '@Type' = 'Int'; '@Maximum' = 1999 }
                    }
                    FMO         = @{
                        Env = @{ '@Type' = 'String'; '@Like' = 'FMO' }
                        Id  = @{ '@Type' = 'Int'; '@Minimum' = 2000 }
                    }
                }
            }

            $Data = @{
                Company = @(
                    @{ Env = 'CMO'; Id = 1234 },
                    @{ Env = 'FMO'; Id = 1235 }, # Id should be >= 2000
                    @{ Env = 'FMO'; Id = 2345 }
                )
            }

            $data | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Result = $data | Test-Object $Schema
            $Result.Count | Should -BeGreaterOrEqual 1
            # $Result | Select-Issue | Should -Contain "The value 1235 is less or equal than 2000"
        }

    }

    Context '#142 @MinimumCount' {

        BeforeAll {
            $Schema = @{
                'Minimal 3 Strings'  = @{ '@Type' = [String]; '@MinimumCount' = 3 }
                'Minimal 3 Integers' = @{ '@Type' = [Int]; '@MinimumCount' = 3 }
            }
        }

        It "1, 'two', 3, 'four'" {
            , @(1, 'two', 3, 'four') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four') | Test-Object $Schema | Select-Issue
            $Issues.Count | Should -Be 2
            $Issues | Should -Contain "'Minimal 3 Strings' occurred less than 3 times"
            $Issues | Should -Contain "'Minimal 3 Integers' occurred less than 3 times"
        }

        It "1, 'two', 3, 'four', 5" {
            , @(1, 'two', 3, 'four', 5) | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four', 5) | Test-Object $Schema | Select-Issue
            $Issues | Should -Be "'Minimal 3 Strings' occurred less than 3 times"
        }

        It "1, 'two', 3, 'four', 'five'" {
            , @(1, 'two', 3, 'four', 'five') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four', 'five') | Test-Object $Schema | Select-Issue
            $Issues | Should -Be "'Minimal 3 Integers' occurred less than 3 times"
        }

        It 'Valid' {
            , @(1, 'two', 3, 'four', 5, 'six')             | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 'two', 3, 'four', 5, 'six', 7)          | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 'two', 3, 'four', 5, 'six', 7, 'Eight') | Test-Object $Schema -ValidateOnly | Should -BeTrue
        }
    }

    Context '#142 @MaximumCount' {

        BeforeAll {
            $Schema = @{
                'Maximal 2 Strings'  = @{ '@Type' = [String]; '@MaximumCount' = 2 }
                'Maximal 2 Integers' = @{ '@Type' = [Int]; '@MaximumCount' = 2 }
            }
        }

        It 'Valid' {
            , @(1, 'two')            | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 'two', 3)         | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @('One', 2, 'Three')   | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 'two', 3, 'four') | Test-Object $Schema -ValidateOnly | Should -BeTrue
        }

        It "1, 2" {
            , @(1, 2) | Test-Object $Schema -ValidateOnly | Should -BeFalse
            , @(1, 2) | Test-Object $Schema | Select-Issue | Should -Be "The requirement 'Maximal 2 Strings' is missing"
        }

        It "'one', 'two'" {
            , @('one', 'two') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            , @('one', 'two') | Test-Object $Schema | Select-Issue | Should -Be "The requirement 'Maximal 2 Integers' is missing"
        }

        It "1, 'two', 3, 'four', 5" {
            , @(1, 'two', 3, 'four', 5) | Test-Object $Schema -ValidateOnly | Should -BeFalse
            , @(1, 'two', 3, 'four', 5) | Test-Object $Schema | Select-Issue | Should -Be "'Maximal 2 Integers' occurred more than 2 times"
        }

        It "1, 'two', 3, 'four', 'five'" {
            , @(1, 'two', 3, 'four', 'five') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            , @(1, 'two', 3, 'four', 'five') | Test-Object $Schema | Select-Issue | Should -Be "'Maximal 2 Strings' occurred more than 2 times"
        }

        It "1, 'two', 3, 'four', 5, 'Six'" {
            , @(1, 'two', 3, 'four', 5, 'Six') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four', 5, 'Six') | Test-Object $Schema | Select-Issue
            $Issues.Count | Should -Be 2
            $Issues[0] | Should -BeLike "'*' occurred more than 2 times"
            $Issues[1] | Should -BeLike "* is not of type '*'"
        }
    }

    Context '#142 @Count' {

        BeforeAll {
            $Schema = @{
                '3 Strings'  = @{ '@Type' = [String]; '@Count' = 3 }
                '3 Integers' = @{ '@Type' = [Int]; '@Count' = 3 }
            }
        }

        It "1, 'two', 3, 'four'" {
            , @(1, 'two', 3, 'four') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four') | Test-Object $Schema | Select-Issue
            $Issues.Count | Should -Be 4
            $Issues | Should -Contain "'3 Integers' occurred more than 3 times"
            $Issues | Should -Contain "'two' is not of type 'int'"
            $Issues | Should -Contain "'four' is not of type 'int'"
            $Issues | Should -Contain "'3 Strings' occurred less than 3 times"
        }

        It "1, 'two', 3, 'four', 5" {
            , @(1, 'two', 3, 'four', 5) | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four', 5) | Test-Object $Schema | Select-Issue
            $Issues | Should -Be "'3 Strings' occurred less than 3 times"
        }

        It "1, 'two', 3, 'four', 'five'" {
            , @(1, 'two', 3, 'four', 'five') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 3, 'four', 'five') | Test-Object $Schema | Select-Issue
            $Issues | Should -Be "'3 Integers' occurred less than 3 times"
        }

        It 'Valid' {
            , @(1, 'two', 3, 'four', 5, 'Six') | Test-Object $Schema -ValidateOnly | Should -BeTrue
        }

        It "1, 2, 3, 4, 'Five'" {
            , @(1, 2, 3, 4, 'Five') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 2, 3, 4, 'Five') | Test-Object $Schema | Select-Issue
            $Issues | Should -Contain "'3 Strings' occurred less than 3 times"
        }

        It "1, 'two', 'three', 'four', 'five'" {
            , @(1, 'two', 'three', 'four', 'five') | Test-Object $Schema -ValidateOnly | Should -BeFalse
            $Issues = , @(1, 'two', 'three', 'four', 'five') | Test-Object $Schema | Select-Issue
            $Issues.Count | Should -Be 2
            $Issues | Should -Contain "'3 Integers' occurred less than 3 times"
            $Issues | Should -Contain "'three' is not of type 'int'"
        }
    }

    Context '#142 @Conditional @MaximumCount' {

        BeforeAll {
            $Schema = @{
                'Maximal 2 Strings'  = @{ '@Type' = [String]; '@Optional' = $true; '@MaximumCount' = 2 }
                'Maximal 2 Integers' = @{ '@Type' = [Int];    '@Optional' = $true; '@MaximumCount' = 2 }
            }
        }

        It 'Valid' {
            , @()                      | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1)                     | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @('One')                 | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 2)                  | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 'Two')              | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 2, 'Three')         | Test-Object $Schema -ValidateOnly | Should -BeTrue
            , @(1, 2, 'Three', 'Four') | Test-Object $Schema -ValidateOnly | Should -BeTrue
        }

        It 'Too many Integers' {
            ,@(1, 2 ,3)                 | Test-Object $Schema | Select-Issue | Should -be "'Maximal 2 Integers' occurred more than 2 times"
            ,@(1, 2 ,3, 'four')         | Test-Object $Schema | Select-Issue | Should -be "'Maximal 2 Integers' occurred more than 2 times"
            ,@(1, 2 ,3, 'Four', 'Five') | Test-Object $Schema | Select-Issue | Should -be "'Maximal 2 Integers' occurred more than 2 times"
        }
    }
    #EndRegion Github issues
}