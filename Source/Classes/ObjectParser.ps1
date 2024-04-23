<#
.SYNOPSIS
    Class to support Object Graph Tools
.DESCRIPTION
    This class provides general properties and method to recursively
    iterate through to PowerShell Object Graph nodes.

    For details, see:

    * [PowerShell Object Parser][1] for details on the `[PSNode]` properties and methods.
    * [Extended-Dot-Notation][2] for details on path selectors.

.LINK
    [1]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/ObjectParser.md "PowerShell Object Parser"
    [2]: https://github.com/iRon7/ObjectGraphTools/blob/main/Docs/Xdn.md "Extended Dot Notation"
#>

using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Class LanguageType {
    hidden static $_TypeCache = [Dictionary[String,Bool]]::new()
    hidden Static LanguageType() {
        [LanguageType]::_TypeCache['System.Management.Automation.PSCustomObject'] = $True # https://github.com/PowerShell/PowerShell/issues/20767
    }
    static [Bool]IsConstrained([Type]$Type) { # https://stackoverflow.com/a/64806919/1701026
        if ($Null -eq $Type) { Throw 'The type can not be $Null' }
        $FullName = $Type.FullName
        if (-not [LanguageType]::_TypeCache.ContainsKey($FullName)) {
            [LanguageType]::_TypeCache[$FullName] = try {
                $ConstrainedSession = [PowerShell]::Create()
                $ConstrainedSession.RunSpace.SessionStateProxy.LanguageMode = 'Constrained'
                $ConstrainedSession.AddScript("[$FullName]0").Invoke().Count -ne 0 -or
                $ConstrainedSession.Streams.Error[0].FullyQualifiedErrorId -ne 'ConversionSupportedOnlyToCoreTypes'
            } catch { $False }
        }
        return [LanguageType]::_TypeCache[$FullName]
    }
}

# ____  ____ ____            _       _ _
# |  _ \/ ___/ ___|  ___ _ __(_) __ _| (_)_______
# | |_) \___ \___ \ / _ \ '__| |/ _` | | |_  / _ \
# |  __/ ___) |__) |  __/ |  | | (_| | | |/ /  __/
# |_|   |____/____/ \___|_|  |_|\__,_|_|_/___\___|

