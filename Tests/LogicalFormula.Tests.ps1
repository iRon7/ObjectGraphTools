#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

param()

Describe 'LogicalFormula' {

    BeforeAll {
        Set-StrictMode -Version Latest
    }

    Context 'Existence Check' {

        It 'Loaded' {
            [LogicalFormula]::new() -is [LogicalFormula] | Should -BeTrue
        }
    }

    Context 'Evaluate' {
        $ScriptBlock = {
            switch ($_) {
                'A' { $true }
                'B' { $false }
            }
        }

        $Formula = [LogicalFormula]::new("A or B")
        $Formula.Evaluate($ScriptBlock) | Should -BeTrue

        $Formula = [LogicalFormula]::new("A and B")
        $Formula.Evaluate($ScriptBlock) | Should -BeFalse
    }
}