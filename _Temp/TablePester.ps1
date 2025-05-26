function Build-TableShouldBe ($InputObject) {
    $Lines = ($InputObject | Format-Table -Auto | Out-String -Stream).TrimEnd().where{ $_ }
    $Digits = ($Lines.Count - 1).ToString().Length
    for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
        "`$Lines[{0:d$Digits}] | Should -be '{1}'" -f $Index, $Lines[$Index]
    }
}

# $Service = Get-Service | Select-Object -First 1
# Build-TableShouldBe $Service