Class PSSerialize {
    hidden static [String[]]$Parameters = 'LanguageMode', 'Explicit', 'FullTypeName', 'HighFidelity', 'Indent', 'ExpandSingleton'
    hidden [PSLanguageMode]$LanguageMode = 'Restricted'
    hidden [Int]$ExpandDepth = [Int]::MaxValue
    hidden [Bool]$Explicit
    hidden [Bool]$FullTypeName
    hidden [bool]$HighFidelity
    hidden [String]$Indent = '    '
    hidden [Bool]$ExpandSingleton

    hidden static [Dictionary[String,Bool]]$IsConstrainedType = [Dictionary[String,Bool]]::new()
    hidden static [Dictionary[String,Bool]]$HasStringConstructor = [Dictionary[String,Bool]]::new()

    # The dictionary below defines the round trip property. Unless the `-HighFidelity` switch is set,
    # the serialization will stop (even it concerns a `PSCollectionNode`) when the specific property
    # type is reached.
    # * An empty string will return the string representation of the object: `"<Object>"`
    # * Any other string will return the string representation of the object property: `"$(<Object>.<Property>)"`
    # * A ScriptBlock will be invoked and the result will be used for the object value

    hidden static $RoundTripProperty = @{
        'Microsoft.Management.Infrastructure.CimInstance'                     = ''
        'Microsoft.Management.Infrastructure.CimSession'                      = 'ComputerName'
        'Microsoft.PowerShell.Commands.ModuleSpecification'                   = 'Name'
        'System.DateTime'                                                     = { $($Input).ToString('o') }
        'System.DirectoryServices.DirectoryEntry'                             = 'Path'
        'System.DirectoryServices.DirectorySearcher'                          = 'Filter'
        'System.Globalization.CultureInfo'                                    = 'Name'
        'Microsoft.PowerShell.VistaCultureInfo'                               = 'Name'
        'System.Management.Automation.AliasAttribute'                         = 'AliasNames'
        'System.Management.Automation.ArgumentCompleterAttribute'             = 'ScriptBlock'
        'System.Management.Automation.ConfirmImpact'                          = ''
        'System.Management.Automation.DSCResourceRunAsCredential'             = ''
        'System.Management.Automation.ExperimentAction'                       = ''
        'System.Management.Automation.OutputTypeAttribute'                    = 'Type'
        'System.Management.Automation.PSCredential'                           = { ,@($($Input).UserName, @("(""$($($Input).Password | ConvertFrom-SecureString)""", '|', 'ConvertTo-SecureString)')) }
        'System.Management.Automation.PSListModifier'                         = 'Replace'
        'System.Management.Automation.PSReference'                            = 'Value'
        'System.Management.Automation.PSTypeNameAttribute'                    = 'PSTypeName'
        'System.Management.Automation.RemotingCapability'                     = ''
        'System.Management.Automation.ScriptBlock'                            = 'Ast'
        'System.Management.Automation.SemanticVersion'                        = ''
        'System.Management.Automation.ValidatePatternAttribute'               = 'RegexPattern'
        'System.Management.Automation.ValidateScriptAttribute'                = 'ScriptBlock'
        'System.Management.Automation.ValidateSetAttribute'                   = 'ValidValues'
        'System.Management.Automation.WildcardPattern'                        = { $($Input).ToWql().Replace('%', '*').Replace('_', '?').Replace('[*]', '%').Replace('[?]', '_') }
        'Microsoft.Management.Infrastructure.CimType'                         = ''
        'System.Management.ManagementClass'                                   = 'Path'
        'System.Management.ManagementObject'                                  = 'Path'
        'System.Management.ManagementObjectSearcher'                          = { $($Input).Query.QueryString }
        'System.Net.IPAddress'                                                = 'IPAddressToString'
        'System.Net.IPEndPoint'                                               = { $($Input).Address.Address; $($Input).Port }
        'System.Net.Mail.MailAddress'                                         = 'Address'
        'System.Net.NetworkInformation.PhysicalAddress'                       = ''
        'System.Security.Cryptography.X509Certificates.X500DistinguishedName' = 'Name'
        'System.Security.SecureString'                                        = { ,[string[]]("(""$($Input | ConvertFrom-SecureString)""", '|', 'ConvertTo-SecureString)') }
        'System.Text.RegularExpressions.Regex'                                = ''
        'System.Uri'                                                          = 'OriginalString'
        'System.Version'                                                      = ''
        'System.Void'                                                         = $Null
    }
    hidden [System.Text.StringBuilder]$StringBuilder = [System.Text.StringBuilder]::new()
    hidden [Int]$Offset = 0
    hidden [Int]$LineNumber = 1

    PSSerialize($Object) { $this.Serialize($Object) }
    PSSerialize(
        $Object,
        $LanguageMode    = 'Restricted',
        $ExpandDepth     = [Int]::MaxValue,
        $Explicit        = $False,
        $FullTypeName    = $False,
        $HighFidelity    = $False,
        $ExpandSingleton = $False,
        $Indent          = '    '
    ) {
        $this.LanguageMode    = $LanguageMode
        $this.ExpandDepth     = $ExpandDepth
        $this.Explicit        = $Explicit
        $this.FullTypeName    = $FullTypeName
        $this.HighFidelity    = $HighFidelity
        $this.ExpandSingleton = $ExpandSingleton
        $this.Indent          = $Indent
        $this.Serialize($Object)
    }
    PSSerialize($Object, [HashTable]$Parameters) {
        foreach ($Name in $Parameters.get_Keys()) { # https://github.com/PowerShell/PowerShell/issues/13307
            if ($Name -notin [PSSerialize]::Parameters) { Throw "Unknown parameter: $Name." }
            $this.GetType().GetProperty($Name).SetValue($this, $Parameters[$Name])
        }
        $this.Serialize($Object)
    }

    [String]Serialize($Object) {
        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
        if (-not ('ConstrainedLanguage', 'FullLanguage' -eq $this.LanguageMode)) {
            if ($this.FullTypeName) { Write-Warning 'The FullTypeName switch requires Constrained - or FullLanguage mode.' }
            if ($this.Explicit)     { Write-Warning 'The Explicit switch requires Constrained - or FullLanguage mode.' }
        }
        if ($Object -is [PSNode]) { $Node = $Object }
        else { $Node = [PSNode]::ParseInput($Object) }
        $this.Iterate($Node)
        return $this.StringBuilder.ToString()
    }

    hidden Iterate([PSNode]$Node) {
        $Value = $Node.Value
        if ($Null -eq $Value) {
            $this.StringBuilder.Append('$Null')
            return
        }
        $Type = $Node.ValueType
        $TypeName = "$Type"
        $TypeInitializer =
            if ($Null -ne $Type -and (
                $this.LanguageMode -eq 'Full' -or (
                        $this.LanguageMode -eq 'Constrained' -and
                        [LanguageType]::IsConstrained($Type) -and (
                            $this.Explicit -or -not (
                                $Type.IsPrimitive      -or
                                $Value -is [String]    -or
                                $Value -is [Object[]]  -or
                                $Value -is [Hashtable]
                            )
                        )
                    )
                )
                ) {
                    if ($this.FullTypeName) {
                        if ($Type.FullName -eq 'System.Management.Automation.PSCustomObject' ) { '[System.Management.Automation.PSObject]' } # https://github.com/PowerShell/PowerShell/issues/2295
                        else { "[$($Type.FullName)]" }
                    }
                    elseif ($TypeName -eq 'System.Object[]') { "[array]" }
                    elseif ($TypeName -eq 'System.Management.Automation.PSCustomObject') { "[PSCustomObject]" }
                    else { "[$TypeName]" }
                }
        if ($TypeInitializer) { $this.StringBuilder.Append($TypeInitializer) }

        if ($Node -is [PSLeafNode] -or (-not $this.HighFidelity -and [PSSerialize]::RoundTripProperty.Contains($Node.ValueType.FullName))) {
            $Expression =
                if ([PSSerialize]::RoundTripProperty.Contains($Node.ValueType.FullName)) {
                    $Property = [PSSerialize]::RoundTripProperty[$Node.ValueType.FullName]
                        if ($Null -eq $Property)                      { $Null }
                    elseif ($Property -is [String])                   { if ($Property) { ,$Value.$Property } else { "$Value" } }
                    elseif ($Property -is [ScriptBlock] )             { Invoke-Command $Property -InputObject $Value }
                    elseif ($Property -is [HashTable])                { if ($this.LanguageMode -eq 'Restricted') { $Null } else { @{} } }
                    elseif ($Property -is [Array])                    { @($Property.foreach{ $Value.$_ }) }
                    else { Throw "Unknown round trip property type: $($Property.GetType())."}
                }
                elseif ($Type.IsPrimitive)                        { $Value }
                elseif (-not $Type.GetConstructors())             { "$TypeName" }
                elseif ($Type.GetMethod('ToString', [Type[]]@())) { $Value.ToString() }
                elseif ($Value -is [Collections.ICollection])     { ,$Value }
                else                                              { $Value } # Handle compression

            if     ($Null -eq $Expression)         { $Expression = '$Null' }
            elseif ($Expression -is [Bool])        { $Expression = "`$$Value" }
            elseif ($Expression -is [Char])        { $Expression = "'$Value'" }
            elseif ($Expression -is [ScriptBlock]) { $Expression = $Expression.Ast.Extent.Text }
            elseif ($Expression -is [HashTable])   { $Expression = '@{}' }
            elseif ($Expression -is [array]) {
                $Space = if ($this.ExpandDepth -ge 0) { ' ' }
                $New = if ($TypeInitializer) { '::new(' } else { '@(' }
                $Expression = $New + ($Expression.foreach{
                    if ($Null -eq $_)  { '$Null' }
                    elseif ($_.GetType().IsPrimitive) { "$_" }
                    elseif ($_ -is [Array]) { $_ -Join $Space }
                    else { "'$_'" }
                } -Join ",$Space") + ')'
            }
            elseif ($Type -and $Type.IsPrimitive) { }
            else {
                if ($Expression -isnot [String]) { $Expression = "$Expression" }
                $Expression = if ($Expression.Contains("`n")) {
                    "@'" + [Environment]::NewLine + "$Expression".Replace("'", "''") + [Environment]::NewLine + "'@"
                }
                else {
                    "'" + "$Expression".Replace("'", "''") + "'"
                }
            }

            $this.StringBuilder.Append($Expression)
        }
        elseif ($Node -is [PSListNode]) {
            $this.StringBuilder.Append('@(')
            $this.Offset++
            $StartLine = $this.LineNumber
            $Index = 0
            $ChildNodes = $Node.get_ChildNodes()
            $ExpandSingle = $this.ExpandSingleton -or $ChildNodes.Count -gt 1 -or ($ChildNodes.Count -eq 1 -and $ChildNodes[0] -isnot [PSLeafNode])
            $ChildNodes.foreach{
                if ($Index++) {
                    $this.StringBuilder.Append(',')
                    $this.NewWord()
                }
                elseif ($ExpandSingle) { $this.NewWord('') }
                $this.Iterate($_)
            }
            $this.Offset--
            if ($this.LineNumber -gt $StartLine) { $this.NewWord('') }
            $this.StringBuilder.Append(')')
        }
        else { # if ($Node -is [PSMapNode]) {
            $ChildNodes = $Node.get_ChildNodes()
            if ($ChildNodes) {
                $this.StringBuilder.Append('@{')
                $this.Offset++
                $StartLine = $this.LineNumber
                $Index = 0
                $ExpandSingle = $this.ExpandSingleton -or $ChildNodes.Count -gt 1 -or $ChildNodes[0] -isnot [PSLeafNode]
                $ChildNodes.foreach{
                    if ($Index++) {
                        $Separator = if ($this.ExpandDepth -ge 0) { '; ' } else { ';' }
                        $this.NewWord($Separator)
                    }
                    elseif ($ExpandSingle) { $this.NewWord() }
                    elseif ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' ') }
                    $this.StringBuilder.Append($_.Name)
                    if ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' = ') } else { $this.StringBuilder.Append('=') }
                    $this.Iterate($_)
                }
                $this.Offset--
                if ($this.LineNumber -gt $StartLine) { $this.NewWord() } else { $this.StringBuilder.Append(' ') }
                $this.StringBuilder.Append('}')
            }
            elseif ($Node -is [PSObjectNode] -and $TypeInitializer) { $this.StringBuilder.Append('::new()') }
            else { $this.StringBuilder.Append('@{}') }
        }
    }

    hidden NewWord() { $this.NewWord(' ') }
    hidden NewWord([String]$Separator) {
        if ($this.Offset -le $this.ExpandDepth) {
            $this.StringBuilder.AppendLine()
            for($i = $this.Offset; $i -gt 0; $i--) {
                $this.StringBuilder.Append($this.Indent)
            }
            $this.LineNumber++
        }
        else {
            $this.StringBuilder.Append($Separator)
        }
    }

    hidden [String]Quote($Value) { return "'" + "$Value".Replace("'", "''") + "'" }

    [String] ToString() {
        return $this.StringBuilder.ToString()
    }
 }

