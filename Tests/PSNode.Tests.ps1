#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

using module ..\ObjectGraphTools.psm1
. $PSScriptRoot\..\Source\Classes\PSNode.ps1

Describe 'PSNode' {

    BeforeAll {

        Set-StrictMode -Version Latest
    }

    Context 'Sanity Check' {

        It 'Loaded' {
            [PSNode]1 | Should -BeOfType PSNode
        }
    }

    Context 'Basic functionality' {

        It 'Loaded' {
            ([PSNode]1).Structure | Should -Be 'Scalar'
            ([PSNode]1).Value     | Should -Be 1
        }
    }

    
}
