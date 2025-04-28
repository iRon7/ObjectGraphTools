Class Abbreviate {
    hidden static [String]$Ellipses = [Char]0x2026

    hidden [String] $Prefix
    hidden [String] $String
    hidden [String] $AndSoForth = [Abbreviate]::Ellipses
    hidden [String] $Suffix
    hidden [Int] $MaxLength

    Abbreviate([String]$Prefix, [String]$String, [Int]$MaxLength, [String]$AndSoForth, [String]$Suffix) {
        $this.Prefix     = $Prefix
        $this.String     = $String
        $this.MaxLength  = $MaxLength
        $this.AndSoForth = $AndSoForth
        $this.Suffix     = $Suffix
    }
    Abbreviate([String]$Prefix, [String]$String, [Int]$MaxLength, [String]$Suffix) {
        $this.Prefix    = $Prefix
        $this.String    = $String
        $this.MaxLength = $MaxLength
        $this.Suffix    = $Suffix
    }
    Abbreviate([String]$String, [Int]$MaxLength) {
        $this.String    = $String
        $this.MaxLength = $MaxLength
    }

    [String] ToString() {
        if ($this.MaxLength -le 0) { return $this.String }
        if ($this.String.Length -gt 3 * $this.MaxLength) { $this.String = $this.String.SubString(0, (3 * $this.MaxLength)) } # https://stackoverflow.com/q/78787537/1701026
        $this.String = [Regex]::Replace($this.String, '\s+', ' ')
        if ($this.Prefix.Length + $this.String.Length + $this.Suffix.Length -gt $this.MaxLength) {
            $Length = $this.MaxLength - $this.Prefix.Length - $this.AndSoForth.Length - $this.Suffix.Length
            if ($Length -gt 0) { $this.String = $this.String.SubString(0, $Length) + $this.AndSoForth } else { $this.String = $this.AndSoForth }
        }
        return $this.Prefix + $this.String + $this.Suffix
    }
}