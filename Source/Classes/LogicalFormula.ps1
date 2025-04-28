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
            # elseif ($Char -le ' ' -or $Null -eq $Char) { # A space or any control code
            #     if ($Start -lt $this.Pointer) {
            #         $this.Terms.Add($this.GetUnquotedTerm($Expression, $Start, ($this.Pointer - $Start)))
            #     }
            #     $Start = $this.Pointer + 1
            # }
            $this.Pointer++
        }
        if ($InString) { Throw "Missing the terminator: $InString in logical expression: $Expression" }
        if ($SubExpression) { Throw "Missing closing ')' in logical expression: $Expression" }
    }

    LogicalFormula ([String]$Expression) {
        $this.GetFormula($Expression, 0)
        if ($this.Pointer -lt $Expression.Length) {
            Throw "Unexpected token ')' at position $($this.Pointer) in logical expression: $Expression"
        }
    }

    LogicalFormula ([String]$Expression, $Start) {
        $this.GetFormula($Expression, $Start)
    }

    Append ([LogicalOperator]$Operator, [LogicalFormula]$Formula) {
        if ($Operator.Value -eq 'Not') { $this.Terms.Add([LogicalOperator]'And') }
        $this.Terms.Add($Operator)
        $this.Terms.AddRange($Formula.Terms)
    }

    [String] ToString() {
        $StringBuilder = [System.Text.StringBuilder]::new()
        $Stack = [System.Collections.Stack]::new()
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
                    if ($Term.Value -is [String])     { $null = $StringBuilder.Append([ANSI]::VariableColor) }
                    else                              { $null = $StringBuilder.Append([ANSI]::NumberColor) }
                }
                elseif ($Term -is [LogicalOperator])  { $null = $StringBuilder.Append([ANSI]::OperatorColor) }
                else { # if ($Term -is [LogicalFormula])
                    $null = $StringBuilder.Append([ANSI]::StringColor)
                    $null = $StringBuilder.Append('(')
                    $Stack.Push($Enumerator)
                    $Enumerator = $Term.Terms.GetEnumerator()
                    $Term = $null
                    continue
                }
                $null = $StringBuilder.Append($Term)
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
