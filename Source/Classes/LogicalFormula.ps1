using module .\..\..\..\ObjectGraphTools

using namespace System.Collections
using namespace System.Collections.Generic

enum LogicalOperatorEnum { not; and; or; xor }

class LogicalTerm {}

class LogicalOperator : LogicalTerm {
    hidden [LogicalOperatorEnum]$Value
    LogicalOperator ([LogicalOperatorEnum]$Operator) { $this.Value = $Operator }
    LogicalOperator ([String]$Operator) { $this.Value = [LogicalOperatorEnum]$Operator }
    [String]ToString() { return $this.Value }
}

class LogicalVariable : LogicalTerm {
    hidden [Object]$Value
    LogicalVariable ($Variable) { $this.Value = $Variable }
    [String]ToString() {
        if ($this.Value -is [String]) {
            return "'$($this.Value -Replace "'", "''")'"
        }
        else { return $this.Value }
    }
}

class LogicalFormula : LogicalTerm {
    hidden static $OperatorSymbols = @{
        '!' = [LogicalOperatorEnum]'Not'
        ',' = [LogicalOperatorEnum]'And'
        '*' = [LogicalOperatorEnum]'And'
        '|' = [LogicalOperatorEnum]'Or'
        '+' = [LogicalOperatorEnum]'Or'
    }
    hidden static [Int[]]$OperatorNameLengths

    hidden [List[LogicalTerm]]$Terms = [List[LogicalTerm]]::new()
    hidden [Int]$Pointer

    GetFormula([String]$Expression, [Int]$Start) {
        $SubExpression = $Start -gt 0
        $InString = $null # Quote type (double - or single quoted)
        $Escaped = $null
        $this.Pointer = $Start
        While ($this.Pointer -le $Expression.Length) {
            $Char = if ($this.Pointer -lt $Expression.Length) { $Expression[$this.Pointer] }
            if ($InString) {
                if ($Char -eq $InString) {
                    if ($this.Pointer + 1 -lt $Expression.Length -and $Expression[$this.Pointer + 1] -eq $InString) {
                        $Escaped = $true
                         $this.Pointer++
                    }
                    else {
                        $Name = $Expression.SubString($Start + 1, ($this.Pointer - $Start - 1))
                        if ($Escaped) { $Name = $Name.Replace("$InString$InString", $InString) }
                        $this.Terms.Add([LogicalVariable]::new($Name))
                        $InString = $Null
                        $Start = $this.Pointer + 1
                    }
                }
            }
            elseif ('"', "'" -eq $Char) {
                $InString = $Char
                $Escaped = $false
                $Start = $this.Pointer
            }
            elseif ($Char -eq '(') {
                $Formula = [LogicalFormula]::new($Expression, ($this.Pointer + 1))
                $this.Terms.Add($Formula)
                $this.Pointer = $Formula.Pointer
                $Start = $this.Pointer + 1
            }
            elseif ($Char -in $Null, ' ', ')' + [LogicalFormula]::OperatorSymbols.Keys) {
                $Length = $this.Pointer - $Start
                if ($Length -gt 0) {
                    $Term = $Expression.SubString($Start, $Length)
                    if ([LogicalOperatorEnum].GetEnumNames() -eq $Term) {
                        $this.Terms.Add([LogicalOperator]::new($Term))
                    }
                    else {
                        $Double = 0
                        if ([double]::TryParse($Term, [Ref]$Double)) {
                            $this.Terms.Add([LogicalVariable]::new($Double))
                        }
                        else {
                            $this.Terms.Add([LogicalVariable]::new($Term))
                        }
                    }
                }
                if ($Char -eq ')') { return }
                if ($Char -gt ' ') {
                    $this.Terms.Add([LogicalOperator]::new([LogicalFormula]::OperatorSymbols($Char)))
                }
                $Start = $this.Pointer + 1
            }
            $this.Pointer++
        }
        if ($InString) { Throw "Missing the terminator: $InString in logical expression: $Expression" }
        if ($SubExpression) { Throw "Missing closing ')' in logical expression: $Expression" }
    }

