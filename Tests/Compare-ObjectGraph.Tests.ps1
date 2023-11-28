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

    Context 'Sort' {

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
                        Name = 'One'
                        Comment = 'Third item'
                    }
                )
            }
        }

        It 'Basic Sort' {
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
                        Name = 'One'
                        Comment = 'Third item'
                    }
                )
            }
            $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $True
        }
    }
}