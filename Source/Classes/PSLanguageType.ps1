using module .\..\..\ObjectGraphTools.psm1

using namespace System.Collections.Generic
Class PSLanguageType {
    hidden static $_TypeCache = [Dictionary[String,Bool]]::new()
    hidden Static PSLanguageType() { # Hardcoded
        [PSLanguageType]::_TypeCache['System.Void'] = $True
        [PSLanguageType]::_TypeCache['System.Management.Automation.PSCustomObject'] = $True # https://github.com/PowerShell/PowerShell/issues/20767
    }
    static [Bool]IsRestricted($TypeName) {
        if ($Null -eq $TypeName) { return $True } # Warning: a $Null is considered a restricted "type"!
        $Type = $TypeName -as [Type]
        if ($Null -eq $Type) { Throw 'Unknown type name: $TypeName' }
        $TypeName = $Type.FullName
        return $TypeName -in 'bool', 'array', 'hashtable'
    }
    static [Bool]IsConstrained($TypeName) { # https://stackoverflow.com/a/64806919/1701026
        if ($Null -eq $TypeName) { return $True } # Warning: a $Null is considered a constrained "type"!
        $Type = $TypeName -as [Type]
        if ($Null -eq $Type) { Throw 'Unknown type name: $TypeName' }
        $TypeName = $Type.FullName
        if (-not [PSLanguageType]::_TypeCache.ContainsKey($TypeName)) {
            [PSLanguageType]::_TypeCache[$TypeName] = try {
                $ConstrainedSession = [PowerShell]::Create()
                $ConstrainedSession.RunSpace.SessionStateProxy.LanguageMode = 'Constrained'
                $ConstrainedSession.AddScript("[$TypeName]0").Invoke().Count -ne 0 -or
                $ConstrainedSession.Streams.Error[0].FullyQualifiedErrorId -ne 'ConversionSupportedOnlyToCoreTypes'
            } catch { $False }
        }
        return [PSLanguageType]::_TypeCache[$TypeName]
    }
}
