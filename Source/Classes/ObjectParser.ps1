<#
.SYNOPSIS
    PowerShell Object Node Class

.DESCRIPTION
    This class provides general properties and method to recursively
    iterate through to PowerShell Object Graph nodes.

    *** commented help will follow ***
#>

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Name', Justification = 'False positive')]
param()

Class PSNode {
    static [int]$DefaultMaxDepth = 10
    [Int]$MaxDepth = [PSNode]::DefaultMaxDepth
    $Key                                    # The dictionary key or property name of the node
    $Index                                  # The list index of the node
    [Type]$Type
    [Int]$Depth
    hidden $_Value
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this               # This will be overwritten by the Append method
    hidden [Bool]$WarnedMaxDepth            # Warn one per item branch

    PSNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
        if ($Null -ne $Object)    { $this.Type = $Object.GetType() }
    }

    static [PSNode] ParseInput($Object) {
        if     ($Object -is [PSNode])                               { return $Object }
        elseif ($Object -is [Management.Automation.PSCustomObject]) { return [PSObjectNode]$Object }
        elseif ($Object -is [ComponentModel.Component])             { return [PSObjectNode]$Object }
        elseif ($Object -is [Collections.IDictionary])              { return [PSDictionaryNode]$Object }
        elseif ($Object -is [Collections.ICollection])              { return [PSListNode]$Object }
        else                                                        { return [PSLeafNode]$Object }
    }

    static [PSNode] ParseInput($Object, [int]$MaxDepth) {
        $Node = [PSNode]::parseInput($Object)
        $Node.MaxDepth = $MaxDepth
        return $Node
    }

    [PSNode] Append($Object) {
        $Node = [PSNode]::ParseInput($Object)
        $Node.Depth      = $this.Depth + 1
        $Node.ParentNode = $this
        $Node.RootNode   = $this.RootNode
        return $Node
    }

    hidden [System.Collections.Generic.List[PSNode]] get_Path() {
        if ($this.ParentNode) { $Path = $this.ParentNode.get_Path() }
        else { $Path = [System.Collections.Generic.List[PSNode]]::new() }
        $Path.Add($this)
        return $Path
    }

    hidden [String] get_PathName() {
        return -Join @($this.get_Path()).foreach{
            if ($Null -ne $_.Key) {
                if     ($_.Key -is [ValueType])        { ".$($_.Key)" }
                elseif ($_.Key -isnot [String])        { ".[$($_.Key.GetType())]'$($_.Key)'" }
                elseif ($_.Key -Match '^[_,a-z]+\w*$') { ".$($_.Key)" }
                else                                   { ".'$($_.Key)'" }
            }
            elseif ($Null -ne $_.Index) {
                "[$($_.Index)]"
            }
        }
    }
}

Class PSLeafNode : PSNode {
    PSLeafNode($Object) : base($Object) { }
}

Class PSCollectionNode : PSNode {
    PSCollectionNode($Object) : base($Object) { }

    hidden [bool]MaxDepthReached() {
        $MaxDepthReached = $this.Depth -ge $this.RootNode.MaxDepth
        if ($MaxDepthReached -and -not $this.WarnedMaxDepth) {
            Write-Warning "$($this.Path) reached the maximum depth of $($this.RootNode.MaxDepth)."
            $this.WarnedMaxDepth = $true
        }
        return $MaxDepthReached
    }
}

Class PSListNode : PSCollectionNode {
    PSListNode($Object) : base($Object) { }

    hidden [Int]get_Count() {
        return $this._Value.get_Count()
    }

    hidden [Array]get_Keys() {
        if ($this._Value.Length) { return 0..($this._Value.Length - 1) }
        return @()
    }

    hidden [Array]get_Values() {
        return $this._Value
    }

    [Bool]Contains($Index) {
       return $Index -ge 0 -and $Index -lt $this.get_Count()
    }

    [Object]GetItem($Index) {
            return $this._Value[$Index]
    }

    SetItem($Index, $Value) {
        $this._Value[$Index] = $Value
    }

    [PSNode[]]get_ChildNodes() {
        if ($this.MaxDepthReached()) { return @() }
        return @(
            for ($Index = 0; $Index -lt $this._Value.Get_Count(); $Index++) {
                $Node = $this.Append($this._Value[$Index])
                $Node.Index = $Index
                $Node
            }
        )
    }

    [Object]GetChildNode([Int]$Index) {
        if ($this.MaxDepthReached()) { return $Null }
        if ($Index -lt 0 -or $Index -ge $this._Value.get_Count()) { return $Null } # Return $Null if index is out of bound
        $Node = $this.Append($this._Value[$Index])
        $Node.Index = $Index
        return $Node
    }
}

