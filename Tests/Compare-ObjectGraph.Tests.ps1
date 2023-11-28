#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Reference', Justification = 'False positive')]
param()

Describe 'Compare-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        Import-Module $PSScriptRoot\..\ObjectGraphTools.psm1 -DisableNameChecking -Force
    }

    Context 'Sanity Check' {

         It 'Help' {
            Compare-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
         }
    }

    Context 'Compare' {

        BeforeEach {
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
            $Result.Property    | Should -Be '.Comment'
            $Result.Inequality  | Should -Be 'Value'
            $Result.Reference   | Should -Be 'Sample ObjectGraph'
            $Result.InputObject | Should -Be 'Something else'
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
        $Result[0].Property    | Should -Be '.Data'
        $Result[0].Inequality  | Should -Be 'Size'
        $Result[0].Reference   | Should -Be 3
        $Result[0].InputObject | Should -Be 2
        $Result[1].Property    | Should -Be '.Data[2]'
        $Result[1].Inequality  | Should -Be 'Exists'
        $Result[1].Reference   | Should -Be $True
        $Result[1].InputObject | Should -Be $False
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
        $Result[0].Property    | Should -Be '.Data'
        $Result[0].Inequality  | Should -Be 'Size'
        $Result[0].Reference   | Should -Be 3
        $Result[0].InputObject | Should -Be 4
        $Result[1].Property    | Should -Be '.Data[3]'
        $Result[1].Inequality  | Should -Be 'Exists'
        $Result[1].Reference   | Should -Be $False
        $Result[1].InputObject | Should -Be $True
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
                    Name = 'Zero'
                    Comment = 'Third item'
                }
            )
        }
        $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
        $Result = $Object      | Compare-ObjectGraph $Reference
        $Result.Count          | Should -Be 2
        $Result[0].Property    | Should -Be '.Data[2]'
        $Result[0].Inequality  | Should -Be 'Exists'
        $Result[0].Reference   | Should -Be $False
        $Result[0].InputObject | Should -Be $True
        $Result[1].Property    | Should -Be '.Data[2]'
        $Result[1].Inequality  | Should -Be 'Exists'
        $Result[1].Reference   | Should -Be $True
        $Result[1].InputObject | Should -Be $False
    }
}
