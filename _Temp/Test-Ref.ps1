function Test ($Issues) {
    if ($Issues -is [Ref]) { $Issues.Value = $true }
}

$Issues = [ref]$Null
$Param = @{ Issues = $Issues}
Test @Param
Write-Host 'Issues' $Issues.Value