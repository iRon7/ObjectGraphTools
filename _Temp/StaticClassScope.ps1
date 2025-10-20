function Test {
    param()
    begin {
        class MyClass {
            static [Int]$Count
        }
    }
    process {
        $a = [MyClass]::new()
        [MyClass]::Count++
        Write-Host 'Count:' ([MyClass]::Count)
        $_
    }
}

function Test1 {
    param()
    begin {
        class MyClass {
            static [Int]$Count
        }
    }
    process {
        $a = [MyClass]::new()
        [MyClass]::Count++
        Write-Host 'Count:' ([MyClass]::Count)
        $_
    }
}

'a', 'b', 'c' | Test | Test1