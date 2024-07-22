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

function Use-ClassAccessors {
<#
.SYNOPSIS
    Implements class getter and setter accessors.

.DESCRIPTION
    The [Use-ClassAccessors][1] cmdlet updates script property of a class from the getter and setter methods.
    Which are also known as [accessors or mutator methods][2].

    The getter and setter methods should use the following syntax:

    ### getter syntax

        [<type>] get_<property name>() {
            return <variable>
        }

    or:

        [Object] get_<property name>() {
            return ,[<Type>]<variable>
        }
    ### setter syntax

        set_<property name>(<variable>) {
            <code>
        }

    > [!NOTE]
    > A **setter** accessor requires a **getter** accessor to implement the related property.

    > [!NOTE]
    > In most cases, you might want to hide the getter and setter methods using the [`hidden` keyword][3]
    > on the getter and setter methods.

.EXAMPLE
    # Using class accessors

    The following example defines a getter and setter for a `value` property
    and a _readonly_ property for the type of the type of the contained value.

        Install-Script -Name Use-ClassAccessors

        Class ExampleClass {
            hidden $_Value
            hidden [Object] get_Value() {
                return $this._Value
            }
            hidden set_Value($Value) {
                $this._Value = $Value
            }
            hidden [Type]get_Type() {
                if ($Null -eq $this.Value) { return $Null }
                else { return $this._Value.GetType() }
            }
            hidden static ExampleClass() { Use-ClassAccessors }
        }

        $Example = [ExampleClass]::new()

        $Example.Value = 42         # Set value to 42
        $Example.Value              # Returns 42
        $Example.Type               # Returns [Int] type info
        $Example.Type = 'Something' # Throws readonly error

.PARAMETER Class

    Specifies the class from which the accessor need to be initialized.
    Default: The class from which this function is invoked (by its static initializer).

.PARAMETER Property

    Filters the property that requires to be (re)initialized.
    Default: All properties in the given class

.PARAMETER Force

    Indicates that the cmdlet reloads the specified accessors,
    even if the accessors already have been defined for the concerned class.

.LINK
    [1]: https://github.com/iRon7/Use-ClassAccessors "Online Help"
    [2]: https://en.wikipedia.org/wiki/Mutator_method "Mutator method"
    [3]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#hidden-keyword "Hidden keyword in classes"
#>
    param(
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Class,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Property,

        [switch]$Force
    )

    process {
        $ClassNames =
            if ($Class) { $Class }
            else {
                $Caller = (Get-PSCallStack)[1]
                if ($Caller.FunctionName -ne '<ScriptBlock>') {
                    $Caller.FunctionName
                }
                elseif ($Caller.ScriptName) {
                    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($Caller.ScriptName, [ref]$Null, [ref]$Null)
                    $Ast.EndBlock.Statements.where{ $_.IsClass }.Name
                }
            }
        foreach ($ClassName in $ClassNames) {
            $TargetType = $ClassName -as [Type]
            if (-not $TargetType) { Write-Warning "Class not found: $ClassName" }
            $TypeData = Get-TypeData -TypeName $ClassName
            $Members = if ($TypeData -and $TypeData.Members) { $TypeData.Members.get_Keys() } else { @() }
            $Methods =
                if ($Property) {
                    $TargetType.GetMethod("get_$Property")
                    $TargetType.GetMethod("set_$Property")
                }
                else {
                    $targetType.GetMethods().where{ ($_.Name -Like 'get_*' -or  $_.Name -Like 'set_*') -and $_.Name -NotLike '???__*' }
                }
            $Accessors = @{}
            foreach ($Method in $Methods) {
                $Member = $Method.Name.SubString(4)
                if (-not $Force -and $Member -in $Members) { continue }
                $Parameters = $Method.GetParameters()
                if ($Method.Name -Like 'get_*') {
                    if ($Parameters.Count -eq 0) {
                        if ($Method.ReturnType.IsArray) {
                            $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Invoke = `$Method.Invoke(`$this, `$Null)
`$Output = `$Invoke -as '$($Method.ReturnType.FullName)'
if (@(`$Invoke).Count -gt 1) { `$Output } else { ,`$Output }
"@
                        }
                        else {
                            $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Method.Invoke(`$this, `$Null) -as '$($Method.ReturnType.FullName)'
"@
                        }
                        if (-not $Accessors.Contains($Member)) { $Accessors[$Member] = @{} }
                        $Accessors[$Member].Value = [ScriptBlock]::Create($Expression)
                    }
                    else { Write-Warning "The getter '$($Method.Name)' is skipped as it is not parameter-less." }
                }
                elseif ($Method.Name -Like 'set_*') {
                    if ($Parameters.Count -eq 1) {
                        $Expression = @"
`$TargetType = '$ClassName' -as [Type]
`$Method = `$TargetType.GetMethod('$($Method.Name)')
`$Method.Invoke(`$this, `$Args)
"@
                        if (-not $Accessors.Contains($Member)) { $Accessors[$Member] = @{} }
                        $Accessors[$Member].SecondValue = [ScriptBlock]::Create($Expression)
                    }
                    else { Write-Warning "The setter '$($Method.Name)' is skipped as it does not have a single parameter" }
                }
            }
            foreach ($MemberName in $Accessors.get_Keys()) {
                $TypeData = $Accessors[$MemberName]
                if ($TypeData.Contains('Value')) {
                    $TypeData.TypeName   = $ClassName
                    $TypeData.MemberType = 'ScriptProperty'
                    $TypeData.MemberName = $MemberName
                    $TypeData.Force      = $Force
                    Update-TypeData @TypeData
                }
                else { Write-Warning "'[$ClassName].set_$MemberName()' accessor requires a '[$ClassName].get_$MemberName()' accessor." }
            }
        }
    }
}

