function Write-Immediately {
    param([int]$Depth = 0, $RefTest)
    begin { Write-Output 'Beginning...' }
    process {
        if ($Depth -gt 0) {
            Write-Output "Processing $Depth"
            Write-Immediately -Depth ($Depth - 1) -RefTest ([Ref]$Test)
        }
        Start-Sleep 1
        $RefTest.Value = $RefTest.Value + "$Depth"
    }
    end { Write-Output 'Ending...' }
}

$Test = ''
Write-Immediately -Depth 5 -RefTest ([Ref]$Test)
$Test