#  ____  ____  ____                      _       _ _
# |  _ \/ ___||  _ \  ___  ___  ___ _ __(_) __ _| (_)_______
# | |_) \___ \| | | |/ _ \/ __|/ _ \ '__| |/ _` | | |_  / _ \
# |  __/ ___) | |_| |  __/\__ \  __/ |  | | (_| | | |/ /  __/
# |_|   |____/|____/ \___||___/\___|_|  |_|\__,_|_|_/___\___|

 Class PSDeserialize {
    hidden static [String[]]$Parameters = 'LanguageMode', 'ArrayType', 'HashTableType'
    hidden static PSDeserialize() { Use-ClassAccessors }

    hidden $_Object
    [PSLanguageMode]$LanguageMode = 'Restricted'
    [Type]$ArrayType     = 'Array'     -as [Type]
    [Type]$HashTableType = 'HashTable' -as [Type]
    [String] $Expression

    PSDeserialize([String]$Expression) { $this.Expression = $Expression }
    PSDeserialize([String]$Expression, [PSLanguageMode]$LanguageMode) {
        $this.Expression = $Expression
        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
        $this.LanguageMode = $LanguageMode
    }
    PSDeserialize(
        $Expression,
        $LanguageMode  = 'Restricted',
        $ArrayType,
        $HashTableType
    ) {
        $this.Expression    = $Expression
        $this.LanguageMode  = $LanguageMode
        if ($Null -ne $ArrayType)     { $this.ArrayType     = $ArrayType }
        if ($Null -ne $HashTableType) { $this.HashTableType = $HashTableType }
    }

    PSDeserialize($Expression, [HashTable]$Parameters) {
        $this.Expression = $Expression
        foreach ($Name in $Parameters.get_Keys()) { # https://github.com/PowerShell/PowerShell/issues/13307
            if ($Name -notin [PSSerialize]::Parameters) { Throw "Unknown parameter: $Name." }
            $this.GetType().GetProperty($Name).SetValue($this, $Parameters[$Name])
        }
    }

    hidden [Object] get_Object() {
        if ($Null -eq $this._Object) {
            $Ast = [System.Management.Automation.Language.Parser]::ParseInput($this.Expression, [ref]$null, [ref]$Null)
            $this._Object = $this.ParseAst([Ast]$Ast)
        }
        return $this._Object
    }

    hidden [Object] ParseAst([Ast]$Ast) {
        # Write-Host 'Ast type:' "$($Ast.getType())"
        $Type = $Null
        if ($Ast -is [ConvertExpressionAst]) {
            $FullTypeName = $Ast.Type.TypeName.FullName
            if (
                $this.LanguageMode -eq 'Full' -or (
                    $this.LanguageMode -eq 'Constrained' -and
                    [LanguageType]::IsConstrained($FullTypeName)
                )
            ) {
                try { $Type = $FullTypeName -as [Type] } catch { write-error $_ }
            }
            $Ast = $Ast.Child
        }
        if ($Ast -is [ScriptBlockAst]) {
            $List = [List[Object]]::new()
            if ($Null -ne $Ast.BeginBlock)   { $Ast.BeginBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($Null -ne $Ast.ProcessBlock) { $Ast.ProcessBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($Null -ne $Ast.EndBlock)     { $Ast.EndBlock.Statements.ForEach{ $List.Add($this.ParseAst($_)) } }
            if ($List.Count -eq 1) { return $List[0] } else { return @($List) }
        }
        elseif ($Ast -is [PipelineAst]) {
            $Element = $Ast.PipelineElements.Expression
                if ($Element.Count -eq 0) { return @() }
            elseif ($Element.Count -eq 1) { return $this.ParseAst($Element[0]) }
            else                          { return $Element.Foreach{ $this.ParseAst($_) } }
        }
        elseif ($Ast -is [ArrayLiteralAst] -or $Ast -is [ArrayExpressionAst]) {
            if (-not $Type -or 'System.Object[]', 'System.Array' -eq $Type.FullName) { $Type = $this.ArrayType }
            if ($Ast -is [ArrayLiteralAst]) { $Value = $Ast.Elements.foreach{ $this.ParseAst($_) } }
            else { $Value = $Ast.SubExpression.Statements.foreach{ $this.ParseAst($_) } }
            if ('System.Object[]', 'System.Array' -eq $Type.FullName) {
                if ($Value -isnot [Array]) { $Value = @($Value) } # Prevent single item array unrolls
            }
            else { $Value = $Value -as $Type }
            return $Value
        }
        elseif ($Ast -is [HashtableAst]) {
            if (-not $Type -or $Type.FullName -eq 'System.Collections.Hashtable') { $Type = $this.HashTableType }
            $IsPSCustomObject = "$Type" -in
                'PSCustomObject',
                'System.Management.Automation.PSCustomObject',
                'psobject',
                'System.Management.Automation.PSObject'
            if ($Type.FullName -eq 'System.Collections.Hashtable') { $Map = @{} } # Case insensitive
            elseif ($IsPSCustomObject) { $Map = [Ordered]@{} }
            else { $Map = New-Object -Type $Type }
            $Ast.KeyValuePairs.foreach{
                if ( $Map -is [Collections.IDictionary]) { $Map.Add($_.Item1.Value, $this.ParseAst($_.Item2)) }
                else { $Map."$($_.Item1.Value)" = $this.ParseAst($_.Item2) }
            }
            if ($IsPSCustomObject) { return [PSCustomObject]$Map } else { return $Map }
        }
        elseif ($Ast -is [ConstantExpressionAst]) {
            if ($Type) { $Value = $Ast.Value -as $Type } else { $Value = $Ast.Value }
            return $Value
        }
        elseif ($Ast -is [VariableExpressionAst]) {
            $Value = switch ($Ast.VariablePath.UserPath) {
                Null    { $Null }
                True    { $True }
                False   { $False }
                Default { $Ast.Extent.Text }
            }
            return $Value
        }
        else { return $Null }
    }
}

 #   __  __   _
 #   \ \/ /__| |_ __
 #    \  // _` | '_ \
 #    /  \ (_| | | | |
 #   /_/\_\__,_|_| |_|

enum XdnType { Root; Ancestor; Index; Child; Descendant; Equals; Error = 99 }

enum XdnColorName { Reset; Regular; Literal; WildCard; Operator; Error = 99 }

class XdnColor {
    Static [String]$Regular
    Static [String]$Literal
    Static [String]$Wildcard
    Static [String]$Extended
    Static [String]$Operator
    Static [String]$Error
    Static [String]$Reset

    static XdnColor() {
        $PSReadLineOption = try { Get-PSReadLineOption -ErrorAction SilentlyContinue } catch { $Null }
        [XdnColor]::Reset    = [char]0x1b + '[39m'
        [XdnColor]::Regular  = $PSReadLineOption.VariableColor
        [XdnColor]::WildCard = $PSReadLineOption.EmphasisColor
        [XdnColor]::Extended = $PSReadLineOption.StringColor
        [XdnColor]::Operator = $PSReadLineOption.CommandColor
        [XdnColor]::Error    = $PSReadLineOption.ErrorColor
    }
}

class XdnValue {
    hidden static $Verbatim = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
    hidden [Bool]$_IsLiteral
    hidden $_IsWildcard
    hidden $_Value

    XdnValue($Value) {
        $this._IsLiteral = $False
        $this._IsWildcard = $Null
        $this._Value = $Value -replace '(?<=[^`](``)*)`(?=[\.\[\~\=\/])' # Remove any (odd number of) escapes from Xdn operators
    }

    XdnValue($Value, [Bool]$Literal) {
        $this._IsLiteral = $Literal
        $this._IsWildcard = $False
        $this._Value = $Value
    }

    [Bool] IsWildcard() {
        if ($this._IsLiteral) { $this._IsWildcard = $False }
        elseif ($Null -eq $this._IsWildcard) {
            $this._IsWildcard = $this._Value -is [String] -and $this._Value -Match '(?<=([^`]|^)(``)*)[\?\*]'
        }
        return $this._IsWildcard
    }

    [Bool] Equals($Object) {
        if ($this._IsLiteral)       { return $this._Value -eq $Object }
        elseif ($this.IsWildcard()) { return $Object -Like $this._Value }
        else                        { return $this._Value -eq $Object }
    }

    [String] ToString($Colored) {
        $Color = if ($Colored) {
            if ($this._IsLiteral)                                { [XdnColor]::Regular }
            elseif ($this._Value -NotMatch [XdnValue]::Verbatim) { [XdnColor]::Extended }
            elseif ($this.IsWildcard())                          { [XdnColor]::Wildcard }
            else                                                 { [XdnColor]::Regular }
        }
        $String =
            if ($this._IsLiteral) { "'" + "$($this._Value)".Replace("'", "''") + "'" }
            else { "$($this._Value)" -replace '(?<!([^`]|^)(``)*)[\.\[\~\=\/]', '`${0}' } # Escape any Xdn operator (that isn't yet escaped)
        $Reset = if ($Colored) { [XdnColor]::Reset }
        return $Color + $String + $Reset
    }
    [String] ToString()        { return $this.ToString($False) }
    [String] ToColoredString() { return $this.ToString($True) }

    static XdnValue() {
        Set-View { $_.ToString($True) }
    }
}

class XdnPath {
    hidden static $_PSReadLineOption
    hidden static $Verbatim = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices

    hidden $_Entries = [List[KeyValuePair[XdnType, Object]]]::new()

    hidden [Object]get_Entries() { return ,$this._Entries }

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
                    $this.Add($XdnOperator, [XdnValue]::new($StringAst[0].Value, $True))
                    $Path = $Path.SubString($StringAst[0].Extent.EndOffset)
                }
                else { # Probably a quoting error
                    $this.Add($XdnOperator, [XdnValue]::new($Path, $True))
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
                    $Value = if ($Literal) { [XdnValue]::new($Name, $True) } else { [XdnValue]$Name }
                    $this.Add($XdnOperator, $Value)
                    $Path = $Path.SubString($Match.Index)
                    $XdnOperator = $Null
                }
                else {
                    $Value = if ($Literal) { [XdnValue]::new($Path, $True) } else { [XdnValue]$Path }
                    $this.Add($XdnOperator, $Value)
                    $Path = $Null
                }
            }
        }
    }
    XdnPath ([String]$Path)                 { $this.FromString($Path, $False) }
    XdnPath ([String]$Path, [Bool]$Literal) { $this.FromString($Path, $Literal) }

    [String] ToString([String]$VariableName, [Bool]$Colored) {
        $RegularColor  = if ($Colored) { [XdnColor]::Regular }
        $OperatorColor = if ($Colored) { [XdnColor]::Operator }
        $ErrorColor    = if ($Colored) { [XdnColor]::Error }
        $ResetColor    = if ($Colored) { [char]0x1b + '[39m' }

        $Path = [System.Text.StringBuilder]::new()
        $PreviousEntry = $Null
        foreach ($Entry in $this._Entries) {
            $Value = $Entry.Value
            $Append = Switch ($Entry.Key) {
                Root        { "$OperatorColor$VariableName$ResetColor" }
                Ancestor    { "$OperatorColor$('.' * $Value)$ResetColor" }
                Index       {
                                $Dot = if (-not $PreviousEntry -or $PreviousEntry.Key -eq 'Ancestor') { "$OperatorColor." }
                                if ([int]::TryParse($Value, [Ref]$Null)) { "$Dot$RegularColor[$Value]$ResetColor" }
                                else { "$ErrorColor[$Value]$ResetColor" }
                            }
                Child       { "$RegularColor.$(@($Value).foreach{ $_.ToString($Colored) }  -Join ""$OperatorColor/"")" }
                Descendant  { "$OperatorColor~$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Equals      { "$OperatorColor=$(@($Value).foreach{ $_.ToString($Colored) } -Join ""$OperatorColor/"")" }
                Default     { "$ErrorColor$($Value)$ResetColor" }
            }
            $Path.Append($Append)
            $PreviousEntry = $Entry
        }
        return $Path.ToString()
    }
    [String] ToString()                             { return $this.ToString($Null        , $False)}
    [String] ToString([String]$VariableName)        { return $this.ToString($VariableName, $False)}
    [String] ToColoredString()                      { return $this.ToString($Null,         $True)}
    [String] ToColoredString([String]$VariableName) { return $this.ToString($VariableName, $True)}

    static XdnPath() {
        Use-ClassAccessors
        Set-View { $_.ToColoredString('<Root>') }
    }
}

