#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
param()

Describe 'Copy-ObjectGraph' {

    BeforeAll {
        Set-StrictMode -Version Latest

        $Object = @{
            String = 'Hello World'
            Array = @(
                @{ Index = 1; Name = 'One';   Comment = 'First item'  }
                @{ Index = 2; Name = 'Two';   Comment = 'Second item' }
                @{ Index = 3; Name = 'Three'; Comment = 'Third item'  }
            )
            HashTable = @{ One = 1; Two = 2; Three = 3 }
            PSCustomObject = [PSCustomObject]@{ One = 1; Two = 2; Three = 3 }
        }
    }

    Context 'Sanity Check' {

        It 'Help' {
            Copy-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Copy' {

        It 'Default' {
            $Copy = Copy-ObjectGraph $Object
            $Copy.String         | Should -Be 'Hello World'
            ,$Copy.Array         | Should -BeOfType 'Array'
            $Copy.HashTable      | Should -BeOfType 'HashTable'
            $Copy.PSCustomObject | Should -BeOfType 'PSCustomObject'
            $Copy | Compare-ObjectGraph $Object -IsEqual | Should -BeTrue
            $Copy.String = 'Something else'
            $Copy | Compare-ObjectGraph $Object -IsEqual | Should -BeFalse
        }

        It 'Convert to list' {
            $Copy = Copy-ObjectGraph $Object -ListAs System.Collections.Generic.List[Object]
            ,$Copy.Array | Should -BeOfType 'System.Collections.Generic.List[Object]'
            $Copy | Compare-ObjectGraph $Object -IsEqual | Should -BeTrue
        }

        It 'Convert to ordered' {
            $Copy = Copy-ObjectGraph $Object -MapAs ([Ordered]@{})
            $Copy.HashTable      | Should -BeOfType 'System.Collections.Specialized.OrderedDictionary'
            $Copy.PSCustomObject | Should -BeOfType 'System.Collections.Specialized.OrderedDictionary'
            $Copy | Compare-ObjectGraph $Object -IsEqual | Should -BeTrue
        }

        It 'Convert to PSCustomObject' {
            $Copy = Copy-ObjectGraph $Object -MapAs PSCustomObject
            $Copy.HashTable      | Should -BeOfType 'PSCustomObject'
            $Copy.PSCustomObject | Should -BeOfType 'PSCustomObject'
            $Copy | Compare-ObjectGraph $Object -IsEqual | Should -BeTrue
        }
    }
    Context 'Issues' {

        It '#40: Numeric keys' {
            $PSCustomObject = @{ 1 = 'a' } | Copy-ObjectGraph -MapAs PSCustomObject
            $PSCustomObject.1 | Should -Be a
        }

        It '#50 -ListAs Array gives error' {
            $Copy = Copy-ObjectGraph $Object -ListAs array
            ,$Copy.Array | Should -BeOfType Array
            $Copy | Compare-ObjectGraph $Object -IsEqual | Should -BeTrue
        }
    }
}