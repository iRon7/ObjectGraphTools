#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object',     Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Expression', Justification = 'False positive')]
param()

# $PesterPreference = [PesterConfiguration]::Default
# $PesterPreference.Should.ErrorAction = 'Stop'

Describe 'Import-ObjectGraph' {

    BeforeAll {

        # Set-StrictMode -Version Latest

        $PS1File  = Join-Path $Env:Temp 'ObjectGraph.ps1'
        $PSD1File = Join-Path $Env:Temp 'ObjectGraph.psd1'

        $Expression = @'
@{
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

        $Expression | Set-Content -LiteralPath $PS1File
        $Expression | Set-Content -LiteralPath $PSD1File
    }

    Context 'Existence Check' {

        It 'Help' {
            Import-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'PowerShell data (.psd1) file' {

        It "Default" {
            $Object = Import-ObjectGraph $PSD1File
            $Object            | Should -BeOfType PSCustomObject
            $Object.PSObject.Properties.Name | Should -Be 'first_name', 'last_name', 'is_alive', 'birthday', 'age', 'address', 'phone_numbers', 'children', 'spouse'
            $Object.first_name | Should -BeOfType String
            $Object.birthday   | Should -BeOfType String
            $Object.address    | Should -BeOfType PSCustomObject
            ,$Object.children  | Should -BeOfType Array
        }

        It "AsHashTable" {
            $Object = Import-ObjectGraph $PSD1File -HashTableAs @{}
            $Object            | Should -BeOfType HashTable
            $Object.Keys       | Sort-Object | Should -Be 'address', 'age', 'birthday', 'children', 'first_name', 'is_alive', 'last_name', 'phone_numbers', 'spouse'
            $Object.Address    | Should -not -BeNullOrEmpty  # Cash insensitive
            $Object.first_name | Should -BeOfType String
            $Object.birthday   | Should -BeOfType String
            $Object.address    | Should -BeOfType HashTable
            ,$Object.children  | Should -BeOfType Array
        }
    }


    Context 'PowerShell (.ps1) file' {

        It "Default" {
            $Object = Import-ObjectGraph $PS1File
            $Object            | Should -BeOfType HashTable
            $Object.Keys       | Sort-Object | Should -Be 'address', 'age', 'birthday', 'children', 'first_name', 'is_alive', 'last_name', 'phone_numbers', 'spouse'
            $Object.first_name | Should -BeOfType String
            $Object.birthday   | Should -BeOfType DateTime
            $Object.address    | Should -BeOfType PSCustomObject
            ,$Object.children  | Should -BeOfType Array
        }

        It "Restricted" {
            $Object = Import-ObjectGraph $PS1File -LanguageMode Restricted
            $Object            | Should -BeOfType HashTable
            $Object.Keys       | Sort-Object | Should -Be 'address', 'age', 'birthday', 'children', 'first_name', 'is_alive', 'last_name', 'phone_numbers', 'spouse'
            $Object.first_name | Should -BeOfType String
            $Object.birthday   | Should -BeOfType String
            $Object.address    | Should -BeOfType HashTable
            ,$Object.children  | Should -BeOfType Array
        }
    }

    AfterAll {
        Remove-Item -LiteralPath $PS1File
        Remove-Item -LiteralPath $PSD1File
    }
}