    LogicalFormula() {}
    LogicalFormula ([String]$Expression) {
        $this.GetFormula($Expression, 0)
        if ($this.Pointer -lt $Expression.Length) {
            Throw "Unexpected token ')' at position $($this.Pointer) in logical expression: $Expression"
        }
    }
    LogicalFormula ([String]$Expression, $Start) {
        $this.GetFormula($Expression, $Start)
    }

    Append ([LogicalOperator]$Operator, $Formula) {
        if ($Formula -is [LogicalFormula]) {
            if ($Formula.Terms.Count -eq 0) { return }
            if($this.Terms.Count -eq 0) {
                $This.Terms = $Formula.Terms
                return
            }
            if ($Operator.Value -eq 'Not') { $this.Terms.Add([LogicalOperator]'And') }
            $this.Terms.Add($Operator)
            if ($Formula.Terms.Count -gt 1) { $this.Terms.Add($Formula) }
            else { $this.Terms.Add($Formula.Terms[0]) }
        }
        elseif ($null -ne $Formula) {
            if ($this.Terms.Count -gt 0) { $this.Terms.Add([LogicalOperator]'And') }
            $this.Terms.Add([LogicalVariable]::new($Formula))
        }
    }
    And($Formula) { $this.Append('And', $Formula) }
    Or($Formula)  { $this.Append('Or',  $Formula) }
    Xor($Formula) { $this.Append('Xor', $Formula) }

    [Object]Find([ScriptBlock]$Predicate, [Bool]$All) {
        $Stack = [Stack]::new()
        $Enumerator = $this.Terms.GetEnumerator()
        $Term = $null
        return $(
            while ($true) {
                while ($Enumerator.MoveNext()) {
                    $Term = $Enumerator.Current
                    if ($Term -is [LogicalFormula]) {
                        $Stack.Push($Enumerator)
                        $Enumerator = $Term.Terms.GetEnumerator()
                        $Term = $null
                        continue
                    }
                    else {
                        if (& $Predicate $Term) { if ($All) { $Term } else { return $Term } }
                    }
                }
                if (-not $Stack.Count) { break }
                $Enumerator = $Stack.Pop()
            }
        )
    }

