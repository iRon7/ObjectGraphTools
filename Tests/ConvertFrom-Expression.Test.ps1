#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Expression', Justification = 'False positive')]
param()

Describe 'ConvertFrom-Expression' {

    BeforeAll {

        # Set-StrictMode -Version Latest
    }

    Context 'Existence Check' {

        It 'Help' {
            ConvertFrom-Expression -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Constrained values' {

        BeforeAll {

            $Expression = @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    birthday = [DateTime]'Monday,  October 7,  1963 10:47:00 PM'
    age = 27
    address = [PSCustomObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }

        It "Restricted mode" {
            $Object = $Expression | ConvertFrom-Expression
            $Object | Should -BeOfType HashTable
            $Object.Keys | Sort-Object | Should -Be 'address', 'age', 'birthday', 'children', 'first_name', 'is_alive', 'last_name', 'phone_numbers', 'spouse'
        }

        It "Constrained mode" {
            $Object = $Expression | ConvertFrom-Expression -LanguageMode Constrained
            $Object | ConvertTo-Expression -LanguageMode Constrained | Should -be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    birthday = [datetime]'1963-10-07T22:47:00.0000000'
    age = 27
    address = [PSCustomObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
    }

    Context 'Issues' {

        It '#90 Add $PSCulture and $PSUICulture to the restricted language mode cmdlets and classes' {
            '@{ Culture = $PSCulture }'   | ConvertFrom-Expression | ConvertTo-Expression | Should -be "@{ Culture = '$PSCulture' }"
            '@{ Culture = $PSUICulture }' | ConvertFrom-Expression | ConvertTo-Expression | Should -be "@{ Culture = '$PSUICulture' }"
        }
    }
}
