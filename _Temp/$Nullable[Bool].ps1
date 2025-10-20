$a = [Nullable[Bool]]$null

Switch ($a) {
    $false { 'false' }
    $true  { 'true' }
    default { 'null' }
}