#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
param()

Describe 'Get-ChildNode' {

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

    Context 'Parameters' {

        it 'All child nodes' {
            $Nodes = $Object | Get-ChildNode
            $Nodes.Count | Should -Be 2
        }

        it 'All decedent nodes' {
            $Nodes = $Object | Get-ChildNode -Recurse
            $Nodes.Count | Should -Be 14
        }

        it 'All leaf nodes' {
            $Nodes = $Object | Get-ChildNode -LeafNode
            $Nodes.Name  | Should -Be Comment
        }

        it 'All decedent leaf nodes' {
            $Nodes = $Object | Get-ChildNode -LeafNode -Recurse
            $Nodes.Count | Should -Be 10
        }

        it 'All list child nodes' {
            $Nodes = $Object | Get-ChildNode -ListChild
            $Nodes | Should -BeNullOrEmpty
        }

        it 'All decedent list child nodes' {
            $Nodes = $Object | Get-ChildNode -ListChild -Recurse
            $Nodes.Name  | Should -Be 0, 1, 2
        }

        it 'All map child nodes' {
            $Nodes = $Object | Get-ChildNode -Include *
            $Nodes.Name  | Should -Be Data, Comment
        }

        it 'All map leaf nodes' {
            $Nodes = $Object | Get-ChildNode -Include * -LeafNode
            $Nodes.Name  | Should -Be Comment
        }

        it 'All decedent map child nodes' {
            $Nodes = $Object | Get-ChildNode -Include * -Recurse
            $Nodes.Count | Should -Be 11
        }

        it 'All decedent map leaf nodes' {
            $Nodes = $Object | Get-ChildNode -Include * -Recurse -LeafNode
            $Nodes.Count | Should -Be 10
        }

        it 'All decedent map nodes named index' {
            $Nodes = $Object | Get-ChildNode -Include Index -Recurse
            $Nodes.Value | Should -Be 1, 2, 3
        }
    }
}