#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
param()

Describe 'Get-Node' {

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

    Context 'Sanity Check' {

        It 'Help' {
            Get-Node -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Root' {

        it 'String' {
            $Node = Get-Node 'Hello World'
            $Node       | Should -BeOfType PSNode
            $Node.Value | Should -Be 'Hello World'
        }

        it 'Object' {
            $Node = Get-Node $Object
            $Node | Should -BeOfType PSNode
            $Node | Should -BeOfType PSCollectionNode
            $Node | Should -BeOfType PSMapNode
            $Node | Should -BeOfType PSDictionaryNode
        }
    }

    Context 'by PathName' {

        it 'Get data node' {
            $Data = '.Data' | Get-Node $Object
            $Data | Should -BeOfType PSListNode
        }

        it 'Get the first comment node' {
            $Comment = '.Data[0].Comment' | Get-Node $Object
            $Comment.Value | Should -Be 'First item'
        }
    }

    Context 'By Array' {

        it 'Get data node' {
            $Data = 'Data' | Get-Node $Object
            $Data | Should -BeOfType PSListNode
        }

        it 'Get the first comment node' {
            $Comment = ,@('Data', 0, 'Comment') | Get-Node $Object
            $Comment.Value | Should -Be 'First item'
        }
    }
}