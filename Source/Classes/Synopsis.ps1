using module .\..\..\ObjectGraphTools.psm1

Class Text {
    static [String] Synopsis([String]$Prefix, [String]$String, [Int]$MaxLength, [String]$AndSoForth, [String]$Suffix) {
        if ($MaxLength -le 0) { return $String }
        if ($String.Length -gt 3 * $MaxLength) { $String = $String.SubString(0, (3 * $MaxLength)) } # https://stackoverflow.com/q/78787537/1701026
        $String = [Regex]::Replace($String, '\s+', ' ')
        if ($Prefix.Length + $String.Length + $Suffix.Length -gt $MaxLength) {
            $Length = $MaxLength - $Prefix.Length - $AndSoForth.Length - $Suffix.Length
            if ($Length -gt 0) { $String = $String.SubString(0, $Length) + $AndSoForth } else { $String = $AndSoForth }
        }
        return $Prefix + $String + $Suffix
    }

    static [String] Synopsis([String]$Prefix, [String]$String, [Int]$MaxLength, [String]$Suffix) {
        return [Text]::Synopsis($Prefix, $String, $MaxLength, '...', $Suffix)
    }

    static [String] Synopsis([String]$String, [Int]$MaxLength) {
        return [Text]::Synopsis('', $String, $MaxLength, '...', '')
    }
}
