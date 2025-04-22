$n = $Null

$a = 1..5
$r = :myLabel switch ($a) {
    { $true } { $n = 4 }
    2 { Write-Host 'Two' $_ $n }
    3 { 'test'; break mylabel }
}
$r