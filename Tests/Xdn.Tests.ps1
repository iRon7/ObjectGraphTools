#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'XdnPath', Justification = 'False positive')]
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

    Context 'XdnPath class' {

        BeforeAll {
            $XdnPath = [XdnPath]'"Book Store"~Title=*PowerShell*/*Python*..Price'
        }

        it 'ToString' {
            $XdnPath.ToString('<Root>') | Should -be "<Root>.'Book Store'~Title=*PowerShell*/*Python*..Price"
        }

        it 'ToColoredString' {
            $Esc = [Char]0x1b
            $AnsiString = "$Esc[93m<Root>$Esc[39m$Esc[92m.$Esc[92m'Book Store'$Esc[39m$Esc[93m~$Esc[92mTitle$Esc[39m$Esc[93m=$Esc[96m*PowerShell*$Esc[39m$Esc[93m/$Esc[96m*Python*$Esc[39m$Esc[93m.$Esc[39m$Esc[92m.$Esc[92mPrice$Esc[39m"
            $XdnPath.ToColoredString('<Root>') | Should -be $AnsiString
        }
    }

    Context 'Path' {

        BeforeAll {
            $ObjectGraph = @{
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
            $1stBook.Path | Should -be BookStore[0].Book
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
            $ObjectGraph = @{
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

    Context 'Issues' {

        BeforeAll {
            $ObjectGraph = @{
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

        it '#83 $ObjectGraph | Get-Node $PSNodePath should work' {
            $Template = @{
                BookStore = @(
                    @{
                        Book = @{
                            Title = 'a title'
                            Price = 0
                        }
                    }
                )
            }
            $TitleNode = $Template | Get-Node ~Title
            $Title = $ObjectGraph | Get-Node $TitleNode.Path
            $Title.Value | Should -be 'Harry Potter'
        }

    }
}