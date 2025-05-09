$Get = $Null

function Test ($Out) {
    $Out.PSTypeNames
    if ($Out) { $out.Value = 4 }
}

$Param = @{ Out = [ref]$Get }
Test @Param
Write-Host 'Get' $Get