#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Reference', Justification = 'False positive')]
param()

Describe 'Compare-ObjectGraph' {

    BeforeAll {

        Set-StrictMode -Version Latest

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

    Context 'Existence Check' {

        It 'Help' {
            Compare-ObjectGraph -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Compare' {

        BeforeAll {
            $Object12345 = @{
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
                        Comment = 'Fourth item'
                    }
                    @{
                        Index = 5
                        Name = 'Five'
                        Comment = 'Fifth item'
                    }
                )
            }

            function New-TestObject ($Indices) {
                @{
                    Comment = 'Sample ObjectGraph'
                    Data = @(
                        foreach ($Index in $Indices) {
                            $Object12345.Data[$Index - 1]
                        }
                    )
                }
            }
        }

        It 'Different comment string value' {
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
            $Result = $Object | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy Reference          InputObject'
            $Lines[1] | Should -be '----    ----------- ---------          -----------'
            $Lines[2] | Should -be 'Comment Value       Sample ObjectGraph Something else'
        }


        It 'Object123' {
            $Object123 = New-TestObject 1, 2, 3

            $Object123 | Compare-ObjectGraph $Reference -IsEqual                   | Should -Be $True
            $Object123 | Compare-ObjectGraph $Reference                            | Should -BeNullOrEmpty

            $Object123 | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual  | Should -Be $True
            $Object123 | Compare-ObjectGraph $Reference -IgnoreListOrder           | Should -BeNullOrEmpty

            $Object123 | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $True
            $Object123 | Compare-ObjectGraph $Reference -PrimaryKey Index          | Should -BeNullOrEmpty
        }

        It 'Object1' {
            $Object1 = New-TestObject 1

            $Object1 | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object1 | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           1'
            $Lines[3] | Should -be 'Data[1] Exists      [hashtable]'
            $Lines[4] | Should -be 'Data[2] Exists      [hashtable]'

            $Object1 | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $False
            $Result = $Object1 | Compare-ObjectGraph $Reference -IgnoreListOrder
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           1'
            $Lines[3] | Should -be 'Data[1] Exists      [hashtable]'
            $Lines[4] | Should -be 'Data[2] Exists      [hashtable]'

            $Object1 | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $False
            $Result = $Object1 | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           1'
            $Lines[3] | Should -be 'Data[1] Exists      [hashtable]'
            $Lines[4] | Should -be 'Data[2] Exists      [hashtable]'
        }

        It 'Object2' {
            $Object2 = New-TestObject 2

            $Object2 | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object2 | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path            Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----            -----------   --------- -----------'
            $Lines[2] | Should -be 'Data            Size                  3           1'
            $Lines[3] | Should -be 'Data[0].Index   Value                 1           2'
            $Lines[4] | Should -be 'Data[0].Comment Value        First item Second item'
            $Lines[5] | Should -be 'Data[0].Name    Value               One         Two'
            $Lines[6] | Should -be 'Data[1]         Exists      [hashtable]'
            $Lines[7] | Should -be 'Data[2]         Exists      [hashtable]'

            $Object2 | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $False
            $Result = $Object2 | Compare-ObjectGraph $Reference -IgnoreListOrder
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           1'
            $Lines[3] | Should -be 'Data[0] Exists      [hashtable]'
            $Lines[4] | Should -be 'Data[2] Exists      [hashtable]'

            $Object2 | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $False
            $Result = $Object2 | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           1'
            $Lines[3] | Should -be 'Data[0] Exists      [hashtable]'
            $Lines[4] | Should -be 'Data[2] Exists      [hashtable]'
        }

        It 'Object13' {
            $Object13 = New-TestObject 1, 3

            $Object13 | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object13 | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path            Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----            -----------   --------- -----------'
            $Lines[2] | Should -be 'Data            Size                  3           2'
            $Lines[3] | Should -be 'Data[1].Index   Value                 2           3'
            $Lines[4] | Should -be 'Data[1].Comment Value       Second item  Third item'
            $Lines[5] | Should -be 'Data[1].Name    Value               Two       Three'
            $Lines[6] | Should -be 'Data[2]         Exists      [hashtable]'

            $Object13 | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $False
            $Result = $Object13 | Compare-ObjectGraph $Reference -IgnoreListOrder
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           2'
            $Lines[3] | Should -be 'Data[1] Exists      [hashtable]'

            $Object13 | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $False
            $Result = $Object13 | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path    Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----    -----------   --------- -----------'
            $Lines[2] | Should -be 'Data    Size                  3           2'
            $Lines[3] | Should -be 'Data[1] Exists      [hashtable]'
        }

        It 'Object13a' {
            $Object13a = New-TestObject 1, 3
            $Object13a.Data[1].Name = '3a'

            $Object13a | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object13a | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path            Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----            -----------   --------- -----------'
            $Lines[2] | Should -be 'Data            Size                  3           2'
            $Lines[3] | Should -be 'Data[1].Index   Value                 2           3'
            $Lines[4] | Should -be 'Data[1].Comment Value       Second item  Third item'
            $Lines[5] | Should -be 'Data[1].Name    Value               Two          3a'
            $Lines[6] | Should -be 'Data[2]         Exists      [hashtable]'

            $Object13a | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $False
            $Result = $Object13a | Compare-ObjectGraph $Reference -IgnoreListOrder
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path            Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----            -----------   --------- -----------'
            $Lines[2] | Should -be 'Data            Size                  3           2'
            $Lines[3] | Should -be 'Data[1].Index   Value                 2           3'
            $Lines[4] | Should -be 'Data[1].Comment Value       Second item  Third item'
            $Lines[5] | Should -be 'Data[1].Name    Value               Two          3a'
            $Lines[6] | Should -be 'Data[2]         Exists      [hashtable]'

            $Object13a | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $False
            $Result = $Object13a | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path         Discrepancy   Reference InputObject'
            $Lines[1] | Should -be '----         -----------   --------- -----------'
            $Lines[2] | Should -be 'Data         Size                  3           2'
            $Lines[3] | Should -be 'Data[1].Name Value             Three          3a'
            $Lines[4] | Should -be 'Data[1]      Exists      [hashtable]'
        }

        it 'Object321' {
            $Object321 = New-TestObject 3, 2, 1

            $Object321 | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object321 | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path            Discrepancy  Reference InputObject'
            $Lines[1] | Should -be '----            -----------  --------- -----------'
            $Lines[2] | Should -be 'Data[0].Index   Value                1           3'
            $Lines[3] | Should -be 'Data[0].Comment Value       First item  Third item'
            $Lines[4] | Should -be 'Data[0].Name    Value              One          3a'
            $Lines[5] | Should -be 'Data[2].Index   Value                3           1'
            $Lines[6] | Should -be 'Data[2].Comment Value       Third item  First item'
            $Lines[7] | Should -be 'Data[2].Name    Value            Three         One'

            $Object321 | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $False
            $Result = $Object321 | Compare-ObjectGraph $Reference -IgnoreListOrder
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path         Discrepancy Reference InputObject'
            $Lines[1] | Should -be '----         ----------- --------- -----------'
            $Lines[2] | Should -be 'Data[0].Name Value       Three     3a'

            $Object321 | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $False
            $Result = $Object321 | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path         Discrepancy Reference InputObject'
            $Lines[1] | Should -be '----         ----------- --------- -----------'
            $Lines[2] | Should -be 'Data[0].Name Value       Three     3a'
        }

        it 'Object3a21' {
            $Object321 = New-TestObject 3, 2, 1
            $Object13a.Data[0].Name = '3a'

            $Object321 | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Result = $Object321 | Compare-ObjectGraph $Reference
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path            Discrepancy  Reference InputObject'
            $Lines[1] | Should -be '----            -----------  --------- -----------'
            $Lines[2] | Should -be 'Data[0].Index   Value                1           3'
            $Lines[3] | Should -be 'Data[0].Comment Value       First item  Third item'
            $Lines[4] | Should -be 'Data[0].Name    Value              One          3a'
            $Lines[5] | Should -be 'Data[2].Index   Value                3           1'
            $Lines[6] | Should -be 'Data[2].Comment Value       Third item  First item'
            $Lines[7] | Should -be 'Data[2].Name    Value            Three         One'

            $Object321 | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $False
            $Result = $Object321 | Compare-ObjectGraph $Reference -IgnoreListOrder
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path         Discrepancy Reference InputObject'
            $Lines[1] | Should -be '----         ----------- --------- -----------'
            $Lines[2] | Should -be 'Data[0].Name Value       Three     3a'

            $Object321 | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $False
            $Result = $Object321 | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Lines = ($Result | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
            $Lines[0] | Should -be 'Path         Discrepancy Reference InputObject'
            $Lines[1] | Should -be '----         ----------- --------- -----------'
            $Lines[2] | Should -be 'Data[0].Name Value       Three     3a'
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
            $Result[0].Path        | Should -Be 'Data'
            $Result[0].Discrepancy | Should -Be 'Size'
            $Result[0].InputObject | Should -Be 4
            $Result[0].Reference   | Should -Be 3
            $Result[1].Path        | Should -Be 'Data[3]'
            $Result[1].Discrepancy | Should -Be 'Exists'
            $Result[1].InputObject | Should -Be '[HashTable]'
            $Result[1].Reference   | Should -Be $Null
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
            $Result[0].Path        | Should -Be 'Data[2].Name'
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
            $Object | Compare-ObjectGraph $Reference -IsEqual | Should -Be $False
            $Object | Compare-ObjectGraph $Reference -IgnoreListOrder -IsEqual | Should -Be $True
            $Object | Compare-ObjectGraph $Reference -PrimaryKey Index -IsEqual | Should -Be $True
            $Result = $Object | Compare-ObjectGraph $Reference
            $Result.Count | Should -Be 6
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
            $Object | Compare-ObjectGraph $Ordered -IsEqual | Should -Be $True
            $Object | Compare-ObjectGraph $Ordered -MatchMapOrder -IsEqual | Should -Be $False
            $Object | Compare-ObjectGraph $Ordered -PrimaryKey Index -MatchMapOrder -IsEqual | Should -Be $False
            $Result = $Object | Compare-ObjectGraph $Ordered -MatchMapOrder
            $Result.Count     | Should -Be 2
        }
    }

    Context 'Issues' {
        It 'Compare single discrepancies' {
            $Obj1 = ConvertFrom-Json '
                {
                    "NonNodeData": {
                        "Exchange": {
                            "AcceptedDomains": [
                                {
                                    "DomainType": "Authoritative",
                                    "Ensure": "PresentX",
                                    "MatchSubDomains": true,
                                    "OutboundOnly": true,
                                    "UniqueId": "Default"
                                }
                            ],
                            "ActiveSyncDeviceAccessRules": [],
                            "AddressBookPolicies": [],
                            "AddressLists": []
                        }
                    }
                }'
            $Obj2 = ConvertFrom-Json '
                {
                    "NonNodeData": {
                        "Exchange": {
                            "AcceptedDomains": [
                                {
                                    "DomainType": "Authoritative",
                                    "Ensure": "PresentY",
                                    "MatchSubDomains": true,
                                    "OutboundOnly": true,
                                    "UniqueId": "Default"
                                }
                            ],
                            "ActiveSyncDeviceAccessRules": [],
                            "AddressBookPolicies": [],
                            "AddressLists": []
                        }
                    }
                }'
            $Obj1 | Compare-ObjectGraph $Obj2 -IsEqual | Should -Be $False
            $Result = $Obj1 | Compare-ObjectGraph $Obj2
            @($Result).Count       | Should -Be 1
            $Result[0].Path        | Should -Be 'NonNodeData.Exchange.AcceptedDomains[0].Ensure'
            $Result[0].Discrepancy | Should -Be 'Value'
            $Result[0].InputObject | Should -Be 'PresentX'
            $Result[0].Reference   | Should -Be 'PresentY'
        }

        It "#20 Case insensitive" {
            $Object = @{
                Comment = 'SAMPLE ObjectGraph'
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
            $Object | Compare-ObjectGraph $Reference | Should -BeNullOrEmpty
        }

        It '#121 Primary Key not being used?' {

            $Reference = [Ordered]@{
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

            $Object = [Ordered]@{
                Comment = 'Sample ObjectGraph'
                Data = @(
                    @{
                        Index = 1
                        Name = 'One'
                    }
                    @{
                        Index = 3
                        Name = 'Three'
                    }
                    @{
                        Index = 2
                        Name = 'Two'
                    }
                )
            }

            $Result = $Object | Compare-ObjectGraph $Reference -PrimaryKey Index
            $Result | Where-Object { $_.Path.Nodes[-1].Name -eq 'Index' } | Should -BeNullOrEmpty
        }

        It "#111 Compare-ObjectGraph fails with certain object graphs, presumably due to cyclical references" {
            $Result = ,(Get-Item /) | Compare-ObjectGraph  -Reference (Get-Item /) -Depth 5 -WarningAction SilentlyContinue
            @($Result).Count | Should -BeLessThan 3
        }
    }
}
