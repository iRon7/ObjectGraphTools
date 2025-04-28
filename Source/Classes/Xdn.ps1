using module .\..\..\..\ObjectGraphTools

enum XdnType { Root; Ancestor; Index; Child; Descendant; Equals; Error = 99 }

enum XdnColorName { Reset; Regular; Literal; WildCard; Operator; Error = 99 }

class XdnName {
    hidden [Bool]$_Literal
    hidden $_IsVerbatim
    hidden $_ContainsWildcard
    hidden $_Value

    hidden Initialize($Value, $Literal) {
        $this._Value = $Value
        if ($Null -ne $Literal) { $this._Literal = $Literal } else { $this._Literal = $this.IsVerbatim() }
        if ($this._Literal) {
            $XdnName = [XdnName]::new()
            $XdnName._ContainsWildcard = $False
         }
        else {
            $XdnName = [XdnName]::new()
            $XdnName._ContainsWildcard = $null
        }

    }
    XdnName() {}
    XdnName($Value)                    { $this.Initialize($Value, $null) }
    XdnName($Value, [Bool]$Literal)    { $this.Initialize($Value, $Literal) }
    static [XdnName]Literal($Value)    { return [XdnName]::new($Value, $true) }
    static [XdnName]Expression($Value) { return [XdnName]::new($Value, $false) }

    [Bool] IsVerbatim() {
        if ($Null -eq $this._IsVerbatim) {
            $this._IsVerbatim = $this._Value -is [String] -and $this._Value -Match '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
        }
        return $this._IsVerbatim
    }

    [Bool] ContainsWildcard() {
        if ($Null -eq $this._ContainsWildcard) {
            $this._ContainsWildcard = $this._Value -is [String] -and $this._Value -Match '(?<=([^`]|^)(``)*)[\?\*]'
        }
        return $this._ContainsWildcard
    }

    [Bool] Equals($Object) {
        if ($this._Literal)               { return $this._Value -eq $Object }
        elseif ($this.ContainsWildcard()) { return $Object -Like $this._Value }
        else                              { return $this._Value -eq $Object }
    }

    [String] ToString($Colored) {
        $Color = if ($Colored) {
            if ($this._Literal)               { [ANSI]::VariableColor }
            elseif (-not $this.IsVerbatim())  { [ANSI]::StringColor }
            elseif ($this.ContainsWildcard()) { [ANSI]::EmphasisColor }
            else                              { [ANSI]::VariableColor }
        }
        $String =
            if ($this._Literal) { "'" + "$($this._Value)".Replace("'", "''") + "'" }
            else { "$($this._Value)" -replace '(?<!([^`]|^)(``)*)[\.\[\~\=\/]', '`${0}' } # Escape any Xdn operator (that isn't yet escaped)
        $Reset = if ($Colored) { [ANSI]::ResetColor }
        return $Color + $String + $Reset
    }
    [String] ToString()        { return $this.ToString($False) }
    [String] ToColoredString() { return $this.ToString($True) }
}

class XdnPath {
    hidden $_Entries = [List[KeyValuePair[XdnType, Object]]]::new()

    hidden [Object]get_Entries() { return ,$this._Entries }

    XdnPath ([String]$Path)                 { $this.FromString($Path, $False) }
    XdnPath ([String]$Path, [Bool]$Literal) { $this.FromString($Path, $Literal) }
    XdnPath ([PSNodePath]$Path) {
        foreach ($Node in $Path.Nodes) {
            Switch ($Node.NodeOrigin) {
                Root { $this.Add('Root',  $Null) }
                List { $this.Add('Index', $Node.Name) }
                Map  { $this.Add('Child', [XdnName]$Node.Name) }
            }
        }
    }

    hidden AddError($Value) {
        $this._Entries.Add([KeyValuePair[XdnType, Object]]::new('Error', $Value))
    }

    Add ($EntryType, $Value) {
        if ($EntryType -eq '/') {
            if ($this._Entries.Count -eq 0) { $this.AddError($Value) }
            elseif ($this._Entries[-1].Key -NotIn 'Child', 'Descendant', 'Equals') { $this.AddError($Value) }
            else {
                $EntryValue = $this._Entries[-1].Value
                if ($EntryValue -IsNot [IList]) { $EntryValue = [List[Object]]$EntryValue }
                $EntryValue.Add($Value)
                $this._Entries[-1] = [KeyValuePair[XdnType, Object]]::new($this._Entries[-1].Key, $EntryValue)
            }
        }
        else {
            $XdnType = Switch ($EntryType) { '.' { 'Child' } '~' { 'Descendant' } '=' { 'Equals' } default { $EntryType } }
            if ($XdnType -in [XdnType].GetEnumNames()) {
                $this._Entries.Add([KeyValuePair[XdnType, Object]]::new($XdnType, $Value))
            } else { $this.AddError($Value) }

        }
    }