enum PSNodeOrigin { Root; List; Map }

Class PSNodePath {
    hidden [PSNode[]]$Nodes
    hidden [String]$_String

    hidden PSNodePath($Nodes) { $this.Nodes = [PSNode[]]$Nodes }

    static [String] op_Addition([PSNodePath]$Path, [String]$String) {
        return "$Path" + $String
    }

    [String] ToString() {
        if ($Null -eq $this._String) {
            $Count = $this.Nodes.Count
            $this._String = if ($Count -gt 1) { $this.Nodes[-2].Path.ToString() }
            $Node = $this.Nodes[-1]
            $this._String +=
                if ($Node._NodeOrigin -eq 'List') {
                    "[$($Node._Name)]"
                }
                elseif ($Node._NodeOrigin -eq 'Map') {
                    $Dot = if ($Count -gt 2) { '.' }
                    if     ($Node.Name -is [ValueType])        { "$Dot$($Node._Name)" }
                    elseif ($Node.Name -isnot [String])        { "$Dot[$($Node._Name.GetType())]'$($Node._Name)'" }
                    elseif ($Node.Name -Match '^[_,a-z]+\w*$') { "$Dot$($Node._Name)" }
                    else                                       { "$Dot'$($Node._Name)'" }
                }
        }
        return $this._String
    }

}

