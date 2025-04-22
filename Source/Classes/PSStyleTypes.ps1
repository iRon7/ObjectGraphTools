using module .\..\..\ObjectGraphTools.psm1

Class ANSI {
    # Retrieved from Get-PSReadLineOption
    static [String]$CommandColor
    static [String]$CommentColor
    static [String]$ContinuationPromptColor
    static [String]$DefaultTokenColor
    static [String]$EmphasisColor
    static [String]$ErrorColor
    static [String]$KeywordColor
    static [String]$MemberColor
    static [String]$NumberColor
    static [String]$OperatorColor
    static [String]$ParameterColor
    static [String]$SelectionColor
    static [String]$StringColor
    static [String]$TypeColor
    static [String]$VariableColor

    # Hardcoded (if valid Get-PSReadLineOption)
    static [String]$Reset
    static [String]$ResetColor
    static [String]$InverseColor
    static [String]$InverseOff

    Static ANSI() {
        $PSReadLineOption = try { Get-PSReadLineOption -ErrorAction SilentlyContinue } catch { $null }
        if (-not $PSReadLineOption) { return }
        $ANSIType = [ANSI] -as [Type]
        foreach ($Property in [ANSI].GetProperties()) {
            $PSReadLineProperty = $PSReadLineOption.PSObject.Properties[$Property.Name]
            if ($PSReadLineProperty) {
                $ANSIType.GetProperty($Property.Name).SetValue($Property.Name, $PSReadLineProperty.Value)
            }
        }
        $Esc = [char]0x1b
        [ANSI]::Reset        = "$Esc[0m"
        [ANSI]::ResetColor   = "$Esc[39m"
        [ANSI]::InverseColor = "$Esc[7m"
        [ANSI]::InverseOff   = "$Esc[27m"
    }
}

Class TextStyle {
    hidden [String]$Text
    hidden [String]$AnsiCode
    hidden [String]$ResetCode = [ANSI]::Reset
    TextStyle ([String]$Text, [String]$AnsiCode, [String]$ResetCode) {
        $this.Text = $Text
        $this.AnsiCode = $AnsiCode
        $this.ResetCode = $ResetCode
    }
    TextStyle ([String]$Text, [String]$AnsiCode) {
        $this.Text = $Text
        $this.AnsiCode = $AnsiCode
    }
    [String] ToString() { return "$($this.AnsiCode)$($this.Text)$($this.ResetCode)" }
}
Class TextColor : TextStyle { TextColor($Text, $AnsiColor) : base($Text, $AnsiColor, [ANSI]::ResetColor) {} }

# -Replace '^static [\[]String[\]]\$(.*)', 'Class $1 : TextStyle { $1($Text) : base($Text, [ANSI]::$1) {} }'
Class CommandColor : TextColor { CommandColor($Text) : base($Text, [ANSI]::CommandColor) {} }
Class CommentColor : TextColor { CommentColor($Text) : base($Text, [ANSI]::CommentColor) {} }
Class ContinuationPromptColor : TextColor { ContinuationPromptColor($Text) : base($Text, [ANSI]::ContinuationPromptColor) {} }
Class DefaultTokenColor : TextColor { DefaultTokenColor($Text) : base($Text, [ANSI]::DefaultTokenColor) {} }
Class EmphasisColor : TextColor { EmphasisColor($Text) : base($Text, [ANSI]::EmphasisColor) {} }
Class ErrorColor : TextColor { ErrorColor($Text) : base($Text, [ANSI]::ErrorColor) {} }
Class KeywordColor : TextColor { KeywordColor($Text) : base($Text, [ANSI]::KeywordColor) {} }
Class MemberColor : TextColor { MemberColor($Text) : base($Text, [ANSI]::MemberColor) {} }
Class NumberColor : TextColor { NumberColor($Text) : base($Text, [ANSI]::NumberColor) {} }
Class OperatorColor : TextColor { OperatorColor($Text) : base($Text, [ANSI]::OperatorColor) {} }
Class ParameterColor : TextColor { ParameterColor($Text) : base($Text, [ANSI]::ParameterColor) {} }
Class SelectionColor : TextColor { SelectionColor($Text) : base($Text, [ANSI]::SelectionColor) {} }
Class StringColor : TextColor { StringColor($Text) : base($Text, [ANSI]::StringColor) {} }
Class TypeColor : TextColor { TypeColor($Text) : base($Text, [ANSI]::TypeColor) {} }
Class VariableColor : TextColor { VariableColor($Text) : base($Text, [ANSI]::VariableColor) {} }
Class InverseColor : TextStyle { InverseColor($Text) : base($Text, [ANSI]::InverseColor, [ANSI]::InverseOff) {} }