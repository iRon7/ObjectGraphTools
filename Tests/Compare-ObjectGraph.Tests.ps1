#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Reference', Justification = 'False positive')]
param()

Describe 'Compare-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        Import-Module $PSScriptRoot\..\ObjectGraphTools.psm1 -DisableNameChecking -Force

        $Reference = @{
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
            Compare-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
         }
    }

    Context 'Compare' {

        It 'Equal' {
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
            $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $True
            $Object | Compare-ObjectGraph $Reference | Should -BeNullOrEmpty
        }

        It 'Different string value' {
            $Object = @{
                Comment = 'Something else'
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
                        Index   = 3
                        Name    = 'Three'
                        Comment = 'Third item'
                    }
                )
            }
            $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object   | Compare-ObjectGraph $Reference
            @($Result).Count    | Should -Be 1
            $Result.Path        | Should -Be '.Comment'
            $Result.Discrepancy | Should -Be 'Value'
            $Result.InputObject | Should -Be 'Something else'
            $Result.Reference   | Should -Be 'Sample ObjectGraph'
        }
    }

    It 'Missing entry' {
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
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
        $Result = $Object      | Compare-ObjectGraph $Reference
        $Result.Count          | Should -Be 2
        $Result[0].Path        | Should -Be '.Data'
        $Result[0].Discrepancy | Should -Be 'Size'
        $Result[0].InputObject | Should -Be 2
        $Result[0].Reference   | Should -Be 3
        $Result[1].Path        | Should -Be '.Data[2]'
        $Result[1].Discrepancy | Should -Be 'Exists'
        $Result[1].InputObject | Should -Be $False
        $Result[1].Reference   | Should -Be $True
    }
    It 'Extra entry' {
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
                @{
                    Index = 4
                    Name = 'Four'
                    Comment = 'Forth item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
        $Result = $Object      | Compare-ObjectGraph $Reference
        $Result.Count          | Should -Be 2
        $Result[0].Path        | Should -Be '.Data'
        $Result[0].Discrepancy | Should -Be 'Size'
        $Result[0].InputObject | Should -Be 4
        $Result[0].Reference   | Should -Be 3
        $Result[1].Path        | Should -Be '.Data[3]'
        $Result[1].Discrepancy | Should -Be 'Exists'
        $Result[1].InputObject | Should -Be $True
        $Result[1].Reference   | Should -Be $False
    }
    It 'Different entry value' {
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
                    Name = 'Zero'               # This is different
                    Comment = 'Third item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
        $Result = $Object      | Compare-ObjectGraph $Reference
        @($Result).Count       | Should -Be 1
        $Result[0].Path        | Should -Be '.Data[2].Name'
        $Result[0].Discrepancy | Should -Be 'Value'
        $Result[0].InputObject | Should -Be 'Zero'
        $Result[0].Reference   | Should -Be 'Three'
    }
    It 'Unordered array' {
        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                @{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                @{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
                @{
                    Index = 2
                    Name = 'Two'
                    Comment = 'Second item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $True
        $Object | Compare-ObjectGraph $Reference -MatchObjectOrder -IsEqual | Should -Be $False
        $Result = $Object      | Compare-ObjectGraph $Reference -MatchObjectOrder
        $Result.Count          | Should -Be 6
    }
    It 'Unordered (hashtable) reference' {
        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                [PSCustomObject]@{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                [PSCustomObject]@{
                    Index = 2
                    Name = 'Two'
                    Comment = 'Second item'
                }
                [PSCustomObject]@{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $True

        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                [PSCustomObject]@{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                [PSCustomObject]@{
                    Index = 2
                    Comment = 'Second item'                     # Note:
                    Name = 'Two'                                # These entries are swapped
                }
                [PSCustomObject]@{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $True
    }
    It 'Ordered (PSCustomObject) reference' {                
        $Ordered = @{                                           # Redefine Reference with order Dictionary/PSCustomObject
            Comment = 'Sample ObjectGraph'
            Data = @(
                [PSCustomObject]@{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                [PSCustomObject]@{
                    Index = 2
                    Name = 'Two'
                    Comment = 'Second item'
                }
                [PSCustomObject]@{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }
        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                [PSCustomObject]@{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                [PSCustomObject]@{
                    Index = 2
                    Name = 'Two'
                    Comment = 'Second item'
                }
                [PSCustomObject]@{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Ordered -IsEqual | Should -Be $True

        $Object = @{
            Comment = 'Sample ObjectGraph'
            Data = @(
                [PSCustomObject]@{
                    Index = 1
                    Name = 'One'
                    Comment = 'First item'
                }
                [PSCustomObject]@{
                    Index = 2
                    Comment = 'Second item'                     # Note:
                    Name = 'Two'                                # These entries are swapped
                }
                [PSCustomObject]@{
                    Index = 3
                    Name = 'Three'
                    Comment = 'Third item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Ordered -IsEqual | Should -Be $False
    }
}
