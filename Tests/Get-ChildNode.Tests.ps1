#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

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

    Context 'Existence Check' {

        It 'Help' {
            Get-Node -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Basic selection' {

        it 'All child nodes' {
            $Nodes = $Object | Get-ChildNode
            $Nodes.Count | Should -Be 2
        }

        it 'All decedent nodes' {
            $Nodes = $Object | Get-ChildNode -Recurse
            $Nodes.Count | Should -Be 14
        }

        it 'All decedent nodes including self' {
            $Nodes = $Object | Get-ChildNode -Recurse -IncludeSelf
            $Nodes.Count | Should -Be 15
        }

        it 'All leaf nodes' {
            $Nodes = $Object | Get-ChildNode -Leaf
            $Nodes.Name  | Should -Be Comment
        }

        it 'All decedent leaf nodes' {
            $Nodes = $Object | Get-ChildNode -Leaf -Recurse
            $Nodes.Count | Should -Be 10
        }

        it 'All list child nodes' {
            $Nodes = $Object | Get-ChildNode -ListChild
            $Nodes.Name | Sort-Object | Should -Be 0, 1, 2
        }

        it 'All decedent list child nodes' {
            $Nodes = $Object | Get-ChildNode -ListChild -Recurse
            $Nodes.Name | Sort-Object | Should -Be 0, 1, 2
        }

        it 'All map child nodes' {
            $Nodes = $Object | Get-ChildNode -Include *
            $Nodes.Name | Sort-Object | Should -Be Comment, Data
        }

        it 'All map leaf nodes' {
            $Nodes = $Object | Get-ChildNode -Include * -Leaf
            $Nodes.Name  | Should -Be Comment
        }

        it 'All decedent map child nodes' {
            $Nodes = $Object | Get-ChildNode -Include * -Recurse
            $Nodes.Count | Should -Be 11
        }

        it 'All decedent map leaf nodes' {
            $Nodes = $Object | Get-ChildNode -Include * -Recurse -Leaf
            $Nodes.Count | Should -Be 10
        }

        it 'All decedent map nodes named index' {
            $Nodes = $Object | Get-ChildNode -Include Index -Recurse
            $Nodes.Value | Sort-Object | Should -Be 1, 2, 3
        }
    }

    Context 'By name' {

        it 'Include single literal' {
            $Nodes = $Object | Get-ChildNode -Recurse -Include Comment -Literal
            $Nodes.Count | Should -Be 4
            $Nodes.Name | Sort-Object -Unique | Should -Be Comment
        }

        it 'Exclude single literal' {
            $Nodes = $Object | Get-ChildNode -Recurse -Exclude Comment -Literal
            $Nodes.Count | Should -Be 7
            $Nodes.Name | Sort-Object -Unique | Should -Be 'Data', 'Index', 'Name'
        }

        it 'Include single wildcard' {
            $Nodes = $Object | Get-ChildNode -Recurse -Include Comm?nt
            $Nodes.Count | Should -Be 4
            $Nodes.Name | Sort-Object -Unique | Should -Be Comment
        }

        it 'Exclude single wildcard' {
            $Nodes = $Object | Get-ChildNode -Recurse -Exclude Comm?nt
            $Nodes.Count | Should -Be 7
            $Nodes.Name | Sort-Object -Unique | Should -Be 'Data', 'Index', 'Name'
        }

        it 'Include multiple literal' {
            $Nodes = $Object | Get-ChildNode -Recurse -Include Comment, Name -Literal
            $Nodes.Count | Should -Be 7
            $Nodes.Name | Sort-Object -Unique | Should -Be Comment, Name
        }

        it 'Exclude multiple literal' {
            $Nodes = $Object | Get-ChildNode -Recurse -Exclude Comment, Name -Literal
            $Nodes.Count | Should -Be 4
            $Nodes.Name | Sort-Object -Unique | Should -Be 'Data', 'Index'
        }

        it 'Include multiple wildcard' {
            $Nodes = $Object | Get-ChildNode -Recurse -Include Com*, Nam?
            $Nodes.Count | Should -Be 7
            $Nodes.Name | Sort-Object -Unique | Should -Be Comment, Name
        }

        it 'Exclude multiple wildcard' {
            $Nodes = $Object | Get-ChildNode -Recurse -Exclude Com*, Nam?
            $Nodes.Count | Should -Be 4
            $Nodes.Name | Sort-Object -Unique | Should -Be 'Data', 'Index'
        }
    }

    Context 'ValueOnly' {

        It 'Leaf node by name' {

            $Object | Get-ChildNode -Recurse -Value -Include Name | Should -be 'One', 'Two', 'Three'
        }
    }

    Context 'Warnings' {

        it 'Is a leaf node' {
            $LeafNode = $Object | Get-ChildNode Comment
            $Output = $LeafNode | Get-ChildNode 3>&1
            $Output.where{$_ -is [System.Management.Automation.WarningRecord]}.Message | Should -BeLike  '*is a leaf node*'
        }
    }
}