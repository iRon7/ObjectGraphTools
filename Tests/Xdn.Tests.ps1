#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'ObjectGraph', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'RootNode', Justification = 'False positive')]
param()

Describe 'Extended Dot Notation' {

    BeforeAll {

        Set-StrictMode -Version Latest

    }
    
    Context 'Existence Check' {

        It 'Help' {
            Get-Node -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Path' {

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
            $RootNode = [PSNode]::ParseInput($ObjectGraph)
        }

        it 'Member-Access Enumeration' {
            $Titles = $RootNode.GetNode('BookStore.Book.Title')
            $Titles.Count | Should -be 2
            $Titles.Value | Sort-Object | Should -Be 'Harry Potter', 'Learning PowerShell'
        }

        it 'Wildcard selection' {
            $Nodes = $RootNode.GetNode('BookStore.Book.*')
            $Nodes.Count | Should -be 4
            $Nodes.Value | Sort-Object | Should -Be 29.99, 39.95, 'Harry Potter',  'Learning PowerShell'
        }

        it 'Ancestor selector' {
            $1stTitle = $RootNode.GetNode('BookStore[0].Book.Title')
            $1StBook = $1stTitle.GetNode('..')
            $1stBook.PathName | Should -be BookStore[0].Book
        }

        it 'Descendant selector' {
            $Titles = $RootNode.GetNode('BookStore~Title')
            $Titles.Count | Should -be 2
            $Titles.Value | Sort-Object | Should -Be 'Harry Potter', 'Learning PowerShell'
        }

        it 'Equals filter' {
            $Price = $RootNode.GetNode('BookStore~Title=*PowerShell*..Price')
            $Price.Value | Should -Be 39.95
        }

        it 'Or selection list' {
            $Title = $RootNode.GetNode('BookStore~Title=*JavaScript*/*PowerShell*/*Python*')
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
            $RootNode = [PSNode]::ParseInput($ObjectGraph)
        }

        it 'Update price' {
            $Price = $RootNode.GetNode('BookStore~Title=*PowerShell*..Price')
            $Price.Value | Should -Be 39.95
            $Price.Value = 24.95

            $NewPrice = $RootNode.GetNode('BookStore~Title=*PowerShell*..Price')
            $NewPrice.Value | Should -Be 24.95
        }

    }
}