#     ____  ____  _   _           _
#    |  _ \/ ___|| \ | | ___   __| | ___
#    | |_) \___ \|  \| |/ _ \ / _` |/ _ \
#    |  __/ ___) | |\  | (_) | (_| |  __/
#    |_|   |____/|_| \_|\___/ \__,_|\___|

Class PSNode {
    hidden static PSNode() { Use-ClassAccessors }

    static [int]$DefaultMaxDepth = 20
    hidden $_Name
    [Int]$Depth
    hidden $_Value
    hidden [Int]$_MaxDepth = [PSNode]::DefaultMaxDepth
    hidden [PSNodeOrigin]$_NodeOrigin
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this
    hidden [PSNodePath]$_Path
    hidden [String]$_PathName
    hidden [DateTime]$MaxDepthWarningTime            # Warn ones per item branch

    hidden [object] get_Value() {
        return ,$this._Value
    }

    hidden set_Value($Value) {
        if ($this.GetType().Name -eq [PSNode]::getPSNodeType($Value)) { # The root node is of type PSNode (always false)
            $this._Value = $Value
            $this.ParentNode.SetItem($this._Name,  $Value)
        }
        else {
            Throw "The supplied value has a different PSNode type than the existing $($this.Path). Use .ParentNode.SetItem() method and reload its child item(s)."
        }
    }

    hidden [Object] get_Name() {
        return ,$this._Name
    }

    hidden [Object] get_MaxDepth() {
        return $this.RootNode._MaxDepth
    }

    hidden set_MaxDepth($MaxDepth) {
        if (-not $this.ChildType) {
            $this._MaxDepth = $MaxDepth
        }
        else {
            Throw 'The MaxDepth can only be set at the root node: [PSNode].RootNode.MaxDepth = <Maximum Depth>'
        }
    }

    hidden [Object] get_NodeOrigin()  { return [PSNodeOrigin]$this._NodeOrigin }

    hidden [Type] get_ValueType() {
        if ($Null -eq $this._Value) { return $Null }
        else { return $this._Value.getType() }
    }

    hidden static [String]GetPSNodeType($Object) {
        if ($Null -eq $Object)                                      { return 'PSLeafNode' }
        elseif ($Object -is [Management.Automation.PSCustomObject]) { return 'PSObjectNode' }
        elseif ($Object -is [Collections.IDictionary])              { return 'PSDictionaryNode' }
        elseif ($Object -is [Specialized.StringDictionary])         { return 'PSDictionaryNode' }
        elseif ($Object -is [Collections.ICollection])              { return 'PSListNode' }
        elseif ($Object -is [ValueType])                            { return 'PSLeafNode' }
        elseif ($Object -is [String])                               { return 'PSLeafNode' }
        elseif ($Object -is [ScriptBlock])                          { return 'PSLeafNode' }
        elseif ($Object.PSObject.Properties)                        { return 'PSObjectNode' }
        else                                                        { return 'PSLeafNode' }
    }

    static [PSNode] ParseInput($Object, $MaxDepth) {
        $Node =
            if ($Object -is [PSNode]) { $Object }
            else {
                switch ([PSNode]::getPSNodeType($object)) {
                    'PSObjectNode'     { [PSObjectNode]::new($Object) }
                    'PSDictionaryNode' { [PSDictionaryNode]::new($Object) }
                    'PSListNode'       { [PSListNode]::new($Object) }
                    Default            { [PSLeafNode]::new($Object) }
                }
            }
        $Node.RootNode  = $Node
        if ($MaxDepth -gt 0) { $Node._MaxDepth = $MaxDepth }
        return $Node
    }

    static [PSNode] ParseInput($Object) { return [PSNode]::parseInput($Object, 0) }


    hidden [PSNode] Append($Object) {
        $Node = [PSNode]::ParseInput($Object)
        $Node.Depth       = $this.Depth + 1
        $Node.RootNode    = [PSNode]$this.RootNode
        $Node.ParentNode  = $this
        $Node._NodeOrigin = if ($this -is [PSListNode]) { 'List' } elseif ($this -is [PSMapNode]) { 'Map' }
        return $Node
    }

    hidden [Object] get_Path() {
        if ($Null -eq $this._Path) {
            if ($this.ParentNode) {
                $this._Path = [PSNodePath]($this.ParentNode.get_Path().Nodes + $this)
            }
            else {
                $this._Path = [PSNodePath]$this
            }
        }
        return $this._Path
    }

    hidden [String] get_PathName() {
        # Write-Warning 'The `PathName` property has been deprecated. Use the [String]$Node.Path property or the $Node.GetPathName(''$Object'') method instead.'
        return $this.get_Path().ToString()
    }

    [String] GetPathName($VariableName) {
        $PathName = $this.get_Path().ToString()
        if ($PathName -and $PathName.StartsWith('.') ) {
            return "$VariableName$PathName"
        }
        else {
            return "$VariableName.$PathName"
        }
    }

    [String] GetPathName() { return $this.get_Path().ToString() }

    hidden CollectNodes($NodeTable, [XdnPath]$Path, [Int]$PathIndex) {
        $Entry = $Path._Entries[$PathIndex]
        $NextIndex = if ($PathIndex -lt $Path._Entries.Count -1) { $PathIndex + 1 }
        $NextEntry = if ($NextIndex) { $Path._Entries[$NextIndex] }
        $Equals    = if ($NextEntry -and $NextEntry.Key -eq 'Equals') {
            $NextEntry.Value
            $NextIndex = if ($NextIndex -lt $Path._Entries.Count -1) { $NextIndex + 1 }
        }
        switch ($Entry.Key) {
            Root {
                $Node = $this.RootNode
                if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                else { $NodeTable[$Node.getPathName()] = $Node }
            }
            Ancestor {
                $Node = $this
                for($i = $Entry.Value; $i -gt 0 -and $Node.ParentNode; $i--) { $Node = $Node.ParentNode }
                if ($i -eq 0) { # else: reached root boundary
                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                    else { $NodeTable[$Node.getPathName()] = $Node }
                }
            }
            Index {
                if ($this -is [PSListNode] -and [Int]::TryParse($Entry.Value, [Ref]$Null)) {
                    $Node = $this.GetChildNode([Int]$Entry.Value)
                    if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                    else { $NodeTable[$Node.getPathName()] = $Node }
                }
            }
            Default { # Child, Descendant
                if ($this -is [PSListNode]) { # Member access enumeration
                    foreach ($Node in $this.get_ChildNodes()) {
                        $Node.CollectNodes($NodeTable, $Path, $PathIndex)
                    }
                }
                elseif ($this -is [PSMapNode]) {
                    $Found = $False
                    $ChildNodes = $this.get_ChildNodes()
                    foreach ($Node in $ChildNodes) {
                        if ($Entry.Value -eq $Node.Name -and (-not $Equals -or ($Node -is [PSLeafNode] -and $Equals -eq $Node._Value))) {
                            $Found = $True
                            if ($NextIndex) { $Node.CollectNodes($NodeTable, $Path, $NextIndex) }
                            else { $NodeTable[$Node.getPathName()] = $Node }
                        }
                    }
                    if (-not $Found -and $Entry.Key -eq 'Descendant') {
                        foreach ($Node in $ChildNodes) {
                            $Node.CollectNodes($NodeTable, $Path, $PathIndex)
                        }
                    }
                }
            }
        }
    }

    [Object] GetNode([XdnPath]$Path) {
        $NodeTable = [system.collections.generic.dictionary[String, PSNode]]::new() # Case sensitive (case insensitive map nodes use the same name)
        $this.CollectNodes($NodeTable, $Path, 0)
        if ($NodeTable.Count -eq 0) { return @() }
        if ($NodeTable.Count -eq 1) { return $NodeTable[$NodeTable.Keys] }
        else                        { return [PSNode[]]$NodeTable.Values }
    }

    [String] ToExpression() { return [PSSerialize]$this }
}

