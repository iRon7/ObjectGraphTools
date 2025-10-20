$f = { param ($a, $b, $c) Write-Host $a $b $c; if ($b.Value) { $b.Value = 42 } }


#& $f 1 2 3

$a = 1
$b = @{ Value = 2 }
$c = 3
& $f $a $b $c
Write-Host $a $b $c

Function Test-Ref {
    param ([ref]$a, [ref]$b, [ref]$c)
    $a.Value = 1
    $b.Value = 2
    $c.Value = 3
}