[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Name', Justification = 'False positive')]
param()
enum Construction { Undefined; Scalar; List; Dictionary; Object }

Class PSNode {
    static [int]$MaxDepth       # Set the MaxDepth in the Begin of your cmdlet: [PSNode]::MaxDepth = $MaxDepth
    $Key                        # The dictionary key or propery name of the node
    $Index                      # This index of $this item
    [Int]$Depth
    [PSNode]$Parent
    hidden $Path
    hidden $PathName

    $Value
    [Type]$Type
    [Construction]$Construction
    [Construction]$Structure

    PSNode($Object) {
        if ($Object -is [PSNode]) { $this.Value = $Object.Value } else { $this.Value = $Object }
        if ($Null -ne $Object)    { $this.Type = $Object.GetType() }
        $this.Construction =
            if ($Object -is [Management.Automation.PSCustomObject]) { 'Object' }
        elseif ($Object -is [ComponentModel.Component])             { 'Object' }
        elseif ($Object -is [Collections.IDictionary])              { 'Dictionary' }
        elseif ($Object -is [Collections.ICollection])              { 'List' }
        else                                                            { 'Scalar' }
        $this.Structure = if ($this.Construction -le 'Dictionary') { $this.Construction } else { 'Dictionary' }
    }

    [PSNode]Renew() {
        $Object = New-Object -TypeName $this.Type
        $Node = [PSNode]::new($Object)
        ('Key', 'Index', 'Depth', 'Parent', 'Path', 'PathName').foreach{ $Node.$_ = $this.$_ }
        return $Node
    }

    [Array]GetPath() {
        if ($Null -eq $this.Path) {
            if     ($Null -ne $this.Index) { $this.Path = $this.Parent.GetPath() + $this.Index }
            elseif ($Null -ne $this.Key)   { $this.Path = $this.Parent.GetPath() + $this.Key }
            else                           { $this.Path = @() }
        }
        return $this.Path
    }

    [String]GetPathName() {
        if ($Null -eq $this.PathName) {
            if ($Null -eq $this.Parent) {
                $this.PathName = ''
            }
            elseif ($Null -ne $this.Key) {
                $Name =
                    if     ($this.Key -is [ValueType])        { "$($this.Key)" }
                    elseif ($this.Key -isnot [String])        { "[$($this.Key.GetType())]'$($this.Key)'" }
                    elseif ($this.Key -Match '^[_,a-z]+\w*$') { "$($this.Key)" }
                    else                                      { "$($this.Key)'" }
                $this.PathName = "$($this.Parent.GetPathName()).$Name"
            }
            elseif ($Null -ne $this.Index) {
                $this.PathName = "$($this.Parent.GetPathName())[$($this.Index)]"
            }
            else { Write-Error 'Should not happen' }
        }
        return $this.PathName
    }

    [Bool]Contains($Name) {
        if ($this.Construction -eq 'Object') { return $Null -ne $this.Value.PSObject.Properties[$Name] }
        elseif ($this.Construction -in 'List', 'Dictionary') { return $this.Value.Contains($Name) }
        else { return $false }
    }

    [Object]Get($Name) {
        switch ($this.Construction) {
            Object     { return $this.Value.PSObject.Properties[$Name].Value }
            Dictionary { return $this.Value[$Name] }
            List       { return $this.Value[$Name] }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }

    Set($Name, $Value) {
        switch ($this.Construction) {

            Object     { $this.Value.PSObject.Properties[$Name].Value = $Value }
            Dictionary { $this.Value[$Name] = $Value }
            List       { $this.Value[$Name] = $Value }
        }
    }

    [PSNode]GetItemNode($Key) {
        if ($this.Structure -eq 'Scalar') { Write-Error "Expected collection" }
        elseif ($this.Depth -ge [PSNode]::MaxDepth) {
            Write-Warning "$($this.GetPathName) reached the maximum depth of $([PSNode]::MaxDepth)."
        }
        elseif ($this.Structure -eq 'List') {
            $Node        = [PSNode]::new($this.Value[$Key])
            $Node.Index  = $Key
            $Node.Depth  = $this.Depth + 1
            $Node.Parent = $this
            return $Node
        }
        elseif ($this.Structure -eq 'Dictionary') {
            $Node        = [PSNode]::new($this.Value[$Key])
            $Node.Key    = $Key
            $Node.Depth  = $this.Depth + 1
            $Node.Parent = $this
            return $Node
        }
        return $null
    }

    [PSNode[]]GetItemNodes() {
        $ItemNodes = [Collections.Generic.List[PSNode]]::new()
        if ($this.Structure -eq 'Scalar') { Write-Error "Expected collection" }
        elseif ($this.Depth -ge [PSNode]::MaxDepth) {
            Write-Warning "$($this.GetPathName) reached the maximum depth of $([PSNode]::MaxDepth)."
        }
        elseif ($this.Structure -eq 'List') {
            for ($i = 0; $i -lt $this.Value.Count; $i++) {
                $Node        = [PSNode]::new($this.Value[$i])
                $Node.Index  = $i
                $Node.Depth  = $this.Depth + 1
                $Node.Parent = $this
                $ItemNodes.Add($Node)
            }
        }
        elseif ($this.Structure -eq 'Dictionary') {
            if ($this.Construction -eq 'Object') { $Items = $this.Value.PSObject.Properties }
            else                                 { $Items = $this.Value.GetEnumerator() }
            $i = 0
            $Items.foreach{
                $Node        = [PSNode]::new($_.Value)
                $Node.Key    = $_.Name
                $Node.Depth  = $this.Depth + 1
                $Node.Parent = $this
                $ItemNodes.Add($Node)
            }
        }
        return $ItemNodes
    }

    [Int]get_Count() {
        switch ($this.Construction) {
            Object     { return $this.Value.PSObject.Properties.Count }
            Dictionary { return $this.Value.get_Count() }
            List       { return $this.Value.get_Count() }
        }
        return 0
    }

    [Array]get_Keys() {
        switch ($this.Construction) {
            Object     { return $this.Value.PSObject.Properties.Name }
            Dictionary { return $this.Value.get_Keys() }
            List       { return 0..($this.Value.Length - 1) }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }

    [Array]get_Values() {
        switch ($this.Construction) {
            Object     { return $this.Value.PSObject.Properties.Value }
            Dictionary { return $this.Value.get_Values() }
            List       { return $this.Value }
        }
        return [Management.Automation.Internal.AutomationNull]::Value
    }
}
