#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Node',   Justification = 'False positive')]
param()

Describe 'PSInstance' {

    BeforeAll {
        Set-StrictMode -Version Latest
    }

    Context 'Existence Check' {

        It 'Loaded' {
            [PSInstance]::new() -is [PSInstance] | Should -BeTrue
        }
    }

    Context 'By string' {

        it 'String' {
            [PSInstance]::Create('String')        | Should -BeOfType String
            [PSInstance]::Create('[String]')      | Should -BeOfType String
            [PSInstance]::Create('System.String') | Should -BeOfType String
        }

        it 'Int' {
            [PSInstance]::Create('Int')          | Should -BeOfType Int
            [PSInstance]::Create('Int32')        | Should -BeOfType Int
            [PSInstance]::Create('[Int]')        | Should -BeOfType Int
            [PSInstance]::Create('System.Int32') | Should -BeOfType Int
        }

        it 'Char' {
            [PSInstance]::Create('Char') | Should -BeOfType Char
        }

        it 'DateTime' {
            [PSInstance]::Create('DateTime') | Should -BeOfType DateTime
        }

        it 'ScriptBlock' {
            [PSInstance]::Create('ScriptBlock') | Should -BeOfType ScriptBlock
        }

        it 'Array' {
            [PSInstance]::Create('Array')           | Should -BeOfType Array
            [PSInstance]::Create('Object[]')        | Should -BeOfType Array
            [PSInstance]::Create('System.Object[]') | Should -BeOfType Array
        }

        it 'HashTable' {
            [PSInstance]::Create('HashTable')                    | Should -BeOfType HashTable
            [PSInstance]::Create('Collections.hashtable')        | Should -BeOfType HashTable
            [PSInstance]::Create('System.Collections.Hashtable') | Should -BeOfType HashTable
        }

        it 'List[Object]' {
            ,[PSInstance]::Create('Collections.Generic.List[Object]')               | Should -BeOfType Collections.Generic.List[Object]
            ,[PSInstance]::Create('System.Collections.Generic.List[Object]')        | Should -BeOfType Collections.Generic.List[Object]
            ,[PSInstance]::Create('Collections.Generic.List[System.Object]')        | Should -BeOfType Collections.Generic.List[Object]
            ,[PSInstance]::Create('System.Collections.Generic.List[System.Object]') | Should -BeOfType Collections.Generic.List[Object]
        }

        it 'List[String]' {
            ,[PSInstance]::Create('Collections.Generic.List[String]')               | Should -BeOfType Collections.Generic.List[String]
            ,[PSInstance]::Create('System.Collections.Generic.List[String]')        | Should -BeOfType Collections.Generic.List[String]
            ,[PSInstance]::Create('Collections.Generic.List[System.String]')        | Should -BeOfType Collections.Generic.List[String]
            ,[PSInstance]::Create('System.Collections.Generic.List[System.String]') | Should -BeOfType Collections.Generic.List[String]
        }

        it 'Dictionary[String,String]' {
            [PSInstance]::Create('Collections.Generic.Dictionary[String,String]')        | Should -BeOfType 'Collections.Generic.Dictionary[String,String]'
            [PSInstance]::Create('System.Collections.Generic.Dictionary[String,String]') | Should -BeOfType 'Collections.Generic.Dictionary[String,String]'
        }

        it 'Dictionary[String,Object]' {
            [PSInstance]::Create('Collections.Generic.Dictionary[String,Object]')        | Should -BeOfType 'Collections.Generic.Dictionary[String,Object]'
            [PSInstance]::Create('System.Collections.Generic.Dictionary[String,Object]') | Should -BeOfType 'Collections.Generic.Dictionary[String,Object]'
        }

        it 'Ordered' {
            [PSInstance]::Create('Ordered')                                          | Should -BeOfType Collections.Specialized.OrderedDictionary
            [PSInstance]::Create('Collections.Specialized.OrderedDictionary')        | Should -BeOfType Collections.Specialized.OrderedDictionary
            [PSInstance]::Create('System.Collections.Specialized.OrderedDictionary') | Should -BeOfType Collections.Specialized.OrderedDictionary
        }

        it 'PSCustomObject' {
            [PSInstance]::Create('PSObject')                                    | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create('Management.Automation.PSObject')              | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create('System.Management.Automation.PSObject')       | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create('PSCustomObject')                              | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create('Management.Automation.PSCustomObject')        | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create('System.Management.Automation.PSCustomObject') | Should -BeOfType Management.Automation.PSCustomObject
        }
    }
    Context 'By type' {

        it 'String' {
            [PSInstance]::Create([String]) | Should -BeOfType String
        }

        it 'Int' {
            [PSInstance]::Create([Int]) | Should -BeOfType Int
        }

        it 'Char' {
            [PSInstance]::Create([Char]) | Should -BeOfType Char
        }

        it 'DateTime' {
            [PSInstance]::Create([DateTime]) | Should -BeOfType DateTime
        }

        it 'ScriptBlock' {
            [PSInstance]::Create([ScriptBlock]) | Should -BeOfType ScriptBlock
        }

        it 'HashTable' {
            [PSInstance]::Create([HashTable]) | Should -BeOfType HashTable
        }

        it 'List[Object]' {
            ,[PSInstance]::Create([Collections.Generic.List[Object]]) | Should -BeOfType Collections.Generic.List[Object]
        }

        it 'List[String]' {
            ,[PSInstance]::Create([Collections.Generic.List[String]]) | Should -BeOfType Collections.Generic.List[String]
        }

        it 'Dictionary[String,String]' {
            [PSInstance]::Create([Collections.Generic.Dictionary[String,String]]) | Should -BeOfType 'Collections.Generic.Dictionary[String,String]'
        }

        it 'Dictionary[String,Object]' {
            [PSInstance]::Create([Collections.Generic.Dictionary[String,Object]]) | Should -BeOfType 'Collections.Generic.Dictionary[String,Object]'
        }

        it 'Ordered' {
            [PSInstance]::Create([Collections.Specialized.OrderedDictionary]) | Should -BeOfType Collections.Specialized.OrderedDictionary
        }

        it 'PSCustomObject' {
            [PSInstance]::Create([PSCustomObject]) | Should -BeOfType Management.Automation.PSCustomObject
        }
    }

    Context 'By example' {

        it 'String' {
            # As [PSInstance]::Create() support a TypeName (string) as input
            # Only an empty string might be used as an sample value
            # The rest will either assumed to be a TypeName or fail.
            [PSInstance]::Create('')              | Should -BeOfType String
        }

        it 'Int' {
            [PSInstance]::Create(0)  | Should -BeOfType Int
            [PSInstance]::Create(42) | Should -BeOfType Int
            [PSInstance]::Create(42) | Should -Be 0
        }

        it 'Char' {
            [PSInstance]::Create([Char]'a') | Should -BeOfType Char
            [PSInstance]::Create([Char]'a') | Should -Be ''
        }

        it 'DateTime' {
            [PSInstance]::Create((Get-Date))               | Should -BeOfType DateTime
            [PSInstance]::Create((Get-Date)).ToString('s') | Should -Be '0001-01-01T00:00:00'
        }

        it 'ScriptBlock' {
            [PSInstance]::Create({}) | Should -BeOfType ScriptBlock
        }

        it 'Array' {
            [PSInstance]::Create(@())     | Should -BeOfType Array
            [PSInstance]::Create(@(1))    | Should -BeOfType Array
            [PSInstance]::Create(@(1, 2)) | Should -BeOfType Array
            [PSInstance]::Create(@(1, 2)) | Should -BeNullOrEmpty
        }

        it 'HashTable' {
            [PSInstance]::Create(@{})                     | Should -BeOfType HashTable
            [PSInstance]::Create(@{ a = 1 })              | Should -BeOfType HashTable
            [PSInstance]::Create(@{ a = 1 ;b = 2 })       | Should -BeOfType HashTable
            [PSInstance]::Create(@{ a = 1 ;b = 2 }).Count | Should -Be 0
        }

        it 'List[Object]' {
            ,[PSInstance]::Create([Collections.Generic.List[Object]]@())       | Should -BeOfType Collections.Generic.List[Object]
            ,[PSInstance]::Create([Collections.Generic.List[Object]]@('a'))    | Should -BeOfType Collections.Generic.List[Object]
            ,[PSInstance]::Create([Collections.Generic.List[Object]]@('a', 1)) | Should -BeOfType Collections.Generic.List[Object]
            ,[PSInstance]::Create([Collections.Generic.List[Object]]@('a', 1)) | Should -BeNullOrEmpty
        }

        it 'List[String]' {
            ,[PSInstance]::Create([Collections.Generic.List[String]]@())       | Should -BeOfType Collections.Generic.List[String]
            ,[PSInstance]::Create([Collections.Generic.List[String]]@('a'))    | Should -BeOfType Collections.Generic.List[String]
            ,[PSInstance]::Create([Collections.Generic.List[String]]@('a', 1)) | Should -BeOfType Collections.Generic.List[String]
            ,[PSInstance]::Create([Collections.Generic.List[String]]@('a', 1)) | Should -BeNullOrEmpty
        }

        it 'Dictionary[String,String]' {
            $Dictionary = [Collections.Generic.Dictionary[String,String]]::new()
            [PSInstance]::Create($Dictionary)       | Should -BeOfType 'Collections.Generic.Dictionary[String,String]'
            $Dictionary.Add('a', 1)
            [PSInstance]::Create($Dictionary)       | Should -BeOfType 'Collections.Generic.Dictionary[String,String]'
            [PSInstance]::Create($Dictionary).Count | Should -Be 0
        }

        it 'Dictionary[String,Object]' {
            $Dictionary = [Collections.Generic.Dictionary[String,Object]]::new()
            [PSInstance]::Create($Dictionary)       | Should -BeOfType 'Collections.Generic.Dictionary[String,Object]'
            $Dictionary.Add('a', 1)
            [PSInstance]::Create($Dictionary)       | Should -BeOfType 'Collections.Generic.Dictionary[String,Object]'
            [PSInstance]::Create($Dictionary).Count | Should -Be 0
        }

        it 'Ordered' {
            [PSInstance]::Create([Ordered]@{})                     | Should -BeOfType Collections.Specialized.OrderedDictionary
            [PSInstance]::Create([Ordered]@{ a = 1; b = 2 })       | Should -BeOfType Collections.Specialized.OrderedDictionary
            [PSInstance]::Create([Ordered]@{ a = 1; b = 2 }).Count | Should -Be 0
        }

        it 'PSCustomObject' {
            [PSInstance]::Create([PSCustomObject]@{})                                   | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create([PSCustomObject]@{ a = 1; b = 2 })                     | Should -BeOfType Management.Automation.PSCustomObject
            [PSInstance]::Create([PSCustomObject]@{ a = 1; b = 2 }).PSObject.Properties | Should -BeNullOrEmpty
        }

    }
}