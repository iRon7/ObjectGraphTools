class MyClass {
    [string] Get_Secret() { return "hidden stuff" }
}

$inst = [MyClass]::new()
$ps = [PSCustomObject]@{ Base = $inst }
$ps | Add-Member ScriptProperty Secret { $this.Base.Get_Secret() }
$ps.PSObject.Members["Secret"].IsHidden = $true


# $ps | Get-Member -force


# class MyClass { hidden [string]$Secret = 'Hidden property' }; $inst = [MyClass]::new(); $ps = [PSCustomObject]@{ Base = $inst }; $ps.PSObject.Members["Secret"]

