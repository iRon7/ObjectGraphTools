#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

Describe 'Merge-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        Import-Module $PSScriptRoot\..\ObjectGraphTools.psm1 -DisableNameChecking -Force
    }

    Context 'Sanity Check' {

         It 'Help' {
             Merge-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
         }
    }

    Context 'Merge' {

        It 'Scalar Array' {
            ,@('a', 'b', 'c') | Merge-ObjectGraph 'b', 'c', 'd' | Should -Be (,@('a','b','c','d'))
        }

        It 'Dictionary' {
            $InputObject = @{
                a = 1
                b = 2
                c = 3
            }

            $Template = @{
                b = 2
                c = 3
                d = 4
            }

            $Actual = $InputObject | Merge-ObjectGraph $Template
            $Actual.Count | Should -Be 4
            $Actual.Keys | Should -Contain 'a'
            $Actual.Keys | Should -Contain 'd'
        }

        It 'Array of Dictionaries' {
            $InputObject = @(
                @{
                    Key = 'Key1'
                    a = 1
                    b = 2
                }
                @{
                    Key = 'Key2'
                    c = 3
                    d = 4
                }
            )

            $Template = @(
                @{
                    Key = 'Key2'
                    a = 1
                    b = 2
                }
                @{
                    Key = 'Key3'
                    c = 3
                    d = 4
                }
            )

            $Actual = ,$InputObject | Merge-ObjectGraph $Template
            $Actual.Count | Should -Be 4
        }
    }

    It 'append Dictionaries items by Key' {
        $InputObject = @(
            @{
                Key = 'Key1'
                a = 1
                b = 2
            }
            @{
                Key = 'Key2'
                c = 3
                d = 4
            }
        )

        $Template = @(
            @{
                Key = 'Key2'
                a = 1
                b = 2
            }
            @{
                Key = 'Key3'
                c = 3
                d = 4
            }
        )

        $Actual = ,$InputObject | Merge-ObjectGraph $Template -PrimaryKey Key
        $Actual.Count | Should -Be 3
        $Actual.where{ $_.Key -eq 'Key1' }[0].Count | Should -Be 3
        $Actual.where{ $_.Key -eq 'Key2' }[0].Count | Should -Be 5
        $Actual.where{ $_.Key -eq 'Key3' }[0].Count | Should -Be 3
    }

    It 'replace Dictionaries items by Key' {
        $InputObject = @(
            @{
                Key = 'Key1'
                a = 1
                b = 2
            }
            @{
                Key = 'Key2'
                c = 3
                d = 4
            }
        )

        $Template = @(
            @{
                Key = 'Key2'
                c = 1
                d = 2
            }
            @{
                Key = 'Key3'
                e = 3
                f = 4
            }
        )

        $Actual = ,$InputObject | Merge-ObjectGraph $Template -PrimaryKey Key
        $Actual.Count | Should -Be 3
        $Actual.where{ $_.Key -eq 'Key1' }[0].Count | Should -Be 3
        $Actual.where{ $_.Key -eq 'Key2' }[0].Count | Should -Be 3
        $Actual.where{ $_.Key -eq 'Key3' }[0].Count | Should -Be 3
    }

    Context 'Warning' {

        It 'Depth' {
            $Template = @{ Name = 'Base' }
            $Template.Parent = $Template
            $InputObject = @{ Name = 'Test' }
            $InputObject.Parent = $InputObject
            $Records = $InputObject | Merge-ObjectGraph $Template 3>&1
            $Records.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike '*maximum depth*10*'
            $Records.where{$_ -isnot [System.Management.Automation.WarningRecord]}.Name    | Should -Be     'Test'
        }
   }
}