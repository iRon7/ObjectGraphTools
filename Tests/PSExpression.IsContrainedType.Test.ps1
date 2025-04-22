#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

param()

Describe 'PSExpression' {

    BeforeAll {

        Set-StrictMode -Version Latest

    }

    Context 'Is constrained type' {

        It 'Adsi' {
            $Type = 'Adsi' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'AdsiSearcher' {
            $Type = 'AdsiSearcher' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Alias' {
            $Type = 'Alias' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'AllowEmptyCollection' {
            $Type = 'AllowEmptyCollection' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'AllowEmptyString' {
            $Type = 'AllowEmptyString' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'AllowNull' {
            $Type = 'AllowNull' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ArgumentCompleter' {
            $Type = 'ArgumentCompleter' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ArgumentCompletions' {
            $Type = 'ArgumentCompletions' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [ArgumentCompletions] doesn't exists in Windows PowerShell
        }

        It 'Array' {
            $Type = 'Array' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'BigInt' {
            $Type = 'BigInt' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Bool' {
            $Type = 'Bool' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Byte' {
            $Type = 'Byte' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Char' {
            $Type = 'Char' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CimClass' {
            $Type = 'CimClass' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CimConverter' {
            $Type = 'CimConverter' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CimInstance' {
            $Type = 'CimInstance' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CimSession' {
            $Type = 'CimSession' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CimType' {
            $Type = 'CimType' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CmdletBinding' {
            $Type = 'CmdletBinding' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'CultureInfo' {
            $Type = 'CultureInfo' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'DateTime' {
            $Type = 'DateTime' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Decimal' {
            $Type = 'Decimal' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Double' {
            $Type = 'Double' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'DscLocalConfigurationManager' {
            $Type = 'DscLocalConfigurationManager' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'DscProperty' {
            $Type = 'DscProperty' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'DscResource' {
            $Type = 'DscResource' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ExperimentAction' {
            $Type = 'ExperimentAction' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [ExperimentAction] doesn't exists in Windows PowerShell
        }

        It 'Experimental' {
            $Type = 'Experimental' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [Experimental] doesn't exists in Windows PowerShell
        }

        It 'ExperimentalFeature' {
            $Type = 'ExperimentalFeature' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [ExperimentalFeature] doesn't exists in Windows PowerShell
        }

        It 'Float' {
            $Type = 'Float' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Guid' {
            $Type = 'Guid' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Hashtable' {
            $Type = 'Hashtable' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Int' {
            $Type = 'Int' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Int16' {
            $Type = 'Int16' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Int32' {
            $Type = 'Int32' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Int64' {
            $Type = 'Int64' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'IpAddress' {
            $Type = 'IpAddress' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'IPEndpoint' {
            $Type = 'IPEndpoint' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Long' {
            $Type = 'Long' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'MailAddress' {
            $Type = 'MailAddress' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Microsoft.PowerShell.Commands.ModuleSpecification' {
            $Type = 'Microsoft.PowerShell.Commands.ModuleSpecification' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'NoRunSpaceAffinity' {
            $Type = 'NoRunSpaceAffinity' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [NoRunSpaceAffinity] doesn't exists in Windows PowerShell
        }

        It 'NullString' {
            $Type = 'NullString' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Object' {
            $Type = 'Object' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ObjectSecurity' {
            $Type = 'ObjectSecurity' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Ordered' {
            $Type = 'Ordered' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [Ordered] doesn't exists in Windows PowerShell
        }

        It 'OutputType' {
            $Type = 'OutputType' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Parameter' {
            $Type = 'Parameter' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PhysicalAddress' {
            $Type = 'PhysicalAddress' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSCredential' {
            $Type = 'PSCredential' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSCustomObject' {
            $Type = 'PSCustomObject' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSDefaultValue' {
            $Type = 'PSDefaultValue' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSListModifier' {
            $Type = 'PSListModifier' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSObject' {
            $Type = 'PSObject' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSPrimitiveDictionary' {
            $Type = 'PSPrimitiveDictionary' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'PSTypeNameAttribute' {
            $Type = 'PSTypeNameAttribute' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Ref' {
            $Type = 'Ref' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Regex' {
            $Type = 'Regex' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'SByte' {
            $Type = 'SByte' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'SecureString' {
            $Type = 'SecureString' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'SemVer' {
            $Type = 'SemVer' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [SemVer] doesn't exists in Windows PowerShell
        }

        It 'Short' {
            $Type = 'Short' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [Short] doesn't exists in Windows PowerShell
        }

        It 'Single' {
            $Type = 'Single' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'String' {
            $Type = 'String' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'SupportsWildcards' {
            $Type = 'SupportsWildcards' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Switch' {
            $Type = 'Switch' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'TimeSpan' {
            $Type = 'TimeSpan' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'UInt' {
            $Type = 'UInt' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [UInt] doesn't exists in Windows PowerShell
        }

        It 'UInt16' {
            $Type = 'UInt16' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'UInt32' {
            $Type = 'UInt32' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'UInt64' {
            $Type = 'UInt64' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ULong' {
            $Type = 'ULong' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [ULong] doesn't exists in Windows PowerShell
        }

        It 'Uri' {
            $Type = 'Uri' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'UShort' {
            $Type = 'UShort' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [UShort] doesn't exists in Windows PowerShell
        }

        It 'ValidateCount' {
            $Type = 'ValidateCount' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateDrive' {
            $Type = 'ValidateDrive' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateLength' {
            $Type = 'ValidateLength' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateNotNull' {
            $Type = 'ValidateNotNull' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateNotNullOrEmpty' {
            $Type = 'ValidateNotNullOrEmpty' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateNotNullOrWhiteSpace' {
            $Type = 'ValidateNotNullOrWhiteSpace' -as [Type]
            if ($Type) { [PSLanguageType]::IsConstrained($Type) | Should -BeTrue } # else [ValidateNotNullOrWhiteSpace] doesn't exists in Windows PowerShell
        }

        It 'ValidatePattern' {
            $Type = 'ValidatePattern' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateRange' {
            $Type = 'ValidateRange' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateScript' {
            $Type = 'ValidateScript' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateSet' {
            $Type = 'ValidateSet' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateTrustedData' {
            $Type = 'ValidateTrustedData' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'ValidateUserDrive' {
            $Type = 'ValidateUserDrive' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Version' {
            $Type = 'Version' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Void' {
            $Type = 'Void' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'WildcardPattern' {
            $Type = 'WildcardPattern' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Wmi' {
            $Type = 'Wmi' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'WmiClass' {
            $Type = 'WmiClass' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'WmiSearcher' {
            $Type = 'WmiSearcher' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'X500DistinguishedName' {
            $Type = 'X500DistinguishedName' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'X509Certificate' {
            $Type = 'X509Certificate' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }

        It 'Xml' {
            $Type = 'Xml' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeTrue
        }
    }

Context 'Is NOT constrained type' {

        It 'System.Management.Automation.Language.AST' {
            $Type = 'System.Management.Automation.Language.AST' -as [Type]
            [PSLanguageType]::IsConstrained($Type) | Should -BeFalse
        }
    }
}
