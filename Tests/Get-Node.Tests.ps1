#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'ObjectGraph', Justification = 'False positive')]
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

    Context 'Existence Check' {

        It 'Help' {
            Get-Node -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Root' {

        it 'String' {
            $Node = 'Hello World' | Get-Node
            $Node -is [PSNode] | Should -BeTrue
            $Node.Value | Should -Be 'Hello World'
        }

        it 'Object' {
            $Node = $Object | Get-Node
            $Node -is [PSNode]           | Should -BeTrue
            $Node -is [PSCollectionNode] | Should -BeTrue
            $Node -is [PSMapNode]        | Should -BeTrue
            $Node -is [PSDictionaryNode] | Should -BeTrue
        }
    }

    Context 'by PathName' {

        it 'Get data node' {
            $Data = $Object | Get-Node Data
            $Data -is [PSListNode] | Should -BeTrue
        }

        it 'Get the first comment node' {
            $Comment = $Object | Get-Node Data[0].Comment
            $Comment.Value | Should -Be 'First item'
        }
    }

    Context 'Extended Dot Notation' {

        BeforeAll {
            $ObjectGraph =
                @{
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
        }

        it 'Member-Access Enumeration' {
            $Titles = $ObjectGraph | Get-Node BookStore.Book.Title
            $Titles.Count | Should -be 2
            $Titles.Value | Sort-Object | Should -Be 'Harry Potter', 'Learning PowerShell'
        }

        it 'Wildcard selection' {
            $Nodes = $ObjectGraph | Get-Node BookStore.Book.*
            $Nodes.Count | Should -be 4
            $Nodes.Value | Sort-Object | Should -Be 29.99, 39.95, 'Harry Potter',  'Learning PowerShell'
        }

        it 'Ancestor selector' {
            $1stTitle = $ObjectGraph | Get-Node BookStore[0].Book.Title
            $1StBook = $1stTitle | Get-Node ..
            $1stBook.PathName | Should -be BookStore[0].Book
        }

        it 'Descendant selector' {
            $Titles = $ObjectGraph | Get-Node BookStore~Title
            $Titles.Count | Should -be 2
            $Titles.Value | Sort-Object | Should -Be 'Harry Potter', 'Learning PowerShell'
        }

        it 'Equals filter' {
            $Price = $ObjectGraph | Get-Node BookStore~Title=*PowerShell*..Price
            $Price.Value | Should -Be 39.95
        }

        it 'Or selection list' {
            $Title = $ObjectGraph | Get-Node BookStore~Title=*JavaScript*/*PowerShell*/*Python*
            $Title.Value | Should -Be 'Learning PowerShell'
        }

    }

    Context 'Change value' {

        BeforeAll {
            $ObjectGraph =
                @{
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
        }

        it 'Update price' {
            $Price = $ObjectGraph | Get-Node BookStore~Title=*PowerShell*..Price
            $Price.Value | Should -Be 39.95
            $Price.Value = 24.95

            $NewPrice = $ObjectGraph | Get-Node BookStore~Title=*PowerShell*..Price
            $NewPrice.Value | Should -Be 24.95
        }

    }
}