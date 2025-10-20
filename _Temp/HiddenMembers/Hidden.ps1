class MyClass {
    MyClass() {
        $TargetType = 'MyClass' -as [Type]
        $Method = $TargetType.GetMethod('MyMethod')
        $Attributes = $Method.GetCustomAttributes($false)
        # $HiddenAttribute = $Attributes | Where-Object { $_ -is [System.Management.Automation.HiddenAttribute] }
        # $Attributes.Remove($HiddenAttribute)
        # foreach ($Attribute in $Attributes) {
        #     Write-Host ($Attribute | get-member | Out-String)
        # }
    }
    hidden MyHiddenMethod() { }
    MyMethod() { }
}

$MyInstance = [MyClass]::new()

$MyInstance | Get-Member

