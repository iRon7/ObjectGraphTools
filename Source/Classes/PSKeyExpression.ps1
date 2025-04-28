using module .\..\..\..\ObjectGraphTools

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
Class PSKeyExpression {
    hidden static [Regex]$UnquoteMatch = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
    hidden $Key
    hidden [PSLanguageMode]$LanguageMode = 'Restricted'
    hidden [Bool]$Compress
    hidden [Int]$MaxLength

    PSKeyExpression($Key)                                                 { $this.Key = $Key }
    PSKeyExpression($Key, [PSLanguageMode]$LanguageMode)                  { $this.Key = $Key; $this.LanguageMode = $LanguageMode }
    PSKeyExpression($Key, [PSLanguageMode]$LanguageMode, [Bool]$Compress) { $this.Key = $Key; $this.LanguageMode = $LanguageMode; $this.Compress = $Compress }
    PSKeyExpression($Key, [int]$MaxLength)                                { $this.Key = $Key; $this.MaxLength = $MaxLength }

    [String]ToString() {
        $Name = $this.Key
        if ($Name -is [byte]  -or $Name -is [int16]  -or $Name -is [int32]  -or $Name -is [int64]  -or
            $Name -is [sByte] -or $Name -is [uint16] -or $Name -is [uint32] -or $Name -is [uint64] -or
            $Name -is [float] -or $Name -is [double] -or $Name -is [decimal]) { return [Abbreviate]::new($Name, $this.MaxLength)
        }
        if ($this.MaxLength) { $Name = "$Name" }
        if ($Name -is [String]) {
            if ($Name -cMatch [PSKeyExpression]::UnquoteMatch) { return [Abbreviate]::new($Name, $this.MaxLength) }
            return "'$([Abbreviate]::new($Name.Replace("'", "''"), ($this.MaxLength - 2)))'"
        }
        $Node = [PSNode]::ParseInput($Name, 2) # There is no way to expand keys more than 2 levels
        return  [PSSerialize]::new($Node, $this.LanguageMode, -$this.Compress)
    }
}
