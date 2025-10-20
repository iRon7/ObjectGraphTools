Using namespace System.Collections.Generic

Class T {
    [List[Object]]$List
    T() {}
    SetList() {
        Write-Host 123 ($Null -eq $this.List)
        $this.List = [List[Object]]@(1,2,3)
        Write-Host 124 ($Null -eq $this.List)
        $this.List = $Null
        Write-Host 125 ($Null -eq $this.List)
    }
}

$t = [t]::new()
$t.SetList()