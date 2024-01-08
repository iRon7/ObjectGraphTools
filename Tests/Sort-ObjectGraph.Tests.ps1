#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
param()

Describe 'Sort-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest
    }

    Context 'Sanity Check' {

        It 'Help' {
            Sort-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Scalar Array' {

        It 'Integer' {
            $Object = 3, 1, 2
            $Sorted = ,$Object | Sort-ObjectGraph
            $Sorted | Should -Be 1, 2, 3
            $Sorted = ,$Object | Sort-ObjectGraph -Descending
            $Sorted | Should -Be 3, 2, 1
        }

        It 'String' {
            $Object = 'c3', 'a1', 'b2'
            $Sorted = ,$Object | Sort-ObjectGraph
            $Sorted | Should -Be 'a1', 'b2', 'c3'
            $Sorted = ,$Object | Sort-ObjectGraph -Descending
            $Sorted | Should -Be 'c3', 'b2', 'a1'
        }
    }


    Context 'Dictionary' {
        $Dictionary = @{ c = 1; a = 3; b = 2 }
        $Sorted = $Dictionary | Sort-ObjectGraph
        $Sorted | Should -BeOfType PSCustomObject
        $Sorted.PSObject.Properties.Name  | Should -be 'a', 'b', 'c'
        $Sorted.PSObject.Properties.Value | Should -be 3, 2, 1
    }

    Context 'PSCustomObject' {
        $PSCustomObject = [PSCustomObject]@{ c = 1; a = 3; b = 2 }
        $Sorted = $PSCustomObject | Sort-ObjectGraph
        $Sorted | Should -BeOfType PSCustomObject
        $Sorted.PSObject.Properties.Name  | Should -be 'a', 'b', 'c'
        $Sorted.PSObject.Properties.Value | Should -be 3, 2, 1
    }

    Context 'Dictionary Array' {

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
                        Name = 'Three'
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

        It 'Descending' {
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
    }

    Context 'Object Array' {

        BeforeEach {
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

        It 'Descending' {
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
    }

    Context 'Types' {

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
                DateTime = [DateTime]'1963-10-07T17:56:53.8139055'
                Version = [Version]'1.2.34567.890'
                Guid = [Guid]'5f167621-6abe-4153-a26c-f643e1716720'
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
                Ordered = [Ordered]@{
                    One = 1
                    Two = 2
                    Three = 3
                    Four = 4
                }
                Object = [PSCustomObject]@{ Name = 'Value' }
            }

            { $Object | Sort-ObjectGraph } | Should -not -throw
        }

        Context 'Issues' {

            It '#2: Merge-ObjectGraph Bug' {
            }
        }

        Context 'Warning' {
            BeforeAll {
                $Object = @{ Name = 'Test' }
                $Object.Parent = $Object
            }

            It 'Default Depth' {
                $Records = Sort-ObjectGraph $Object 3>&1
                $Records.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike '*maximum depth*10*'
                $Records.where{$_ -isnot [System.Management.Automation.WarningRecord]}.Name    | Should -Be     'Test'
            }

            It '-Depth 5' {
                $Records = Sort-ObjectGraph -Depth 5 $Object 3>&1
                $Records.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike '*maximum depth*5*'
                $Records.where{$_ -isnot [System.Management.Automation.WarningRecord]}.Name    | Should -Be     'Test'
            }
       }

       Context 'Issues' {

        It '#12: Bug Sort-ObjectGraph' {

            $Object = ConvertFrom-Json '
                {
                    "NoneNodeData": {
                        "Teams": {
                            "AppSetupPolicies": [
                                {
                                    "Ensure": "Present",
                                    "Identity": "Global",
                                    "PinnedAppBarApps": [
                                        "86fcd49b-61a2-4701-b771-54728cd291fb",
                                        "42f6c1da-a241-483a-a3cc-4f5be9185951",
                                        "2a84919f-59d8-4441-a975-2a8c2643b741",
                                        "14d6962d-6eeb-4f48-8890-de55454bb136",
                                        "14072831-8a2a-4f76-9294-057bf0b42a68"
                                    ]
                                }
                            ]
                        }
                    }
                }'

            $Sorted = $Object | Sort-ObjectGraph
            $Sorted.NoneNodeData.Teams.AppSetupPolicies[0].PinnedAppBarApps[0] | Should -BeOfType String
            $Sorted.NoneNodeData.Teams.AppSetupPolicies[0].PinnedAppBarApps[0].Length | Should -BeGreaterThan 1
        }
    }
}
}