# This class is used to define the structure of an object (property)
# and to supply a common set of methods based on the structure
# See also: https://github.com/PowerShell/PowerShell/issues/20591

enum Construction { Undefined; Scalar; List; Dictionary; Component; Custom }
class PSInterface {
    [Type]$Type
    $Base
    [Construction]$Construction
    [Construction]$Structure

    PSInterface($Object) {
        if ($Object -is [Type]) { $Object = New-Object -TypeName $Object }
        if ($Object -is [PSInterface]) { $this.Base = $Object.Base } else { $this.Base = $Object }
        if ($Null -ne $Object) { $this.Type = $Object.GetType() }
        $this.Construction =
            if ($Object -is [Management.Automation.PSCustomObject]) { 'Custom' }
        elseif ($Object -is [ComponentModel.Component])             { 'Component' }
        elseif ($Object -is [Collections.IDictionary])              { 'Dictionary' }
        elseif ($Object -is [String])                               { 'Scalar' }
        elseif ($Object -is [Collections.IEnumerable])              { 'List' }
        else                                                        { 'Scalar' }
        $this.Structure = if ($this.Construction -le 'Dictionary') { $this.Construction } else { 'Dictionary' }
    }

    [Bool]Contains($Name) {
        if ($this.Construction -in 'Component', 'Custom') { return $Null -ne $this.Base.PSObject.Properties[$Name] }
        elseif ($this.Construction -in 'List', 'Dictionary') { return $this.Base.Contains($Name) }
        else { return $false }
    }

    [Object]Get($Name) {
        switch ($this.Construction) {
            Custom     { return $this.Base.PSObject.Properties[$Name].Value }
            Component  { return $this.Base.PSObject.Properties[$Name].Value }
            Dictionary { return $this.Base[$Name] }
            List       { return $this.Base[$Name] }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }

    Set($Name, $Value) {
        switch ($this.Construction) {
            Custom     { $this.Base.PSObject.Properties[$Name].Value = $Value }
            Component  { $this.Base.PSObject.Properties[$Name].Value = $Value }
            Dictionary { $this.Base[$Name] = $Value }
            List       { $this.Base[$Name] = $Value }
        }
    }

    [Int]get_Count() {
        switch ($this.Construction) {
            Custom     { return $this.Base.PSObject.Properties.Count }
            Component  { return $this.Base.PSObject.Properties.Count }
            Dictionary { return $this.Base.get_Count() }
            List       { return $this.Base.get_Count() }
        }
        return 0
    }

    [Array]get_Keys() {
        switch ($this.Construction) {
            Custom     { return $this.Base.PSObject.Properties.Name }
            Component  { return $this.Base.PSObject.Properties.Name }
            Dictionary { return $this.Base.get_Keys() }
            List       { return 0..($this.Base.Length - 1) }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }

    [Array]get_Values() {
        switch ($this.Construction) {
            Custom     { return $this.Base.PSObject.Properties.Value }
            Component  { return $this.Base.PSObject.Properties.Value }
            Dictionary { return $this.Base.get_Values() }
            List       { return $this.Base }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }

    [Array]get_Nodes() {
        switch ($this.Construction) {
            Custom     { return $this.Base.PSObject.Properties }
            Component  { return $this.Base.PSObject.Properties }
            Dictionary { return $this.Base.GetEnumerator() }
            List       { return $this.Base }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }
}