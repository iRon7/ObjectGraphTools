#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

# using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Node',   Justification = 'False positive')]
param()

. $PSScriptRoot\..\Source\Private\Use-ClassAccessors.ps1
. $PSScriptRoot\..\Source\Classes\ObjectParser.ps1

Describe 'PSNode' {

    BeforeAll {
        Set-StrictMode -Version Latest

        $Object = @{
            String = 'Hello World'
            Array = @(
                @{ Index = 1; Name = 'One';   Comment = 'First item'  }
                @{ Index = 2; Name = 'Two';   Comment = 'Second item' }
                @{ Index = 3; Name = 'Three'; Comment = 'Third item'  }
            )
            HashTable = @{ One = 1; Two = 2; Three = 3 }
            PSCustomObject = [PSCustomObject]@{ One = 1; Two = 2; Three = 3 }
        }

        function Iterate([PSNode]$Node) { # Basic iterator
            $Node.PathName
            if ($Node -is [PSCollectionNode]) {
                $Node.ChildNodes.foreach{ Iterate $_ }
            }
        }
    }

    Context 'Sanity Check' {

        It 'Loaded' {
            [PSNode]::new() | Should -BeOfType PSNode
        }
    }

    Context 'ParseInput' {

        BeforeAll {
            $Node = [PSNode]::ParseInput($Object)
        }

        it 'PSNode' {
            $Node | Should -BeOfType PSNode
        }

        it "Value" {
            $Node.Value | Should -Be $Object
        }

        it "ValueType" {
            $Node.ValueType | Should -Be 'HashTable'
            { $Node.ValueType = 'Something' } | Should -Throw '*ReadOnly*' -ExceptionType System.Management.Automation.RuntimeException
        }
    }

    Context 'Get child node' {
        BeforeAll {
            $Node = [PSNode]::ParseInput($Object)
        }

        it 'String' {
            $ItemNode = $Node.GetChildNode('String')
            $ItemNode | Should -BeOfType PSNode
            $ItemNode | Should -BeOfType PSLeafNode
            $ItemNode.ValueType | Should -Be $Object.String.GetType()
        }

        it 'Array' {
            $ItemNode = $Node.GetChildNode('Array')
            $ItemNode | Should -BeOfType PSNode
            $ItemNode | Should -BeOfType PSCollectionNode
            $ItemNode | Should -BeOfType PSListNode
            $ItemNode.ValueType | Should -Be $Object.Array.GetType()
        }

        it 'HashTable' {
            $ItemNode = $Node.GetChildNode('HashTable')
            $ItemNode | Should -BeOfType PSNode
            $ItemNode | Should -BeOfType PSCollectionNode
            $ItemNode | Should -BeOfType PSMapNode
            $ItemNode | Should -BeOfType PSDictionaryNode
            $ItemNode.ValueType | Should -Be $Object.HashTable.GetType()
        }

        it 'PSCustomObject' {
            $ItemNode = $Node.GetChildNode('PSCustomObject')
            $ItemNode | Should -BeOfType PSNode
            $ItemNode | Should -BeOfType PSCollectionNode
            $ItemNode | Should -BeOfType PSMapNode
            $ItemNode | Should -BeOfType PSObjectNode
            $ItemNode.ValueType | Should -Be $Object.PSCustomObject.GetType()
        }
    }

    Context 'Get and set item' {
        BeforeAll {
            $Test = @{
                String = 'Hello World'
                Array = @(
                    @{ Index = 1; Name = 'One';   Comment = 'First item'  }
                    @{ Index = 2; Name = 'Two';   Comment = 'Second item' }
                    @{ Index = 3; Name = 'Three'; Comment = 'Third item'  }
                )
                HashTable = @{ One = 1; Two = 2; Three = 3 }
                PSCustomObject = [PSCustomObject]@{ One = 1; Two = 2; Three = 3 }
            }

            $Node = [PSNode]::ParseInput($Test)
        }

        it 'Read string node' {
            $ItemNode = $Node.GetChildNode('String')
            $ItemNode.Value | Should -Be 'Hello World'
        }

        it 'Write string node' {
            $ItemNode = $Node.GetChildNode('String')
            $ItemNode.Value = 'Changed'
            $ItemNode.Value                    | Should -Be 'Changed'
            $Node.GetChildNode('String').Value | Should -Be 'Changed'
        }

        it 'Array' {
            $ItemNode = $Node.GetChildNode('Array')
            $ItemNode.GetChildNode(1).GetChildNode('Comment').Value | Should -Be 'Second item'
            $ItemNode.SetItem(1, @{ Index = 2; Name = 'Two'; Comment = 'Foo Bar' })
            $ItemNode.GetChildNode(1).GetChildNode('Comment').Value | Should -Be  'Foo Bar'
        }

        it 'HashTable' {
            $ItemNode = $Node.GetChildNode('HashTable')
            $ItemNode.GetChildNode('Two').Value | Should -Be 2
            $ItemNode.SetItem('Two', 22)
            $ItemNode.GetChildNode('Two').Value | Should -Be 22
        }

        it 'PSCustomObject' {
            $ItemNode = $Node.GetChildNode('PSCustomObject')
            $ItemNode.GetChildNode('Two').Value | Should -Be 2
            $ItemNode.SetItem('Two', 22)
            $ItemNode.GetChildNode('Two').Value | Should -Be 22
        }
    }

    Context 'Get child nodes' {
        BeforeAll {
            $Node = [PSNode]::ParseInput($Object)
        }

        it 'Array' {
            $ItemNodes = $Node.GetChildNode('Array').ChildNodes
            $ItemNodes -is [PSNode[]] | Should -BeTrue
            $ItemNodes.Count          | Should -Be 3
            $ItemNodes.Value.Index    | Should -Contain 2
            $ItemNodes.Value.Name     | Should -Be 'One', 'Two', 'Three'
        }

        it 'HashTable' {
            $ItemNodes = $Node.GetChildNode('HashTable').ChildNodes
            $ItemNodes -is [PSNode[]] | Should -BeTrue
            $ItemNodes.Count          | Should -Be 3
            $ItemNodes.Name           | Should -Contain 'One'
            $ItemNodes.Name           | Should -Contain 'Two'
            $ItemNodes.Name           | Should -Contain 'Three'
            $ItemNodes.Value          | Should -Contain 1
            $ItemNodes.Value          | Should -Contain 2
            $ItemNodes.Value          | Should -Contain 3
        }


        it 'PSCustomObject' {
            $ItemNodes = $Node.GetChildNode('PSCustomObject').ChildNodes
            $ItemNodes -is [PSNode[]] | Should -BeTrue
            $ItemNodes.Count          | Should -Be 3
            $ItemNodes.Name      | Should -Be 'One', 'Two', 'Three'
            $ItemNodes.Value          | Should -Be 1, 2, 3
        }
    }

    Context 'Path' {
        BeforeAll {
            $Node = [PSNode]::ParseInput($Object)
        }

        it 'Array' {
            $ItemNode = $Node.GetChildNode('Array').GetChildNode(2)
            $ItemNode.PathName | Should -Be '.Array[2]'
            $ItemNode.Path[0]  | Should -Be $ItemNode.RootNode
            $ItemNode.Path[-1] | Should -Be $ItemNode
            $ItemNode.Path[-2] | Should -Be $ItemNode.ParentNode
        }

        it 'HashTable' {
            $ItemNode = $Node.GetChildNode('HashTable').GetChildNode('Two')
            $ItemNode.PathName | Should -Be '.HashTable.Two'
            $ItemNode.Path[0]  | Should -Be $ItemNode.RootNode
            $ItemNode.Path[-1] | Should -Be $ItemNode
            $ItemNode.Path[-2] | Should -Be $ItemNode.ParentNode
        }

        it 'PSCustomObject' {
            $ItemNode = $Node.GetChildNode('PSCustomObject').GetChildNode('Two')
            $ItemNode.PathName | Should -Be '.PSCustomObject.Two'
            $ItemNode.Path[0]  | Should -Be $ItemNode.RootNode
            $ItemNode.Path[-1] | Should -Be $ItemNode
            $ItemNode.Path[-2] | Should -Be $ItemNode.ParentNode
        }

        it 'Path with space' {
            [PSNode]::ParseInput(@{ 'Hello World' = 42 }).ChildNodes[0].PathName | Should -Be ".'Hello World'"
        }
    }

    Context 'Recursively iterate' {

        it 'Get node paths' {
            $Actual = Iterate ([PSNode]::ParseInput($Object))
            $Expected = '', '.PSCustomObject', '.PSCustomObject.One', '.PSCustomObject.Two', '.PSCustomObject.Three', '.Array', '.Array[0]', '.Array[0].Comment', '.Array[0].Name', '.Array[0].Index', '.Array[1]', '.Array[1].Comment', '.Array[1].Name', '.Array[1].Index', '.Array[2]', '.Array[2].Comment', '.Array[2].Name', '.Array[2].Index', '.HashTable', '.HashTable.One', '.HashTable.Three', '.HashTable.Two', '.String'
            $Actual | Compare-Object $Expected | Should -BeNullOrEmpty
        }
    }


    Context '(not) exists' {
        BeforeAll {
            $Exists = @{
                String = 'Hello World'
                Array = 'One', 'Two', 'Three'
                HashTable = @{ One = 1; Two = 2; Three = 3 }
                PSCustomObject = [PSCustomObject]@{ One = 1; Two = 2; Three = 3 }
            }
            $Node = [PSNode]::ParseInput($Exists)
        }

        it '(in/out bound)' {
            { $Node.GetChildNode('NotExists') }                           | Should -Throw
            { $Node.GetChildNode('String') }                              | Should -Not -Throw
            { $Node.GetChildNode('Array') }                               | Should -Not -Throw
            { $Node.GetChildNode('Array').GetChildNode(2)}                | Should -Not -Throw
            { $Node.GetChildNode('Array').GetChildNode(3)}                | Should -Throw
            { $Node.GetChildNode('Array').GetChildNode(-3) }              | Should -Not -Throw
            { $Node.GetChildNode('Array').GetChildNode(-4) }              | Should -Throw
            { $Node.GetChildNode('HashTable').GetChildNode('One') }       | Should -Not -Throw
            { $Node.GetChildNode('HashTable').GetChildNode('one') }       | Should -Not -Throw
            { $Node.GetChildNode('HashTable').GetChildNode('Four') }      | Should -Throw
            { $Node.GetChildNode('PSCustomObject').GetChildNode('One') }  | Should -Not -Throw
            { $Node.GetChildNode('PSCustomObject').GetChildNode('one') }  | Should -Not -Throw
            { $Node.GetChildNode('PSCustomObject').GetChildNode('Four') } | Should -Throw
        }
    }

    Context 'Null or Empty' {
        BeforeAll {
            $Empties = @{
                String = ''
                Array = @()
                HashTable = @{}
                PSCustomObject = [PSCustomObject]@{}
            }
            $Node = [PSNode]::ParseInput($Empties)
        }

        it 'Empty Array' {
            $ArrayNode = $Node.GetChildNode('Array')
            $ItemNodes = $ArrayNode.ChildNodes
            $ItemNodes -is [PSNode[]]   | Should -BeTrue
            $ItemNodes.Count            | Should -Be 0
            $ItemNodes.foreach{ $true } | Should -BeNullOrEmpty
        }

        it 'Empty HashTable' {
            $HashTableNode = $Node.GetChildNode('HashTable')
            $ItemNodes = $HashTableNode.ChildNodes
            $ItemNodes -is [PSNode[]]   | Should -BeTrue
            $ItemNodes.Count            | Should -Be 0
            $ItemNodes.foreach{ $true } | Should -BeNullOrEmpty
        }

        it 'Empty PSCustomObject' {
            $PSCustomObjectNode = $Node.GetChildNode('PSCustomObject')
            $ItemNodes = $PSCustomObjectNode.ChildNodes
            $ItemNodes -is [PSNode[]]   | Should -BeTrue
            $ItemNodes.Count            | Should -Be 0
            $ItemNodes.foreach{ $true } | Should -BeNullOrEmpty
        }
    }

    Context 'Warning' {
        BeforeAll {
            $Cycle = @{ Name = 'Test' }
            $Cycle.Parent = $Cycle
        }

        It 'Default Depth' {
            $Output = Iterate ([PSNode]::ParseInput($Cycle)) 3>&1
            $Output.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike  '*maximum depth*10*'
            $Output.where{$_ -isnot [System.Management.Automation.WarningRecord]}         | Should -Contain '.Parent.Parent.Parent.Name'
        }

        It '-Depth 5' {
            $Output = Iterate ([PSNode]::ParseInput($Cycle, 5)) 3>&1
            $Output.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike  '*maximum depth*5*'
            $Output.where{$_ -isnot [System.Management.Automation.WarningRecord]}         | Should -Contain '.Parent.Parent.Parent.Name'
        }

        It '-Depth 15' {
            $Output = Iterate ([PSNode]::ParseInput($Cycle, 15)) 3>&1
            $Output.where{$_ -is    [System.Management.Automation.WarningRecord]}.Message | Should -BeLike  '*maximum depth*15*'
            $Output.where{$_ -isnot [System.Management.Automation.WarningRecord]}         | Should -Contain '.Parent.Parent.Parent.Name'
        }
    }
}