Class PSLeafNode : PSNode {

    hidden PSLeafNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    [Int]GetHashCode() {
        if ($Null -ne $this._Value) { return $this._Value.GetHashCode() } else { return '$Null'.GetHashCode() }
    }
}

Class PSCollectionNode : PSNode {
    hidden static PSCollectionNode() { Use-ClassAccessors }

    hidden [bool]MaxDepthReached() {
        # Check whether the max depth has been reached.
        # Warn if it has, but suppress the warning if
        # it took less then 5 seconds since the last
        # time it reached the max depth.
        $MaxDepthReached = $this.Depth -ge $this.RootNode._MaxDepth
        if ($MaxDepthReached) {
            if (([Datetime]::Now - $this.RootNode.MaxDepthWarningTime).TotalSeconds -gt 5) {
                Write-Warning "$($this.Path) reached the maximum depth of $($this.RootNode._MaxDepth)."
            }
            $this.RootNode.MaxDepthWarningTime = [Datetime]::Now
        }
        return $MaxDepthReached
    }

    hidden WarnSelector ([PSCollectionNode]$Node, [String]$Name) {
        if ($Node -is [PSListNode]) {
            $SelectionName  = "'$Name'"
            $CollectionType = 'list'
        }
        else {
            $SelectionName  = "[$Name]"
            $CollectionType = 'list'
        }
        Write-Warning "Expected $SelectionName to be a $CollectionType selector for: <Object>$($Node.Path)"
    }

    hidden [List[Ast]] GetAstSelectors ($Ast) {
        $List = [List[Ast]]::new()
        if ($Ast -isnot [Ast]) {
            $Ast = [Parser]::ParseInput("`$_$Ast", [ref]$Null, [ref]$Null)
            $Ast = $Ast.EndBlock.Statements.PipeLineElements.Expression
        }
        if ($Ast -is [IndexExpressionAst]) {
            $List.AddRange($this.GetAstSelectors($Ast.Target))
            $List.Add($Ast)
        }
        elseif ($Ast -is [MemberExpressionAst]) {
            $List.AddRange($this.GetAstSelectors($Ast.Expression))
            $List.Add($Ast)
        }
        elseif ($Ast.Extent.Text -ne '$_') {
            Throw "Parse error: $($Ast.Extent.Text)"
        }
        return $List
    }

    [List[PSNode]]GetChildNodes($Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        $NodeList = [List[PSNode]]::new()
        $this.CollectChildNodes($NodeList, $Levels, $NodeOrigin, $Leaf)
        return $NodeList
    }
    [List[PSNode]]GetChildNodes()                                       { return $this.GetChildNodes(0, 0, $False) }
    [List[PSNode]]GetChildNodes([Int]$Levels)                           { return $this.GetChildNodes($Levels, 0, $False) }
    [List[PSNode]]GetChildNodes([PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) { return $this.GetChildNodes(0, $NodeOrigin, $Leaf) }

    hidden [PSNode[]]get_ChildNodes()      { return $this.GetChildNodes(0,  0,      $False) }
    hidden [PSNode[]]get_ListChildNodes()  { return [PSNode[]]$this.GetChildNodes(0,  'List', $False) }
    hidden [PSNode[]]get_MapChildNodes()   { return [PSNode[]]$this.GetChildNodes(0,  'Map',  $False) }
    hidden [PSNode[]]get_DescendantNodes() { return $this.GetChildNodes(-1, 0,      $False) }
    hidden [PSNode[]]get_LeafNodes()       { return $this.GetChildNodes(-1, 0,      $True) }
    hidden [PSNode]_($Name)                { return $this.GetChildNode($Name) }       # CLI Shorthand ("alias") for GetChildNode (don't use in scripts)
    # hidden [Object]Get($Path)                { return $this.GetDescendantNode($Path) }  # CLI Shorthand ("alias") for GetDescendantNode (don't use in scripts)
}

Class PSListNode : PSCollectionNode {
    hidden static PSListNode() { Use-ClassAccessors }

    hidden PSListNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }
    hidden [Object]get_Count() {
        return $this._Value.get_Count()
    }

    hidden [Object]get_Names() {
        if ($this._Value.Length) { return ,@(0..($this._Value.Length - 1)) }
        return ,@()
    }

    hidden [Object]get_Values() {
        return ,@($this._Value)
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

    hidden CollectChildNodes($NodeList, [Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        if (-not $this.MaxDepthReached()) {
            for ($Index = 0; $Index -lt $this._Value.get_Count(); $Index++) {
                $Node = $this.Append($this._Value[$Index])
                $Node._Name = $Index
                if ($NodeOrigin -in 0, 'List' -and (-not $Leaf -or $Node -is [PSLeafNode])) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'Map')) { # $NodeOrigin -eq 'Map' --> Member Access Enumeration
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $Node.CollectChildNodes($NodeList, $Levels_1, $NodeOrigin, $Leaf)
                }
            }
        }
    }

    [Object]GetChildNode([Int]$Index) {
        if ($this.MaxDepthReached()) { return $Null }
        $Count = $this._Value.get_Count()
        if ($Index -lt -$Count -or $Index -ge $Count) {
            throw "The <Object>$($this.Path) doesn't contain a child index: $Index"
        }
        $Node = $this.Append($this._Value[$Index])
        $Node._Name = $Index
        return $Node
    }

    [Int]GetHashCode() {
        $HashCode = '@()'.GetHashCode()
        foreach ($Node in $this.GetChildNodes(-1)) {
            $HashCode = $HashCode -bxor $Node.GetHashCode()
        }
        # Shift the bits to make the level unique
        $HashCode = if ($HashCode -band 1) { $HashCode -shr 1 } else { $HashCode -shr 1 -bor 1073741824 }
        return $HashCode -bxor 0xa5a5a5a5
    }
}

