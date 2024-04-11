#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Expression', Justification = 'False positive')]
param()

# $PesterPreference = [PesterConfiguration]::Default
# $PesterPreference.Should.ErrorAction = 'Stop'

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
    phone_numbers =[PSCustomObject] @(
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }

        It "Restricted mode" {

            Write-Host 122 $Expression.Length
            $Object = $Expression | ConvertFrom-Expression
            Write-Host 123 $Object
            $Object | ConvertTo-Expression -LanguageMode Constrained | Should -be @'
@{
    spouse = $Null
    phone_numbers = @(
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
    )
    children = @('Catherine')
    is_alive = $True
    address = @{
        state = 'NY'
        postal_code = '10021-3100'
        street_address = '21 2nd Street'
        city = 'New York'
    }
    birthday = 'Monday,  October 7,  1963 10:47:00 PM'
    first_name = 'John'
    last_name = 'Smith'
    age = 27
}
'@
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
}