    [bool]Evaluate($Variables) {
        if (-not $this.Terms) { return $null -eq $Variables -or -not $Variables.Count }
        $Enumerator = $this.Terms.GetEnumerator()
        $Stack = [Stack]::new()
        $Stack.Push(@{
                Enumerator  = $Enumerator
                Accumulator = $null
                Operator    = $null
                Negate      = $null
            })
        $Term, $Negate, $Operand, $Operator, $Accumulator = $null
        $Score = 0
        while ($Stack.Count -gt 0) {
            # Accumulator = Accumulator <operation> Operand
            # if ($Stack.Count -gt 20) { Throw 'Formula stack failsafe'}
            $Pop = $Stack.Pop()
            $Enumerator = $Pop.Enumerator
            $Operator = $Pop.Operator
            if ($null -eq $Operator) { $Operand = $Pop.Accumulator }
            else { $Operand, $Accumulator = $Accumulator, $Pop.Accumulator }
            $Negate = $Pop.Negate
            $Compute = $null -notin $Operand, $Operator, $Accumulator
            while ($Compute -or $Enumerator.MoveNext()) {
                if ($Compute) { $Compute = $false }
                else {
                    $Term = $Enumerator.Current
                    if ($Term -is [LogicalVariable]) {
                            if ($Variables -is [ScriptBlock]) { $Operand = [Bool]$Term.Value.foreach($Variables) }
                        elseif ($Variables -is [IDictionary]) { $Operand = [Bool]$Variables[$Term.Value] }
                        elseif ($Variables -is [IEnumerable]) { $Operand = $Variables.Contains($Term.Value) }
                        else { $Operand = $Variables -eq $Term.Value }
                    }
                    elseif ($Term -is [LogicalOperator]) {
                        if ($Term.Value -eq 'Not') { $Negate = -not $Negate }
                        elseif ($null -eq $Operator -and $null -ne $Accumulator) { $Operator = $Term.Value }
                        else { throw [InvalidOperationException]"Unknown logical operator: $Term" }
                    }
                    elseif ($Term -is [LogicalFormula]) {
                        $Stack.Push(@{
                                Enumerator  = $Enumerator
                                Accumulator = $Accumulator
                                Operator    = $Operator
                                Negate      = $Negate
                            })
                        $Accumulator, $Operator, $Negate = $null
                        $Enumerator = $Term.Terms.GetEnumerator()
                        continue
                    }
                    else { throw [InvalidOperationException]"Unknown logical term: $Term" }
                }
                if ($null -ne $Operand) {
                    $Score++
                    if ($null -eq $Accumulator -xor $null -eq $Operator) {
                        if ($Accumulator) { throw [InvalidOperationException]"Missing operator before: $Term" }
                        else { throw [InvalidOperationException]"Missing variable before: $Operator $Term" }
                    }
                    $Operand = $Operand -xor $Negate
                    $Negate = $null
                    if ($Operator -eq 'And') {
                        $Operator = $null
                        if ($Accumulator -eq $false) { break }
                        $Accumulator = $Accumulator -and $Operand
                    }
                    elseif ($Operator -eq 'Or') {
                        $Operator = $null
                        if ($Accumulator -eq $true) { break }
                        $Accumulator = $Accumulator -or $Operand
                    }
                    elseif ($Operator -eq 'Xor') {
                        $Operator = $null
                        $Accumulator = $Accumulator -xor $Operand
                    }
                    else { $Accumulator = $Operand }
                    $Operand = $Null
                }
            }
            if ($null -ne $Operator -or $null -ne $Negate) { throw [InvalidOperationException]"Missing variable after $Operator" }
        }
        if ($null -eq $Accumulator) { throw "The accumulator isn't defined" }
        return $Accumulator
    }

    [String] ToString() { return $this.ToString($null) }
    [String] ToString([IDictionary]$Extents) {
        $StringBuilder = [System.Text.StringBuilder]::new()
        $Stack = [Stack]::new()
        $Enumerator = $this.Terms.GetEnumerator()
        $Term = $null
        while ($true) {
            while ($Enumerator.MoveNext()) {
                if ($Null -ne $Term) {
                    $null = $StringBuilder.Append([ANSI]::ResetColor) # Not really necessarily
                    $null = $StringBuilder.Append(' ')
                }
                $Term = $Enumerator.Current
                if ($Term -is [LogicalVariable]) {
                    if ($Term.Value -is [String]) { $null = $StringBuilder.Append([ANSI]::VariableColor) }
                    else                          { $null = $StringBuilder.Append([ANSI]::NumberColor) }
                    $null = $StringBuilder.Append($Term)
                    if ($Extents) {
                        $null = $StringBuilder.Append([ANSI]::EmphasisColor)
                        $null = $StringBuilder.Append($Extents[$Term.Value])
                    }
                }
                elseif ($Term -is [LogicalOperator])  {
                    $null = $StringBuilder.Append([ANSI]::OperatorColor)
                    $null = $StringBuilder.Append($Term)
                }
                else { # if ($Term -is [LogicalFormula])
                    $null = $StringBuilder.Append([ANSI]::StringColor)
                    $null = $StringBuilder.Append('(')
                    $Stack.Push($Enumerator)
                    $Enumerator = $Term.Terms.GetEnumerator()
                    $Term = $null
                    continue
                }
            }
            if (-not $Stack.Count) {
                $null = $StringBuilder.Append([ANSI]::ResetColor)
                break
            }
            $null = $StringBuilder.Append([ANSI]::StringColor)
            $null = $StringBuilder.Append(')')
            $Enumerator = $Stack.Pop()
        }
        return $StringBuilder.ToString()
    }
}
