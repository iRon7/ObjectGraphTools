using module .\..\..\..\ObjectGraphTools

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic

Class PSSerialize {
    # hidden static [Dictionary[String,Bool]]$IsConstrainedType = [Dictionary[String,Bool]]::new()
    hidden static [Dictionary[String,Bool]]$HasStringConstructor = [Dictionary[String,Bool]]::new()

    hidden static [String]$AnySingleQuote = "'|$([char]0x2018)|$([char]0x2019)"

    # NoLanguage mode only
    hidden static [int]$MaxLeafLength       = 48
    hidden static [int]$MaxKeyLength        = 12
    hidden static [int]$MaxValueLength      = 16
    hidden static [int[]]$NoLanguageIndices = 0, 1, -1
    hidden static [int[]]$NoLanguageItems   = 0, 1, -1

    hidden $_Object

    hidden [PSLanguageMode]$LanguageMode = 'Restricted' # "NoLanguage" will stringify the object for displaying (Use: PSStringify)
    hidden [Int]$ExpandDepth = [Int]::MaxValue
    hidden [Bool]$Explicit
    hidden [Bool]$FullTypeName
    hidden [bool]$HighFidelity
    hidden [String]$Indent = '    '
    hidden [Bool]$ExpandSingleton

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
        'System.RuntimeType'                                                  = ''
        'System.Uri'                                                          = 'OriginalString'
        'System.Version'                                                      = ''
        'System.Void'                                                         = $Null
    }
    hidden $StringBuilder
    hidden [Int]$Offset = 0
    hidden [Int]$LineNumber = 1

    PSSerialize($Object) { $this._Object = $Object }
    PSSerialize($Object, $LanguageMode) {
        $this._Object = $Object
        $this.LanguageMode = $LanguageMode
    }
    PSSerialize($Object, $LanguageMode, $ExpandDepth) {
        $this._Object = $Object
        $this.LanguageMode = $LanguageMode
        $this.ExpandDepth = $ExpandDepth
    }
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
        $this._Object         = $Object
        $this.LanguageMode    = $LanguageMode
        $this.ExpandDepth     = $ExpandDepth
        $this.Explicit        = $Explicit
        $this.FullTypeName    = $FullTypeName
        $this.HighFidelity    = $HighFidelity
        $this.ExpandSingleton = $ExpandSingleton
        $this.Indent          = $Indent
    }

    hidden static [String[]]$Parameters = 'LanguageMode', 'Explicit', 'FullTypeName', 'HighFidelity', 'Indent', 'ExpandSingleton'
    PSSerialize($Object, [HashTable]$Parameters) {
        $this._Object = $Object
        foreach ($Name in $Parameters.get_Keys()) { # https://github.com/PowerShell/PowerShell/issues/13307
            if ($Name -notin [PSSerialize]::Parameters) { Throw "Unknown parameter: $Name." }
            $this.GetType().GetProperty($Name).SetValue($this, $Parameters[$Name])
        }
    }

    [String]Serialize($Object) {
        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
        if (-not ('ConstrainedLanguage', 'FullLanguage' -eq $this.LanguageMode)) {
            if ($this.FullTypeName) { Write-Warning 'The FullTypeName switch requires Constrained - or FullLanguage mode.' }
            if ($this.Explicit)     { Write-Warning 'The Explicit switch requires Constrained - or FullLanguage mode.' }
        }
        if ($Object -is [PSNode]) { $Node = $Object } else { $Node = [PSNode]::ParseInput($Object) }
        $this.StringBuilder = [System.Text.StringBuilder]::new()
        $this.Stringify($Node)
        return $this.StringBuilder.ToString()
    }

    hidden Stringify([PSNode]$Node) {
        $Value = $Node.Value
        $IsSubNode = $this.StringBuilder.Length -ne 0
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
                        [PSLanguageType]::IsConstrained($Type) -and (
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
                    elseif ($TypeName  -eq 'System.Object[]') { "[Array]" }
                    elseif ($TypeName  -eq 'System.Management.Automation.PSCustomObject') { "[PSCustomObject]" }
                    elseif ($Type.Name -eq 'RuntimeType') { "[Type]" }
                    else { "[$TypeName]" }
                }
        if ($TypeInitializer) { $this.StringBuilder.Append($TypeInitializer) }

        if ($Node -is [PSLeafNode] -or (-not $this.HighFidelity -and [PSSerialize]::RoundTripProperty.Contains($Node.ValueType.FullName))) {
            $MaxLength = if ($IsSubNode) { [PSSerialize]::MaxValueLength } else { [PSSerialize]::MaxLeafLength }
            $Expression =
                if ([PSSerialize]::RoundTripProperty.Contains($Node.ValueType.FullName)) {
                    $Property = [PSSerialize]::RoundTripProperty[$Node.ValueType.FullName]
                        if ($Null -eq $Property)          { $Null }
                    elseif ($Property -is [String])       { if ($Property) { ,$Value.$Property } else { "$Value" } }
                    elseif ($Property -is [ScriptBlock] ) { Invoke-Command $Property -InputObject $Value }
                    elseif ($Property -is [HashTable])    { if ($this.LanguageMode -eq 'Restricted') { $Null } else { @{} } }
                    elseif ($Property -is [Array])        { @($Property.foreach{ $Value.$_ }) }
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
            elseif ($Expression -is [ScriptBlock]) { $Expression = [Abbreviate]::new('{', $Expression, $MaxLength, '}') }
            elseif ($Expression -is [HashTable])   { $Expression = '@{}' }
            elseif ($Expression -is [Array]) {
                if ($this.LanguageMode -eq 'NoLanguage') { $Expression = [Abbreviate]::new('[', $Expression[0], $MaxLength, ']') }
                else {
                    $Space = if ($this.ExpandDepth -ge 0) { ' ' }
                    $New = if ($TypeInitializer) { '::new(' } else { '@(' }
                    $Expression = $New + ($Expression.foreach{
                        if ($Null -eq $_)  { '$Null' }
                        elseif ($_.GetType().IsPrimitive) { "$_" }
                        elseif ($_ -is [Array]) { $_ -Join $Space }
                        else { "'$_'" }
                    } -Join ",$Space") + ')'
                }
            }
            elseif ($Type -and $Type.IsPrimitive) {
                if ($this.LanguageMode -eq 'NoLanguage') { $Expression = [CommandColor]([String]$Expression[0]) }
            }
            else {
                if ($Expression -isnot [String]) { $Expression = "$Expression" }
                if ($this.LanguageMode -eq 'NoLanguage') { $Expression = [StringColor]([Abbreviate]::new("'", $Expression, $MaxLength, "'")) }
                else {
                    if ($Expression.Contains("`n")) {
                        $Expression = "@'" + [Environment]::NewLine + "$Expression".Replace("'", "''") + [Environment]::NewLine + "'@"
                    }
                    else { $Expression = "'$($Expression -Replace [PSSerialize]::AnySingleQuote, '$0$0')'" }
                }
            }

            $this.StringBuilder.Append($Expression)
        }
        elseif ($Node -is [PSListNode]) {
            $ChildNodes = $Node.get_ChildNodes()
            $this.StringBuilder.Append('@(')
            if ($this.LanguageMode -eq 'NoLanguage') {
                if ($ChildNodes.Count -eq 0) { }
                elseif ($IsSubNode) { $this.StringBuilder.Append([Abbreviate]::Ellipses) }
                else {
                    $Indices = [PSSerialize]::NoLanguageIndices
                    if (-not $Indices -or $ChildNodes.Count -lt $Indices.Count) { $Indices = 0..($ChildNodes.Count - 1) }
                    $LastIndex = $Null
                    foreach ($Index in $Indices) {
                        if ($Null -ne $LastIndex) { $this.StringBuilder.Append(',') }
                        if ($Index -lt 0) { $Index = $ChildNodes.Count + $Index }
                        if ($Index -gt $LastIndex + 1) { $this.StringBuilder.Append("$([Abbreviate]::Ellipses),") }
                        $this.StringBuilder.Append($this.Stringify($ChildNodes[$Index]))
                        $LastIndex = $Index
                    }
                }
            }
            else {
                $this.Offset++
                $StartLine = $this.LineNumber
                $ExpandSingle = $this.ExpandSingleton -or $ChildNodes.Count -gt 1 -or ($ChildNodes.Count -eq 1 -and $ChildNodes[0] -isnot [PSLeafNode])
                foreach ($ChildNode in $ChildNodes) {
                    if ($ChildNode.Name -gt 0) {
                        $this.StringBuilder.Append(',')
                        $this.NewWord()
                    }
                    elseif ($ExpandSingle) { $this.NewWord('') }
                    $this.Stringify($ChildNode)
                }
                $this.Offset--
                if ($this.LineNumber -gt $StartLine) { $this.NewWord('') }
            }
            $this.StringBuilder.Append(')')
        }
        else { # if ($Node -is [PSMapNode]) {
            $ChildNodes = $Node.get_ChildNodes()
            if ($ChildNodes) {
                $this.StringBuilder.Append('@{')
                if ($this.LanguageMode -eq 'NoLanguage') {
                    if ($ChildNodes.Count -gt 0) {
                        $Indices = [PSSerialize]::NoLanguageItems
                        if (-not $Indices -or $ChildNodes.Count -lt $Indices.Count) { $Indices = 0..($ChildNodes.Count - 1) }
                        $LastIndex = $Null
                        foreach ($Index in $Indices) {
                            if ($IsSubNode -and $Index) { $this.StringBuilder.Append(";$([Abbreviate]::Ellipses)"); break }
                            if ($Null -ne $LastIndex) { $this.StringBuilder.Append(';') }
                            if ($Index -lt 0) { $Index = $ChildNodes.Count + $Index }
                            if ($Index -gt $LastIndex + 1) { $this.StringBuilder.Append("$([Abbreviate]::Ellipses);") }
                            $this.StringBuilder.Append([VariableColor](
                                [PSKeyExpression]::new($ChildNodes[$Index].Name, [PSSerialize]::MaxKeyLength)))
                            $this.StringBuilder.Append('=')
                            $this.StringBuilder.Append($this.Stringify($ChildNodes[$Index]))
                            $LastIndex = $Index
                        }
                    }
                }
                else {
                    $this.Offset++
                    $StartLine = $this.LineNumber
                    $Index = 0
                    $ExpandSingle = $this.ExpandSingleton -or $ChildNodes.Count -gt 1 -or $ChildNodes[0] -isnot [PSLeafNode]
                    $ChildNodes.foreach{
                        if ($Index++) {
                            $Separator = if ($this.ExpandDepth -ge 0) { '; ' } else { ';' }
                            $this.NewWord($Separator)
                        }
                        elseif ($this.ExpandDepth -ge 0) {
                            if ($ExpandSingle) { $this.NewWord() } else { $this.StringBuilder.Append(' ') }
                        }
                        $this.StringBuilder.Append([PSKeyExpression]::new($_.Name, $this.LanguageMode, ($this.ExpandDepth -lt 0)))
                        if ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' = ') } else { $this.StringBuilder.Append('=') }
                        $this.Stringify($_)
                    }
                    $this.Offset--
                    if ($this.LineNumber -gt $StartLine) { $this.NewWord() }
                    elseif ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' ') }
                }
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

    [String] ToString() {
        if ($this._Object -is [PSNode]) { $Node = $this._Object }
        else { $Node = [PSNode]::ParseInput($this._Object) }
        $this.StringBuilder = [System.Text.StringBuilder]::new()
        $this.Stringify($Node)
        return $this.StringBuilder.ToString()
    }
}
