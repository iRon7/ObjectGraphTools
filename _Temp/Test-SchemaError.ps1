Using namespace System.Collections
Using namespace System.Collections.Generic

class PSSchemaError: Exception {
    PSSchemaError([IDictionary]$Data, [string]$Message): base ($Message) {
        foreach ($key in $Data.Keys) { $this.Data.Add($key, $Data[$key]) }
    }
}

function Test {
    $e = [PSSchemaError]::new(@{ Key3 = 'Value3' }, "Test")
    throw $e
}

Try { Test } Catch { $_.Exception.Data }
