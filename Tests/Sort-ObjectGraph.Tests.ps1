#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
param()

Describe 'Sort-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

        Import-Module $PSScriptRoot\..\ObjectGraphTools.psm1 -DisableNameChecking -Force
    }

    Context 'Sanity Check' {

         It 'Help' {
             Sort-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
         }
    }

    Context 'Sort' {

        BeforeEach {
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
        }

        It 'Basic Sort' {
            $Sorted = $Object | Sort-ObjectGraph
            $Sorted.Data.Index | Should -Be 1, 2, 3
            $Sorted.PSObject.Properties.Name | Should -Be 'Comment', 'Data'
            $Sorted.Data[0].PSObject.Properties.Name | Should -Be 'Comment', 'Index', 'Name'
        }

        It 'Decending' {
            $Sorted = $Object | Sort-ObjectGraph -Descending
            $Sorted.Data.Index | Should -Be 2, 3, 1
            $Sorted.PSObject.Properties.Name | Should -Be 'Data', 'Comment'
            $Sorted.Data[0].PSObject.Properties.Name | Should -Be 'Name', 'Index', 'Comment'
        }

        It 'By Name' {
            $Sorted = $Object | Sort-ObjectGraph -By Name
            $Sorted.Data.Index | Should -Be 1, 3, 2
            $Sorted.PSObject.Properties.Name | Should -Be 'Comment', 'Data'
            $Sorted.Data[0].PSObject.Properties.Name | Should -Be 'Name', 'Comment', 'Index'
        }

        It 'By Name Descending' {
            $Sorted = $Object | Sort-ObjectGraph -By Name -Descending
            $Sorted.Data.Index | Should -Be 2, 3, 1
            $Sorted.PSObject.Properties.Name | Should -Be 'Data', 'Comment'
            $Sorted.Data[0].PSObject.Properties.Name | Should -Be 'Name', 'Index', 'Comment'
        }

        It 'Type' {
            $Object = @{
                String = 'String'
                HereString = @'
Hello
World
'@
                Int = 67
                Double = 1.2
                Long = 1234567890123456
                DateTime = [datetime]'1963-10-07T17:56:53.8139055'
                Version = [version]'1.2.34567.890'
                Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'
                Script = {2 * 3}
                Array =
                    'One',
                    'Two',
                    'Three',
                    'Four'
                ByteArray =
                    1,
                    2,
                    3
                StringArray =
                    'One',
                    'Two',
                    'Three'
                EmptyArray = @()
                SingleValueArray = ,'one'
                SubArray =
                    'One',
                    (
                        'Two',
                        'Three'
                    ),
                    'Four'
                HashTable = @{ Name = 'Value' }
                Ordered = [ordered]@{
                    One = 1
                    Two = 2
                    Three = 3
                    Four = 4
                }
                Object = [pscustomobject]@{ Name = 'Value' }
            }

            { $Object | Sort-ObjectGraph } | Should -not -throw
        }

        Context 'Warning' {
            It 'Depth' {
                $Object = @{ Name = 'Test' }
                $Object.Parent = $Object
                $Records = Sort-ObjectGraph $Object 3>&1
                $Records.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike '*maximum depth*10*'
                $Records.where{$_ -isnot [System.Management.Automation.WarningRecord]}.Name    | Should -Be     'Test'
            }
       }
    }
}