function Set-View {
<#
.SYNOPSIS
    Sets the default view output

.LINK
    https://stackoverflow.com/questions/77752014/how-to-type-convert-a-derived-class

#>
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Class,

        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]$ScriptBlock
    )

    process {
        $ClassNames =
            if ($Class) { $Class }
            else {
                $Caller = (Get-PSCallStack)[1]
                if ($Caller.FunctionName -ne '<ScriptBlock>') {
                    $Caller.FunctionName
                }
                elseif ($Caller.ScriptName) {
                    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($Caller.ScriptName, [ref]$Null, [ref]$Null)
                    $Ast.EndBlock.Statements.where{ $_.IsClass }.Name
                }
            }

        foreach ($ClassName in $ClassNames) {
            $FormatData = @"
                <Configuration>
                <ViewDefinitions>
                    <View>
                    <Name>$ClassName</Name>
                    <OutOfBand />
                    <ViewSelectedBy>
                        <TypeName>$ClassName</TypeName>
                    </ViewSelectedBy>
                        <CustomControl>
                        <CustomEntries>
                            <CustomEntry>
                            <CustomItem>
                                <ExpressionBinding>
                                <ScriptBlock>
                                    <![CDATA[$($ScriptBlock.ToString())]]>
                                </ScriptBlock>
                                </ExpressionBinding>
                            </CustomItem>
                            </CustomEntry>
                        </CustomEntries>
                        </CustomControl>
                    </View>
                    </ViewDefinitions>
                </Configuration>
"@
            $TempFile = [IO.Path]::GetTempPath() + "$ClassName.ps1xml"
            Out-File -InputObject $FormatData -LiteralPath $TempFile -Encoding ASCII
            Update-FormatData -PrependPath $TempFile
        }
    }
}

Class PSLanguageType {
    hidden static $_TypeCache = [Dictionary[String,Bool]]::new()
    hidden Static PSLanguageType() {
        [PSLanguageType]::_TypeCache['System.Management.Automation.PSCustomObject'] = $True # https://github.com/PowerShell/PowerShell/issues/20767
    }
    [Bool]IsRestricted($TypeName) {
        if ($Null -eq $TypeName) { return $True } # Warning: a $Null is considered a restricted "type"!
        $Type = $TypeName -as [Type]
        if ($Null -eq $Type) { Throw 'Unknown type name: $TypeName' }
        $TypeName = $Type.FullName
        return $TypeName -in 'bool', 'array', 'hashtable'
    }
    [Bool]IsConstrained($TypeName) { # https://stackoverflow.com/a/64806919/1701026
        if ($Null -eq $TypeName) { return $True } # Warning: a $Null is considered a constrained "type"!
        $Type = $TypeName -as [Type]
        if ($Null -eq $Type) { Throw 'Unknown type name: $TypeName' }
        $TypeName = $Type.FullName
        if (-not [PSLanguageType]::_TypeCache.ContainsKey($TypeName)) {
            [PSLanguageType]::_TypeCache[$TypeName] = try {
                $ConstrainedSession = [PowerShell]::Create()
                $ConstrainedSession.RunSpace.SessionStateProxy.LanguageMode = 'Constrained'
                $ConstrainedSession.AddScript("[$TypeName]0").Invoke().Count -ne 0 -or
                $ConstrainedSession.Streams.Error[0].FullyQualifiedErrorId -ne 'ConversionSupportedOnlyToCoreTypes'
            } catch { $False }
        }
        return [PSLanguageType]::_TypeCache[$TypeName]
    }
}

New-Variable -Scope Global -Name PSLanguageType -Value ([PSLanguageType]::new()) -Force

Class PSInstance {
    static [Object]Create($Object) {
        if ($Null -eq $Object) { return $Null }
        elseif ($Object -is [String]) {
            $String = if ($Object.StartsWith('[') -and $Object.EndsWith(']')) { $Object.SubString(1, ($Object.Length - 2)) } else { $Object }
            Switch -Regex ($String) {
                '^((System\.)?String)?$'                                         { return '' }
                '^(System\.)?Array$'                                             { return ,@() }
                '^(System\.)?Object\[\]$'                                        { return ,@() }
                '^((System\.)?Collections\.Hashtable\.)?hashtable$'              { return @{} }
                '^((System\.)?Management\.Automation\.)?ScriptBlock$'            { return {} }
                '^((System\.)?Collections\.Specialized\.)?Ordered(Dictionary)?$' { return [Ordered]@{} }
                '^((System\.)?Management\.Automation\.)?PS(Custom)?Object$'      { return [PSCustomObject]@{} }
            }
            $Type = $String -as [Type]
            if (-not $Type) { Throw "Unknown type: [$Object]" }
        }
        elseif ($Object -is [Type]) {
            $Type = $Object.UnderlyingSystemType
            if     ("$Type" -eq 'string')      { Return '' }
            elseif ("$Type" -eq 'array')       { Return ,@() }
            elseif ("$Type" -eq 'scriptblock') { Return {} }
        }
        else {
            if     ($Object -is [Object[]])       { Return ,@() }
            elseif ($Object -is [ScriptBlock])    { Return {} }
            elseif ($Object -is [PSCustomObject]) { Return [PSCustomObject]::new() }
            $Type = $Object.GetType()
        }
        try { return [Activator]::CreateInstance($Type) } catch { throw $_ }
    }

}

#  ____  ____ ____            _       _ _
# |  _ \/ ___/ ___|  ___ _ __(_) __ _| (_)_______
# | |_) \___ \___ \ / _ \ '__| |/ _` | | |_  / _ \
# |  __/ ___) |__) |  __/ |  | | (_| | | |/ /  __/
# |_|   |____/____/ \___|_|  |_|\__,_|_|_/___\___|

