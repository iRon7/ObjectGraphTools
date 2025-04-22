using module .\..\..\ObjectGraphTools.psm1

Class PSInstance {
    static [Object]Create($Object) {
        if ($Null -eq $Object) { return $Null }
        elseif ($Object -is [String]) {
            $String = if ($Object.StartsWith('[') -and $Object.EndsWith(']')) { $Object.SubString(1, ($Object.Length - 2)) } else { $Object }
            Switch -Regex ($String) {
                '^((System\.)?String)?$'                                         { return '' }
                '^(System\.)?Array$'                                             { return ,@() }
                '^(System\.)?Object\[\]$'                                        { return ,@() }
                '^((System\.)?Collections\.Hashtable\.)?hashtable$'              { return @{} }
                '^((System\.)?Management\.Automation\.)?ScriptBlock$'            { return {} }
                '^((System\.)?Collections\.Specialized\.)?Ordered(Dictionary)?$' { return [Ordered]@{} }
                '^((System\.)?Management\.Automation\.)?PS(Custom)?Object$'      { return [PSCustomObject]@{} }
            }
            $Type = $String -as [Type]
            if (-not $Type) { Throw "Unknown type: [$Object]" }
        }
        elseif ($Object -is [Type]) {
            $Type = $Object.UnderlyingSystemType
            if     ("$Type" -eq 'string')      { Return '' }
            elseif ("$Type" -eq 'array')       { Return ,@() }
            elseif ("$Type" -eq 'scriptblock') { Return {} }
        }
        else {
            if     ($Object -is [Object[]])       { Return ,@() }
            elseif ($Object -is [ScriptBlock])    { Return {} }
            elseif ($Object -is [PSCustomObject]) { Return [PSCustomObject]::new() }
            $Type = $Object.GetType()
        }
        try { return [Activator]::CreateInstance($Type) } catch { throw $_ }
    }
}