Class PSMapNode : PSCollectionNode {
    hidden static PSMapNode() { Use-ClassAccessors }

    [Int]GetHashCode() {
        $HashCode = '@{}'.GetHashCode()
        foreach ($Node in $this.GetChildNodes(-1)) {
            $HashCode = $HashCode -bxor "$($Node._Name)=$($Node.GetHashCode())".GetHashCode()
        }
        return $HashCode
    }
}

Class PSDictionaryNode : PSMapNode {
    hidden static PSDictionaryNode() { Use-ClassAccessors }

    hidden PSDictionaryNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    hidden [Object]get_Count() {
        return $this._Value.get_Count()
    }

    hidden [Object]get_Names() {
        return ,$this._Value.get_Keys()
    }

    hidden [Object]get_Values() {
        return ,$this._Value.get_Values()
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

    hidden CollectChildNodes($NodeList, [Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        if (-not $this.MaxDepthReached()) {
            foreach($Key in $this._Value.get_Keys()) {
                $Node = $this.Append($this._Value[$Key])
                $Node._Name = $Key
                if ($NodeOrigin -in 0, 'Map' -and (-not $Leaf -or $Node -is [PSLeafNode])) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'List')) {
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $Node.CollectChildNodes($NodeList, $Levels_1, $NodeOrigin, $Leaf)
                }
            }
        }
    }

    [Object]GetChildNode($Key) {
        if ($this.MaxDepthReached()) { return $Null }
        if (-not $this._Value.Contains($Key)) {
            Throw "The <Object>$($this.Path) doesn't contain a child named: $Key"
        }
        $Node = $this.Append($this._Value[$Key])
        $Node._Name = $Key
        return $Node
    }
}