Class PSKeyExpression {
    hidden static [Regex]$UnquoteMatch = '^[\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}_][\?\*\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$' # https://stackoverflow.com/questions/62754771/unquoted-key-rules-and-best-practices
    hidden $Key
    hidden [PSLanguageMode]$LanguageMode = 'Restricted'
    hidden [Bool]$Compress
    hidden [Int]$MaximumLength

    PSKeyExpression($Key)                                                 { $this.Key = $Key }
    PSKeyExpression($Key, [PSLanguageMode]$LanguageMode)                  { $this.Key = $Key; $this.LanguageMode = $LanguageMode }
    PSKeyExpression($Key, [PSLanguageMode]$LanguageMode, [Bool]$Compress) { $this.Key = $Key; $this.LanguageMode = $LanguageMode; $this.Compress = $Compress }
    PSKeyExpression($Key, [int]$MaximumLength)                            { $this.Key = $Key; $this.MaximumLength = $MaximumLength }

    [String]ToString() {
        $Name = $this.Key
        if ($Name -is [byte]  -or $Name -is [int16]  -or $Name -is [int32]  -or $Name -is [int64]  -or
            $Name -is [sbyte] -or $Name -is [uint16] -or $Name -is [uint32] -or $Name -is [uint64] -or
            $Name -is [float] -or $Name -is [double] -or $Name -is [decimal]) {
            if ($this.MaximumLength -and $Name.Length -gt $this.MaximumLength) {
                return "$Name".SubString(0, ($this.MaximumLength - 3)) + '...'
            }
            return $Name
        }
        if ($this.MaximumLength) { $Name = "$Name" }
        if ($Name -is [String]) {
            if ($Name -cMatch [PSKeyExpression]::UnquoteMatch) {
                if ($this.MaximumLength -and $Name.Length -gt $this.MaximumLength) {
                    return $Name.SubString(0, ($this.MaximumLength - 3)) + '...'
                }
                return $Name
            }
            $Name = $Name.Replace("'", "''")
            if ($this.MaximumLength -and $this.MaximumLength -and $Name.Length -gt $this.MaximumLength - 2) {
                $Name = $Name.SubString(0, ($this.MaximumLength - 5)) + '...'
            }
            return "'$Name'"
        }
        else {
            $Node = [PSNode]::ParseInput($Name, 2) # There is no way (yet) to expand keys more than 2 levels
            return  [PSSerialize]::new($Node, $this.LanguageMode, -$this.Compress)
        }

    }
}

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
    PSSerialize($Object, $LanguageMode, $ExpandDepth) {
        $this.LanguageMode = $LanguageMode
        $this.ExpandDepth = $ExpandDepth
        $this.Serialize($Object)
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
        if ($Object -is [PSNode]) { $Node = $Object } else { $Node = [PSNode]::ParseInput($Object) }
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
                        $Global:PSLanguageType.IsConstrained($Type) -and (
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
            elseif ($Expression -is [ScriptBlock]) { $Expression = $Expression.Ast.Extent.Text }
            elseif ($Expression -is [HashTable])   { $Expression = '@{}' }
            elseif ($Expression -is [Array]) {
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
                    elseif ($this.ExpandDepth -ge 0) {
                        if ($ExpandSingle) { $this.NewWord() } else { $this.StringBuilder.Append(' ') }
                    }
                    $Key = [PSKeyExpression]::new($_.Name, $this.LanguageMode, ($this.ExpandDepth -lt 0))
                    $this.StringBuilder.Append($Key)
                    if ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' = ') } else { $this.StringBuilder.Append('=') }
                    $this.Iterate($_)
                }
                $this.Offset--
                if ($this.LineNumber -gt $StartLine) { $this.NewWord() }
                elseif ($this.ExpandDepth -ge 0) { $this.StringBuilder.Append(' ') }
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
        return $this.StringBuilder.ToString()
    }
 }

 Class PSStringify : PSSerialize {
    hidden static [int]$MaximumListCount    = 3
    hidden static [int]$MaximumMapCount     = 3
    hidden static [int]$MaximumStringLength = 48
    hidden static [int]$MaximumKeyLength    = 12
    hidden static [int]$MaximumValueLength  = 16

    PSStringify($Object) { $this.Serialize($Object) }
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
    PSDeserialize(
        $Expression,
        $LanguageMode  = 'Restricted',
        $ArrayType     = $Null,
        $HashTableType = $Null
    ) {
        if ($this.LanguageMode -eq 'NoLanguage') { Throw 'The language mode "NoLanguage" is not supported.' }
        $this.Expression    = $Expression
        $this.LanguageMode  = $LanguageMode
        if ($Null -ne $ArrayType)     { $this.ArrayType     = $ArrayType }
        if ($Null -ne $HashTableType) { $this.HashTableType = $HashTableType }
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
                    $Global:PSLanguageType.IsConstrained($FullTypeName)
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
            $Elements = $Ast.PipelineElements
            if (-not $Elements.Count)  { return @() }
            elseif ($Elements -is [CommandAst]) {
                return $Null #85 ConvertFrom-Expression: convert function/cmdlet calls to Objects
            }
            elseif ($Elements.Expression.Count -eq 1) { return $this.ParseAst($Elements.Expression[0]) }
            else { return $Elements.Expression.Foreach{ $this.ParseAst($_) } }
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
                Null        { $Null }
                True        { $True }
                False       { $False }
                PSCulture   { (Get-Culture).ToString() }
                PSUICulture { (Get-UICulture).ToString() }
                Default     { $Ast.Extent.Text }
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
            if ($this._Literal)               { [XdnColor]::Regular }
            elseif (-not $this.IsVerbatim())  { [XdnColor]::Extended }
            elseif ($this.ContainsWildcard()) { [XdnColor]::Wildcard }
            else                              { [XdnColor]::Regular }
        }
        $String =
            if ($this._Literal) { "'" + "$($this._Value)".Replace("'", "''") + "'" }
            else { "$($this._Value)" -replace '(?<!([^`]|^)(``)*)[\.\[\~\=\/]', '`${0}' } # Escape any Xdn operator (that isn't yet escaped)
        $Reset = if ($Colored) { [XdnColor]::Reset }
        return $Color + $String + $Reset
    }
    [String] ToString()        { return $this.ToString($False) }
    [String] ToColoredString() { return $this.ToString($True) }

    static XdnName() {
        Set-View { $_.ToString($True) }
    }
}
class XdnPath {
    hidden static $_PSReadLineOption

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

enum PSNodeStructure { Leaf; List; Map }
enum PSNodeOrigin { Root; List; Map }

Class PSNodePath {
    hidden [PSNode[]]$Nodes
    hidden [String]$_String

    hidden PSNodePath($Nodes) { $this.Nodes = [PSNode[]]$Nodes }

    static [String] op_Addition([PSNodePath]$Path, [String]$String) {
        return "$Path" + $String
    }

    [Bool] Equals([Object]$Path) {
        if ($Path -is [PSNodePath]) {
            if ($this.Nodes.Count -ne $Path.Nodes.Count) { return $false }
            $Index = 0
            foreach( $Node in $this.Nodes) {
                if ($Node.NodeOrigin -ne $Path.Nodes[$Index].NodeOrigin -or
                    $Node.Name       -ne $Path.Nodes[$Index].Name
                ) { return $false }
                $Index++
            }
            return $true
        }
        elseif ($Path -is [String]) {
            return $this.ToString() -eq $Path
        }
        return $false
    }

    [String] ToString() {
        if ($Null -eq $this._String) {
            $Count = $this.Nodes.Count
            $this._String = if ($Count -gt 1) { $this.Nodes[-2].Path.ToString() }
            $Node = $this.Nodes[-1]
            $this._String += # Copy the new path into the current node
                if ($Node.NodeOrigin -eq 'List') {
                    "[$($Node._Name)]"
                }
                elseif ($Node.NodeOrigin -eq 'Map') {
                    $KeyExpression = [PSKeyExpression]$Node._Name
                    if ($Count -le 2) { $KeyExpression } else { ".$KeyExpression" }
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

Class PSNode : IComparable {
    hidden static PSNode() { Use-ClassAccessors }

    static [int]$DefaultMaxDepth = 20

    hidden $_Name
    [Int]$Depth
    hidden $_Value
    hidden [Int]$_MaxDepth = [PSNode]::DefaultMaxDepth
    [PSNode]$ParentNode
    [PSNode]$RootNode = $this
    # hidden [PSNodePath]$_Path
    # hidden [String]$_PathName
    hidden [Dictionary[String,Object]]$Cache = [Dictionary[String,Object]]::new()
    hidden [DateTime]$MaxDepthWarningTime            # Warn ones per item branch

    static [PSNode] ParseInput($Object, $MaxDepth) {
        $Node =
            if ($Object -is [PSNode]) { $Object }
            else {
                if     ($Null -eq $Object)                                  { [PSLeafNode]::new($Object) }
                elseif ($Object -is [Management.Automation.PSCustomObject]) { [PSObjectNode]::new($Object) }
                elseif ($Object -is [Collections.IDictionary])              { [PSDictionaryNode]::new($Object) }
                elseif ($Object -is [Specialized.StringDictionary])         { [PSDictionaryNode]::new($Object) }
                elseif ($Object -is [Collections.ICollection])              { [PSListNode]::new($Object) }
                elseif ($Object -is [ValueType])                            { [PSLeafNode]::new($Object) }
                elseif ($Object -is [String])                               { [PSLeafNode]::new($Object) }
                elseif ($Object -is [ScriptBlock])                          { [PSLeafNode]::new($Object) }
                elseif ($Object.PSObject.Properties)                        { [PSObjectNode]::new($Object) }
                else                                                        { [PSLeafNode]::new($Object) }
            }
        $Node.RootNode = $Node
        if ($MaxDepth -gt 0) { $Node._MaxDepth = $MaxDepth }
        return $Node
    }

    static [PSNode] ParseInput($Object) { return [PSNode]::parseInput($Object, 0) }

    static [int] Compare($Left, $Right) {
        return [ObjectComparer]::new().Compare($Left, $Right)
    }
    static [int] Compare($Left, $Right, [String[]]$PrimaryKey) {
        return [ObjectComparer]::new($PrimaryKey, 0, [CultureInfo]::CurrentCulture).Compare($Left, $Right)
    }
    static [int] Compare($Left, $Right, [String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) {
        return [ObjectComparer]::new($PrimaryKey, $ObjectComparison, [CultureInfo]::CurrentCulture).Compare($Left, $Right)
    }
    static [int] Compare($Left, $Right, [String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison, [CultureInfo]$CultureInfo) {
       return [ObjectComparer]::new($PrimaryKey, $ObjectComparison, $CultureInfo).Compare($Left, $Right)
    }

    hidden [object] get_Value() { return ,$this._Value }

    hidden set_Value($Value) {
        $this.Cache.Clear()
        $this._Value = $Value
        if ($Null -ne $this.ParentNode) { $this.ParentNode.SetItem($this._Name,  $Value) }
        if ($this.GetType() -ne [PSNode]::ParseInput($Value).GetType()) { # The root node is of type PSNode (always false)
            Write-Warning "The supplied value has a different PSNode type than the existing $($this.Path). Use .ParentNode.SetItem() method and reload its child item(s)."
        }
    }

    hidden [Object] get_Name() { return ,$this._Name }

    hidden [Object] get_MaxDepth() { return $this.RootNode._MaxDepth }

    hidden set_MaxDepth($MaxDepth) {
        if (-not $this.ChildType) {
            $this._MaxDepth = $MaxDepth
        }
        else {
            Throw 'The MaxDepth can only be set at the root node: [PSNode].RootNode.MaxDepth = <Maximum Depth>'
        }
    }

    hidden [PSNodeStructure] get_NodeStructure()  {
        if ($this -is [PSListNode]) { return 'List' } elseif ($this -is [PSMapNode]) { return 'Map' } else { return 'Leaf' }
    }

    hidden [PSNodeOrigin] get_NodeOrigin()  {
        if ($this.ParentNode -is [PSListNode]) { return 'List' } elseif ($this.ParentNode -is [PSMapNode]) { return 'Map' } else { return 'Root' }
    }

    hidden [Type] get_ValueType() {
        if ($Null -eq $this._Value) { return $Null }
        else { return $this._Value.getType() }
    }

    [Int]GetHashCode() { return $this.GetHashCode($false) } # Ignore the case of a string value

    hidden [PSNode] Append($Object) {
        $Node = [PSNode]::ParseInput($Object)
        $Node.Depth       = $this.Depth + 1
        $Node.RootNode    = [PSNode]$this.RootNode
        $Node.ParentNode  = $this
        return $Node
    }

    hidden [Object] get_Path() {
        if (-not $this.Cache.ContainsKey('Path')) {
            if ($this.ParentNode) {
                $this.Cache['Path'] = [PSNodePath]($this.ParentNode.get_Path().Nodes + $this)
            }
            else {
                $this.Cache['Path'] = [PSNodePath]$this
            }
        }
        return $this.Cache['Path']
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

    [Bool] Equals($Object)  {  # https://learn.microsoft.com/dotnet/api/system.globalization.compareoptions
        if ($Object -is [PSNode]) { $Node = $Object }
        else { $Node = [PSNode]::ParseInput($Object) }
        $ObjectComparer = [ObjectComparer]::new()
        return $ObjectComparer.IsEqual($this, $Node)
    }

    [int] CompareTo($Object)  {
        if ($Object -is [PSNode]) { $Node = $Object }
        else { $Node = [PSNode]::ParseInput($Object) }
        $ObjectComparer = [ObjectComparer]::new()
        return $ObjectComparer.Compare($this, $Node)
    }

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

    [Int]GetHashCode($CaseSensitive) {
        if ($Null -eq $this._Value) { return '$Null'.GetHashCode() }
        if ($CaseSensitive) { return $this._Value.GetHashCode() }
        else {
            if ($this._Value -is [String]) { return $this._Value.ToUpper().GetHashCode() } # Windows PowerShell doesn't have a System.HashCode struct
            else { return $this._Value.GetHashCode() }
        }
    }

    [string]ToString() { return $this.ToString($false) }
    [string]ToString([Bool]$IsChild) {
        # $MaximumStringLength = if ($IsChild) { [PSNode]::MaximumNodeStringLength } else { [PSNode]::MaximumChildStringLength }
        return $Null

    }
}

Class PSCollectionNode : PSNode {
    hidden static PSCollectionNode() { Use-ClassAccessors }
    hidden [Dictionary[bool,int]]$_HashCode # Unlike the value HashCode, the default (bool = $false) node HashCode is case insensitive
    hidden [Dictionary[bool,int]]$_ReferenceHashCode # if changed, recalculate the (bool = case sensitive) node's HashCode

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

    [List[PSNode]]GetNodeList($Levels, [PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) {
        $NodeList = [List[PSNode]]::new()
        $this.CollectChildNodes($NodeList, $Levels, $NodeOrigin, $Leaf)
        return $NodeList
    }
    [List[PSNode]]GetNodeList()                                       { return $this.GetNodeList(0, 0, $False) }
    [List[PSNode]]GetNodeList([Int]$Levels)                           { return $this.GetNodeList($Levels, 0, $False) }
    [List[PSNode]]GetNodeList([PSNodeOrigin]$NodeOrigin, [Bool]$Leaf) { return $this.GetNodeList(0, $NodeOrigin, $Leaf) }

    hidden [PSNode[]]get_ChildNodes() {
        # There is no link between the 'ChildNodes' cache and the 'GetChildNode()' function
        # because the comparer of the contained value collection is unknown and
        # it is too expensive and ambiguous to linear search for the actual/original key name.
        # see: https://stackoverflow.com/a/78656228/1701026
        if (-not $this.Cache.ContainsKey('ChildNodes')) { $this.Cache['ChildNodes'] = [PSNode[]]$this.GetNodeList(0, 0, $False) }
        return $this.Cache['ChildNodes']
    }

    #hidden [PSNode[]]get_ChildNodes()      { return $this.GetNodeList(0, 0, $False) }
    hidden [PSNode[]]get_ListChildNodes()  { return $this.GetNodeList(0, 'List', $False) }
    hidden [PSNode[]]get_MapChildNodes()   { return $this.GetNodeList(0, 'Map',  $False) }
    hidden [PSNode[]]get_DescendantNodes() { return $this.GetNodeList(-1, 0, $False) }
    hidden [PSNode[]]get_LeafNodes()       { return $this.GetNodeList(-1, 0, $True) }
    # hidden [PSNode]_($Name)                { return $this.GetChildNode($Name) }       # CLI Shorthand ("alias") for GetChildNode (don't use in scripts)
    # hidden [Object]Get($Path)              { return $this.GetDescendantNode($Path) }  # CLI Shorthand ("alias") for GetDescendantNode (don't use in scripts)

    Sort() { $this.Sort($Null, 0) }
    Sort([ObjectComparison]$ObjectComparison) { $this.Sort($Null, $ObjectComparison) }
    Sort([String[]]$PrimaryKey) { $this.Sort($PrimaryKey, 0) }
    Sort([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.Sort($PrimaryKey, $ObjectComparison) }
    Sort([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) {
        # As the child nodes are sorted first, we just do a side-by-side node compare:
        $ObjectComparison = $ObjectComparison -bor [ObjectComparison]'MatchMapOrder'
        $ObjectComparison = $ObjectComparison -band (-1 - [ObjectComparison]'IgnoreListOrder')
        $PSListNodeComparer = [PSListNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
        $PSMapNodeComparer = [PSMapNodeComparer]@{ PrimaryKey = $PrimaryKey; ObjectComparison = $ObjectComparison }
        $this.SortRecurse($PSListNodeComparer, $PSMapNodeComparer)
    }

    hidden SortRecurse([PSListNodeComparer]$PSListNodeComparer, [PSMapNodeComparer]$PSMapNodeComparer) {
        $NodeList = $this.GetNodeList()
        foreach ($Node in $NodeList) {
            if ($Node -is [PSCollectionNode]) { $Node.SortRecurse($PSListNodeComparer, $PSMapNodeComparer) }
        }
        if ($this -is [PSListNode]) {
            $NodeList.Sort($PSListNodeComparer)
            if ($NodeList.Count) { $this._Value = @($NodeList.Value) } else { $this._Value = @() }
        }
        else { # if ($Node -is [PSMapNode])
            $NodeList.Sort($PSMapNodeComparer)
            $Properties = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
            foreach($ChildNode in $NodeList) { $Properties[[Object]$ChildNode.Name] = $ChildNode.Value } # [Object] forces a key rather than an index (ArgumentOutOfRangeException)
            if ($this -is [PSObjectNode]) { $this._Value = [PSCustomObject]$Properties } else { $this._Value = $Properties }
        }
    }
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

    [Int]GetHashCode($CaseSensitive) {
        # The hash of a list node is equal if all items match the order and the case.
        # The primary keys and the list type are not relevant
        if ($null -eq $this._HashCode) {
            $this._HashCode = [Dictionary[bool,int]]::new()
            $this._ReferenceHashCode = [Dictionary[bool,int]]::new()
        }
        $ReferenceHashCode = $This._value.GetHashCode()
        if (-not $this._ReferenceHashCode.ContainsKey($CaseSensitive) -or $this._ReferenceHashCode[$CaseSensitive] -ne $ReferenceHashCode) {
            $this._ReferenceHashCode[$CaseSensitive] = $ReferenceHashCode
            $HashCode = '@()'.GetHashCode() # Empty lists have a common hash that is not 0
            $Index = 0
            foreach ($Node in $this.GetNodeList()) {
                $HashCode = $HashCode -bxor "$Index.$($Node.GetHashCode($CaseSensitive))".GetHashCode()
                $index++
            }
            $this._HashCode[$CaseSensitive] = $HashCode
        }
        return $this._HashCode[$CaseSensitive]
    }
}

Class PSMapNode : PSCollectionNode {
    hidden static PSMapNode() { Use-ClassAccessors }

    [Int]GetHashCode($CaseSensitive) {
        # The hash of a map node is equal if all names and items match the order and the case.
        # The map type is not relevant
        if ($null -eq $this._HashCode) {
            $this._HashCode = [Dictionary[bool,int]]::new()
            $this._ReferenceHashCode = [Dictionary[bool,int]]::new()
        }
        $ReferenceHashCode = $This._value.GetHashCode()
        if (-not $this._ReferenceHashCode.ContainsKey($CaseSensitive) -or $this._ReferenceHashCode[$CaseSensitive] -ne $ReferenceHashCode) {
            $this._ReferenceHashCode[$CaseSensitive] = $ReferenceHashCode
            $HashCode = '@{}'.GetHashCode() # Empty maps have a common hash that is not 0
            $Index = 0
            foreach ($Node in $this.GetNodeList()) {
                $Name = if ($CaseSensitive) { $Node._Name } else { $Node._Name.ToUpper() }
                $HashCode = $HashCode -bxor "$Index.$Name=$($Node.GetHashCode())".GetHashCode()
                $Index++
            }
            $this._HashCode[$CaseSensitive] = $HashCode
        }
        return $this._HashCode[$CaseSensitive]
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
        if (-not $this._Value.Contains($Key)) { Throw "The <Object>$($this.Path) doesn't contain a child named: $Key" }
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


#      ___  _     _           _    ____
#     / _ \| |__ (_) ___  ___| |_ / ___|___  _ __ ___  _ __   __ _ _ __ ___ _ __
#    | | | | '_ \| |/ _ \/ __| __| |   / _ \| '_ ` _ \| '_ \ / _` | '__/ _ \ '__|
#    | |_| | |_) | |  __/ (__| |_| |__| (_) | | | | | | |_) | (_| | | |  __/ |
#     \___/|_.__// |\___|\___|\__|\____\___/|_| |_| |_| .__/ \__,_|_|  \___|_|
#              |__/                                   |_|

enum ObjectCompareMode {
    Equals  # https://learn.microsoft.com/dotnet/api/system.object.equals
    Compare # https://learn.microsoft.com/dotnet/api/system.string.compareto
    Report  # Returns a report with discrepancies
}

[Flags()] enum ObjectComparison { MatchCase = 1; MatchType = 2; IgnoreListOrder = 4; MatchMapOrder = 8; Descending = 128 }

class ObjectComparer {

    # Report properties (column names)
    [String]$Name1 = 'Reference'
    [String]$Name2 = 'InputObject'
    [String]$Issue = 'Discrepancy'

    [String[]]$PrimaryKey
    [ObjectComparison]$ObjectComparison

    [Collections.Generic.List[Object]]$Differences

    ObjectComparer () {}
    ObjectComparer ([String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey }
    ObjectComparer ([ObjectComparison]$ObjectComparison) { $this.ObjectComparison = $ObjectComparison }
    ObjectComparer ([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    ObjectComparer ([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }

    [bool] IsEqual ($Object1, $Object2) { return $this.Compare($Object1, $Object2, 'Equals') }
    [int] Compare  ($Object1, $Object2) { return $this.Compare($Object1, $Object2, 'Compare') }
    [Object] Report ($Object1, $Object2) {
        $this.Differences = [Collections.Generic.List[Object]]::new()
        $null = $this.Compare($Object1, $Object2, 'Report')
        return $this.Differences
    }

    [Object] Compare($Object1, $Object2, [ObjectCompareMode]$Mode) {
        if ($Object1 -is [PSNode]) { $Node1 = $Object1 } else { $Node1 = [PSNode]::ParseInput($Object1) }
        if ($Object2 -is [PSNode]) { $Node2 = $Object2 } else { $Node2 = [PSNode]::ParseInput($Object2) }
        return $this.CompareRecurse($Node1, $Node2, $Mode)
    }

    hidden [Object] CompareRecurse([PSNode]$Node1, [PSNode]$Node2, [ObjectCompareMode]$Mode) {
        $Comparison = $this.ObjectComparison
        $MatchCase = $Comparison -band 'MatchCase'
        $EqualType = $true

        if ($Mode -ne 'Compare') { # $Mode -ne 'Compare'
            if ($MatchCase -and $Node1.ValueType -ne $Node2.ValueType) {
                if ($Mode -eq 'Equals') { return $false } else { # if ($Mode -eq 'Report')
                    $this.Differences.Add([PSCustomObject]@{
                        Path        = $Node2.Path
                        $this.Issue = 'Type'
                        $this.Name1 = $Node1.ValueType
                        $this.Name2 = $Node2.ValueType
                    })
                }
            }
            if ($Node1 -is [PSCollectionNode] -and $Node2 -is [PSCollectionNode] -and $Node1.Count -ne $Node2.Count) {
                if ($Mode -eq 'Equals') { return $false } else { # if ($Mode -eq 'Report')
                    $this.Differences.Add([PSCustomObject]@{
                        Path        = $Node2.Path
                        $this.Issue = 'Size'
                        $this.Name1 = $Node1.Count
                        $this.Name2 = $Node2.Count
                    })
                }
            }
        }

        if ($Node1 -is [PSLeafNode] -and $Node2 -is [PSLeafNode]) {
            $Eq = if ($MatchCase) { $Node1.Value -ceq $Node2.Value } else { $Node1.Value -eq $Node2.Value }
            Switch ($Mode) {
                Equals    { return $Eq }
                Compare {
                    if ($Eq) { return 1 - $EqualType } # different types results in 1 (-gt)
                    else {
                        $Greater = if ($MatchCase) { $Node1.Value -cgt $Node2.Value } else { $Node1.Value -gt $Node2.Value }
                        if ($Greater -xor $Comparison -band 'Descending') { return 1 } else { return -1 }
                    }
                }
                default {
                    if (-not $Eq) {
                        $this.Differences.Add([PSCustomObject]@{
                            Path        = $Node2.Path
                            $this.Issue = 'Value'
                            $this.Name1 = $Node1.Value
                            $this.Name2 = $Node2.Value
                        })
                    }
                }
            }
        }
        elseif ($Node1 -is [PSListNode] -and $Node2 -is [PSListNode]) {
            $MatchOrder = -not ($Comparison -band 'IgnoreListOrder')
            # if ($Node1.GetHashCode($MatchCase) -eq $Node2.GetHashCode($MatchCase)) {
            #     if ($Mode -eq 'Equals') { return $true } else { return 0 } # Report mode doesn't care about the output
            # }
            $Items1 = $Node1.ChildNodes
            $Items2 = $Node2.ChildNodes
            if ($Items1.Count) { $Indices1 = [Collections.Generic.List[Int]]$Items1.Name } else { $Indices1 = @() }
            if ($Items2.Count) { $Indices2 = [Collections.Generic.List[Int]]$Items2.Name } else { $Indices2 = @() }
            if ($this.PrimaryKey) {
                $Maps2 = [Collections.Generic.List[Int]]$Items2.where{ $_ -is [PSMapNode] }.Name
                if ($Maps2.Count) {
                    $Maps1 = [Collections.Generic.List[Int]]$Items1.where{ $_ -is [PSMapNode] }.Name
                    if ($Maps1.Count) {
                        foreach ($Key in $this.PrimaryKey) {
                            foreach($Index2 in @($Maps2)) {
                                $Item2 = $Items2[$Index2]
                                foreach ($Index1 in $Maps1) {
                                    $Item1 = $Items1[$Index1]
                                    if ($Item1.GetItem($Key) -eq $Item2.GetItem($Key)) {
                                        if ($this.CompareRecurse($Item1, $Item2, 'Equals')) {
                                            $null = $Maps2.Remove($Index2)
                                            $Null = $Maps1.Remove($Index1)
                                            $null = $Indices2.Remove($Index2)
                                            $Null = $Indices1.Remove($Index1)
                                            break # Only match the first primary key
                                        }
                                    }
                                }
                            }
                        }
                        # in case of any single maps leftover without primary keys
                        if($Maps2.Count -eq 1 -and $Maps1.Count -eq 1) {
                            $Item2 = $Items2[$Maps2[0]]
                            $Item1 = $Items1[$Maps1[0]]
                            $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                            Switch ($Mode) {
                                Equals  { if (-not $Compare) { return $Compare } }
                                Compare { if ($Compare)      { return $Compare } }
                                Default {
                                    $Maps2.Clear()
                                    $Maps1.Clear()
                                    $null = $Indices2.Remove($Maps2[0])
                                    $Null = $Indices1.Remove($Maps1[0])
                                }
                            }
                        }
                    }
                }
            }
            if (-not $MatchOrder) { # remove the equal nodes from the lists
                foreach($Index2 in @($Indices2)) {
                    $Item2 = $Items2[$Index2]
                    foreach ($Index1 in $Indices1) {
                        $Item1 = $Items1[$Index1]
                        if ($this.CompareRecurse($Item1, $Item2, 'Equals')) {
                            $null = $Indices2.Remove($Index2)
                            $Null = $Indices1.Remove($Index1)
                            break # Only match a single node
                        }
                    }
                }
            }
            for ($i = 0; $i -lt [math]::max($Indices2.Count, $Indices1.Count); $i++) {
                $Index1 = if ($i -lt $Indices1.Count) { $Indices1[$i] }
                $Index2 = if ($i -lt $Indices2.Count) { $Indices2[$i] }
                $Item1  = if ($Null -ne $Index1) { $Items1[$Index1] }
                $Item2  = if ($Null -ne $Index2) { $Items2[$Index2] }
                if ($Null -eq $Item1) {
                    Switch ($Mode) {
                        Equals  { return $false }
                        Compare { return -1 } # None existing items can't be ordered
                        default {
                            $this.Differences.Add([PSCustomObject]@{
                                Path        = $Node2.Path + "[$Index2]"
                                $this.Issue = 'Exists'
                                $this.Name1 = $Null
                                $this.Name2 = if ($Item2 -is [PSLeafNode]) { "$($Item2.Value)" } else { "[$($Item2.ValueType)]" }
                            })
                        }
                    }
                }
                elseif ($Null -eq $Item2) {
                    Switch ($Mode) {
                        Equals  { return $false }
                        Compare { return 1 } # None existing items can't be ordered
                        default {
                            $this.Differences.Add([PSCustomObject]@{
                                Path        = $Node1.Path + "[$Index1]"
                                $this.Issue = 'Exists'
                                $this.Name1 = if ($Item1 -is [PSLeafNode]) { "$($Item1.Value)" } else { "[$($Item1.ValueType)]" }
                                $this.Name2 = $Null
                            })
                        }
                    }
                }
                else {
                    $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                    if (($Mode -eq 'Equals' -and -not $Compare) -or ($Mode -eq 'Compare' -and $Compare)) { return $Compare }
                }
            }
            if ($Mode -eq 'Equals') { return $true } elseif ($Mode -eq 'Compare') { return 0 } else { return $null }
        }
        elseif ($Node1 -is [PSMapNode] -and $Node2 -is [PSMapNode]) {
            $MatchOrder = [Bool]($Comparison -band 'MatchMapOrder')
            if ($MatchOrder -and $Node1._Value -isnot [HashTable] -and $Node2._Value -isnot [HashTable]) {
                $Items2 = $Node2.ChildNodes
                $Index = 0
                foreach ($Item1 in $Node1.ChildNodes) {
                    if ($Index -lt $Items2.Count) { $Item2 = $Items2[$Index++] } else { break }
                    $EqualName = if ($MatchCase) { $Item1.Name -ceq $Item2.Name } else { $Item1.Name -eq $Item2.Name }
                    if ($EqualName) {
                        $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                        if (($Mode -eq 'Equals' -and -not $Compare) -or ($Mode -eq 'Compare' -and $Compare)) { return $Compare }
                    }
                    else {
                        Switch ($Mode) {
                            Equals  { return $false }
                            Compare {} # The order depends on the child name and value
                            default {
                                $this.Differences.Add([PSCustomObject]@{
                                    Path        = $Item1.Path
                                    $this.Issue = 'Name'
                                    $this.Name1 = $Item1.Name
                                    $this.Name2 = $Item2.Name
                                })
                            }
                        }
                    }
                }
            }
            else {
                $Found = [HashTable]::new() # (Case sensitive)
                foreach ($Item2 in $Node2.ChildNodes) {
                    if ($Node1.Contains($Item2.Name)) {
                        $Item1 = $Node1.GetChildNode($Item2.Name) # Left defines the comparer
                        $Found[$Item1.Name] = $true
                        $Compare = $this.CompareRecurse($Item1, $Item2, $Mode)
                        if (($Mode -eq 'Equals' -and -not $Compare) -or ($Mode -eq 'Compare' -and $Compare)) { return $Compare }
                    }
                    else {
                        Switch ($Mode) {
                            Equals  { return $false }
                            Compare { return -1 }
                            default {
                                $this.Differences.Add([PSCustomObject]@{
                                    Path        = $Item2.Path
                                    $this.Issue = 'Exists'
                                    $this.Name1 = $false
                                    $this.Name2 = $true
                                })
                            }
                        }
                    }
                }
                $Node1.Names.foreach{
                    if (-not $Found.Contains($_)) {
                        Switch ($Mode) {
                            Equals  { return $false }
                            Compare { return 1 }
                            default {
                                $this.Differences.Add([PSCustomObject]@{
                                    Path        = $Node1.GetChildNode($_).Path
                                    $this.Issue = 'Exists'
                                    $this.Name1 = $true
                                    $this.Name2 = $false
                                })
                            }
                        }
                    }
                }
            }
            if ($Mode -eq 'Equals') { return $true } elseif ($Mode -eq 'Compare') { return 0 } else { return $null }
        }
        else { # Different structure
            Switch ($Mode) {
                Equals  { return $false }
                Compare { # Structure order: PSLeafNode - PSListNode - PSMapNode (can't be reversed)
                    if ($Node1 -is [PSLeafNode] -or $Node2 -isnot [PSMapNode] ) { return -1 } else { return 1 }
                }
                default {
                    $this.Differences.Add([PSCustomObject]@{
                        Path        = $Node1.Path
                        $this.Issue = 'Structure'
                        $this.Name1 = $Node1.ValueType.Name
                        $this.Name2 = $Node2.ValueType.Name
                    })
                }
            }
        }
        if ($Mode -eq 'Equals')  { throw 'Equals comparison should have returned boolean.' }
        if ($Mode -eq 'Compare') { throw 'Compare comparison should have returned integer.' }
        return $null
    }
}

class PSListNodeComparer : ObjectComparer, IComparer[Object] { # https://github.com/PowerShell/PowerShell/issues/23959
    PSListNodeComparer () {}
    PSListNodeComparer ([String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey }
    PSListNodeComparer ([ObjectComparison]$ObjectComparison) { $this.ObjectComparison = $ObjectComparison }
    PSListNodeComparer ([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    PSListNodeComparer ([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    [int] Compare ([Object]$Node1, [Object]$Node2) { return $this.CompareRecurse($Node1, $Node2, 'Compare') }
}

class PSMapNodeComparer : IComparer[Object] {
    [String[]]$PrimaryKey
    [ObjectComparison]$ObjectComparison

    PSMapNodeComparer () {}
    PSMapNodeComparer ([String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey }
    PSMapNodeComparer ([ObjectComparison]$ObjectComparison) { $this.ObjectComparison = $ObjectComparison }
    PSMapNodeComparer ([String[]]$PrimaryKey, [ObjectComparison]$ObjectComparison) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    PSMapNodeComparer ([ObjectComparison]$ObjectComparison, [String[]]$PrimaryKey) { $this.PrimaryKey = $PrimaryKey; $this.ObjectComparison = $ObjectComparison }
    [int] Compare ([Object]$Node1, [Object]$Node2) {
        $Comparison = $this.ObjectComparison
        $MatchCase = $Comparison -band 'MatchCase'
        $Equal = if ($MatchCase) { $Node1.Name -ceq $Node2.Name } else { $Node1.Name -eq $Node2.Name }
        if ($Equal) { return 0 }
        else {
            if ($this.PrimaryKey) {                                           # Primary keys take always priority
                if ($this.PrimaryKey -eq $Node1.Name) { return -1 }
                if ($this.PrimaryKey -eq $Node2.Name) { return 1 }
            }
            $Greater = if ($MatchCase) { $Node1.Name -cgt $Node2.Name } else { $Node1.Name -gt $Node2.Name }
            if ($Greater -xor $Comparison -band 'Descending') { return 1 } else { return -1 }
        }
    }
}
