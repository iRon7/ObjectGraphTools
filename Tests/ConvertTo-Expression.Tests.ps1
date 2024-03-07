#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'ObjectGraph', Justification = 'False positive')]
param()

Describe 'ConvertTo-Expression' {

    BeforeAll {

        Set-StrictMode -Version Latest

        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                @{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                @{
                    Index = 2
                    Name = 'Two'
                    Comment = 'Second item'
                }
                @{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }
    }

    Context 'Existence Check' {

        It 'Help' {
            ConvertTo-Expression -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }
    Context 'Issues' {

        It '#59 quoting bug' {
            @{ Test = "foo'bar" } | ConvertTo-Expression | Should -Contain "    Test = 'foo''bar'"
        }
    }
}