Class PSObjectNode : PSMapNode {
    hidden static PSObjectNode() { Use-ClassAccessors }

    hidden PSObjectNode($Object) {
        if ($Object -is [PSNode]) { $this._Value = $Object._Value } else { $this._Value = $Object }
    }

    hidden [Object]get_Count() {
        return @($this._Value.PSObject.Properties).get_Count()
    }

    hidden [Object]get_Names() {
        return ,$this._Value.PSObject.Properties.Name
    }

    hidden [Object]get_Values() {
        return ,$this._Value.PSObject.Properties.Value
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

    hidden CollectChildNodes($NodeList, [Int]$Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        if (-not $this.MaxDepthReached()) {
            foreach($Property in $this._Value.PSObject.Properties) {
                if ($Property.Value -is [Reflection.MemberInfo]) { continue }
                $Node = $this.Append($Property.Value)
                $Node._Name = $Property.Name
                if ($NodeOrigin -in 0, 'Map' -and (-not $Leaf -or $Node -is [PSLeafNode])) { $NodeList.Add($Node) }
                if ($Node -is [PSCollectionNode] -and ($Levels -ne 0 -or $NodeOrigin -eq 'List')) {
                    $Levels_1 = if ($Levels -gt 0) { $Levels - 1 } else { $Levels }
                    $Node.CollectChildNodes($NodeList, $Levels_1, $NodeOrigin, $Leaf)
                }
            }
        }
    }

    [Object]GetChildNode([String]$Name) {
        if ($this.MaxDepthReached()) { return $Null }
        if ($Name -NotIn $this._Value.PSObject.Properties.Name) {
            Throw "The <Object>$($this.Path) doesn't contain a child named: $Name"
        }
        $Node = $this.Append($this._Value.PSObject.Properties[$Name].Value)
        $Node._Name = $Name
        return $Node
    }
}

Update-TypeData -TypeName PSNode -DefaultDisplayPropertySet Path, Name, Depth, Value -Force