Class PSMapNode : PSCollectionNode {
    PSMapNode($Object) : base($Object) { }
}

Class PSDictionaryNode : PSMapNode {
    PSDictionaryNode($Object) : base($Object) { }

    hidden [Int]get_Count() {
        return $this._Value.get_Count()
    }

    hidden [Array]get_Keys() {
        return $this._Value.get_Keys()
    }

    hidden [Array]get_Values() {
        return $this._Value.get_Values()
    }

    [Bool]Contains($Key) {
        return $this._Value.Contains($Key)
    }

    [Object]GetItem($Key) {
        return $this._Value[$Key]
    }

    SetItem($Key, $Value) {
        $this._Value[$Key] = $Value
    }

    [PSNode[]]get_ChildNodes() {
        if ($this.MaxDepthReached()) { return @() }
        return @(
            foreach($Key in $this._Value.get_Keys()) {
                $Node = $this.Append($this._Value[$Key])
                $Node.Key = $Key
                $Node
            }
        )
    }

    [Object]GetChildNode($Key) {
        if ($this.MaxDepthReached()) { return $Null }
        if (-not $this._Value.Contains($Key)) { return $Null } # Return $Null if index is out of bound
        $Node = $this.Append($this._Value[$Key])
        $Node.Key = $Key
        return $Node
    }
}

Class PSObjectNode : PSMapNode {
    PSObjectNode($Object) : base($Object) { }

    hidden [Int]get_Count() {
        return @($this._Value.PSObject.Properties).get_Count()
    }

    hidden [Array]get_Keys() {
        return $this._Value.PSObject.Properties.Name
    }

    hidden [Array]get_Values() {
        return $this._Value.PSObject.Properties.Value
    }

    [Bool]Contains($Name) {
        return $this._Value.PSObject.Properties[$Name]
    }

    [Object]GetItem($Name) {
        return $this._Value.PSObject.Properties[$Name].Value
    }

    SetItem($Name, $Value) {
        $this._Value.PSObject.Properties[$Name].Value = $Value
    }

    [PSNode[]]get_ChildNodes() {
        if ($this.MaxDepthReached()) { return @() }
        return @(
            foreach($Property in $this._Value.PSObject.Properties) {
                $Node = $this.Append($Property.Value)
                $Node.Key = $Property.Name
                $Node
            }
        )
    }

    [Object]GetChildNode([String]$Name) {
        if ($this.MaxDepthReached()) { return $Null }
        if ($Name -NotIn $this._Value.PSObject.Properties.Name) { return $Null } # Return $Null if index is out of bound
        $Node = $this.Append($this._Value.PSObject.Properties[$Name].Value)
        $Node.Key = $Name
        return $Node
    }
}

Update-TypeData -Force -TypeName PSNode -MemberName Value      -MemberType ScriptProperty -Value { return ,$this._Value } -SecondValue {
    Throw 'Node values are readonly. To change a node value, use the SetItem() method of its parent and reload the child node(s) if required.'
}
Update-TypeData -Force -TypeName PSNode -MemberName Count      -MemberType ScriptProperty -Value { return  $this.get_Count() }
Update-TypeData -Force -TypeName PSNode -MemberName Keys       -MemberType ScriptProperty -Value { return ,$this.get_Keys() }
Update-TypeData -Force -TypeName PSNode -MemberName Values     -MemberType ScriptProperty -Value { return ,$this.get_Values() }
Update-TypeData -Force -TypeName PSNode -MemberName ChildNodes -MemberType ScriptProperty -Value { return ,$this.get_ChildNodes() }
Update-TypeData -Force -TypeName PSNode -MemberName Path       -MemberType ScriptProperty -Value { return ,$this.get_Path() }
Update-TypeData -Force -TypeName PSNode -MemberName PathName   -MemberType ScriptProperty -Value { return  $this.get_PathName() }
