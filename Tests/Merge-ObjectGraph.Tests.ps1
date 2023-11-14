#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

Describe 'Merge-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        $FileInfo = [System.Io.FileInfo]$PSCommandPath
        $SourceFolder = Join-Path $FileInfo.Directory.Parent 'Source'
        Foreach ($SubFolder in 'Classes', 'Private') {
            $Folder = Join-Path $SourceFolder $SubFolder
            $PSScripts = Get-ChildItem $Folder -Filter *.ps1
            foreach ($PSScript in $PSScripts) { . $PSScript.FullName }
        }
        $PublicFolder =  Join-Path $SourceFolder Public
        $PSScriptPath = Join-Path $PublicFolder $FileInfo.Name.Replace('.Tests.ps1', '.ps1')
        . $PSScriptPath

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

    It 'Array of Dictionaries by Key' {
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
}
