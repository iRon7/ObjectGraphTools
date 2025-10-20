function Test($Depth = 0) {
    if ($Depth -gt 99) { "Reached $Depth" }
    else {
        Test ($Depth + 1)
        Start-Sleep -Milliseconds 100
        return
    }
}

Test
