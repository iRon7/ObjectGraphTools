Describe 'Test' {

    BeforeAll {
        # Mock Get-Date { 1 / 0 }
        New-Item -Path Function:Get-Date -Value { 1 / 0 }
    }

    Context 'Context' {
        It 'It' {
            Get-Date | Should -be Something
        }
    }
}