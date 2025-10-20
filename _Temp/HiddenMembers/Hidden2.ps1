class MyClass {
    MyClass() {
        $Method = { 'Hello World' }
        $Method.PSTypeNames.Insert([System.Management.Automation.HiddenAttribute])
        $TypeData = @{
            TypeName   = 'MyClass'
            MemberType = 'ScriptMethod'
            MemberName = 'MyMethod'
            Value      = $Method
        }
        Update-TypeData @TypeData
    }
}

$MyInstance = [MyClass]::new()

$MyInstance | Get-Member

$a = [System.Management.Automation.HiddenAttribute]{ return "Hello World" }