class MyClass {
    static MyClass() {
        $TypeData = @{
            TypeName   = 'MyClass'
            MemberType = 'ScriptMethod'
            MemberName = 'MyMethod'
            Value      = { 'Hello World' }
        }
        Update-TypeData @TypeData
    }
}

$MyInstance = [MyClass]::new()

$MyInstance.MyMethod()