    hidden FromString ([String]$Path, [Bool]$Literal) {
        $XdnOperator = $Null
        if (-not $this._Entries.Count) {
            $IsRoot = if ($Literal) { $Path -NotMatch '^\.' } else { $Path -NotMatch '^(?<=([^`]|^)(``)*)\.' }
            if ($IsRoot) {
                $this.Add('Root', $Null)
                $XdnOperator = 'Child'
            }
        }
        $Length  = [Int]::MaxValue
        while ($Path) {
            if ($Path.Length -ge $Length) { break }
            $Length = $Path.Length
            if ($Path[0] -in "'", '"') {
                if (-not $XdnOperator) { $XdnOperator = 'Child' }
                $Ast = [Parser]::ParseInput($Path, [ref]$Null, [ref]$Null)
                $StringAst = $Ast.EndBlock.Statements.Find({ $args[0] -is [StringConstantExpressionAst] }, $False)
                if ($Null -ne $StringAst) {
                    $this.Add($XdnOperator, [XdnName]::Literal($StringAst[0].Value))
                    $Path = $Path.SubString($StringAst[0].Extent.EndOffset)
                }
                else { # Probably a quoting error
                    $this.Add($XdnOperator, [XdnName]::Literal($Path, $True))
                    $Path = $Null
                }
            }
            else {
                $Match = if ($Literal) { [regex]::Match($Path, '[\.\[]') } else { [regex]::Match($Path, '(?<=([^`]|^)(``)*)[\.\[\~\=\/]') }
                $Match = [regex]::Match($Path, '(?<=([^`]|^)(``)*)[\.\[\~\=\/]')
                if ($Match.Success -and $Match.Index -eq 0) { # Operator
                    $IndexEnd  = if ($Match.Value -eq '[') { $Path.IndexOf(']') }
                    $Ancestors = if ($Match.Value -eq '.' -and $Path -Match '^\.\.+') { $Matches[0].Length - 1 }
                    if ($IndexEnd -gt 0) {
                        $Index = $Path.SubString(1, ($IndexEnd - 1))
                        $CommandAst = [Parser]::ParseInput($Index, [ref]$Null, [ref]$Null).EndBlock.Statements.PipelineElements
                        if ($CommandAst -is [CommandExpressionAst]) { $Index = $CommandAst.expression.Value }
                        $this.Add('Index', $Index)
                        $Path = $Path.SubString(($IndexEnd + 1))
                        $XdnOperator = $Null
                    }
                    elseif ($Ancestors) {
                        $this.Add('Ancestor', $Ancestors)
                        $Path = $Path.Substring($Ancestors + 1)
                        $XdnOperator = 'Child'
                    }
                    elseif ($Match.Value -in '.', '~', '=', '/' -and $Match.Value -ne $XdnOperator) {
                        $XdnOperator = $Match.Value
                        $Path = $Path.Substring(1)
                    }
                    else {
                        $XdnOperator = 'Error'
                        $this.Add($XdnOperator, $Match.Value)
                        $Path = $Path.Substring(1)
                    }
                }
                elseif ($Match.Success) {
                    if (-not $XdnOperator) { $XdnOperator = 'Child' }
                    $Name = $Path.SubString(0, $Match.Index)
                    $Value = if ($Literal) { [XdnName]::Literal($Name) } else { [XdnName]::Expression($Name) }
                    $this.Add($XdnOperator, $Value)
                    $Path = $Path.SubString($Match.Index)
                    $XdnOperator = $Null
                }
                else {
                    $Value = if ($Literal) { [XdnName]::Literal($Path) } else { [XdnName]::Expression($Path)}
                    $this.Add($XdnOperator, $Value)
                    $Path = $Null
                }
            }
        }
    }

    [String] ToString([String]$VariableName, [Bool]$Colored) {
        $RegularColor  = if ($Colored) { [ANSI]::VariableColor }
        $OperatorColor = if ($Colored) { [ANSI]::CommandColor }
        $ErrorColor    = if ($Colored) { [ANSI]::ErrorColor }
        $ResetColor    = if ($Colored) { [ANSI]::ResetColor }

        $Path = [System.Text.StringBuilder]::new()
        $PreviousEntry = $Null
        foreach ($Entry in $this._Entries) {
            $Value = $Entry.Value
            $Append = Switch ($Entry.Key) {
                Root        { "$OperatorColor$VariableName" }
                Ancestor    { "$OperatorColor$('.' * $Value)" }
                Index       {
                                $Dot = if (-not $PreviousEntry -or $PreviousEntry.Key -eq 'Ancestor') { "$OperatorColor." }
                                if ([int]::TryParse($Value, [Ref]$Null)) { "$Dot$RegularColor[$Value]" }
                                else { "$ErrorColor[$Value]" }
                            }
                Child       { "$RegularColor.$(@($Value).foreach{ $_.ToString($Colored) }  -Join ""$OperatorColor/"")" }
                Descendant  { "$OperatorColor~$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Equals      { "$OperatorColor=$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Default     { "$ErrorColor$($Value)" }
            }
            $Path.Append($Append)
            $PreviousEntry = $Entry
        }
        $Path.Append($ResetColor)
        return $Path.ToString()
    }
    [String] ToString()                             { return $this.ToString($Null        , $False)}
    [String] ToString([String]$VariableName)        { return $this.ToString($VariableName, $False)}
    [String] ToColoredString()                      { return $this.ToString($Null,         $True)}
    [String] ToColoredString([String]$VariableName) { return $this.ToString($VariableName, $True)}

    static XdnPath() {
        Use-ClassAccessors
    }
}
