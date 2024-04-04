#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

using module ..\..\ObjectGraphTools

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'Object', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', 'ObjectGraph', Justification = 'False positive')]
param()

# $PesterPreference = [PesterConfiguration]::Default
# $PesterPreference.Should.ErrorAction = 'Stop'

Describe 'ConvertTo-Expression' {

    BeforeAll {

        Set-StrictMode -Version Latest
    }

    Context 'Existence Check' {

        It 'Help' {
            ConvertTo-Expression -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Constrained values' {
        It 'adsi' {
            $Object = Invoke-Expression "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
        }

        It 'adsisearcher' {
            $Object = Invoke-Expression "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[adsisearcher]'0123'"
        }

        It 'Alias' {
            $Object = Invoke-Expression "[Alias][String[]]'Example'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[Alias][String[]]'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[Alias][String[]]'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[Alias][String[]]'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[Alias][String[]]'Example'"
        }

        It 'AllowEmptyCollection' {
            $Object = Invoke-Expression "[AllowEmptyCollection]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[AllowEmptyCollection]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[AllowEmptyCollection]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[AllowEmptyCollection]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[AllowEmptyCollection]@{}"
        }

        It 'AllowEmptyString' {
            $Object = Invoke-Expression "[AllowEmptyString]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[AllowEmptyString]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[AllowEmptyString]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[AllowEmptyString]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[AllowEmptyString]@{}"
        }

        It 'AllowNull' {
            $Object = Invoke-Expression "[AllowNull]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[AllowNull]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[AllowNull]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[AllowNull]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[AllowNull]@{}"
        }

        It 'ArgumentCompleter' {
            $Object = Invoke-Expression "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object | Should -Be "{'Example'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ArgumentCompleter]{'Example'}"
        }

        It 'ArgumentCompletions' -Skip:(-not ('ArgumentCompletions' -as [Type])) {
            $Object = Invoke-Expression "[ArgumentCompletions][String[]]'System.Management.Automation.ArgumentCompletionsAttribute'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'System.Management.Automation.ArgumentCompletionsAttribute'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ArgumentCompletions][String[]]'System.Management.Automation.ArgumentCompletionsAttribute'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ArgumentCompletions][String[]]'System.Management.Automation.ArgumentCompletionsAttribute'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ArgumentCompletions][String[]]'System.Management.Automation.ArgumentCompletionsAttribute'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ArgumentCompletions][String[]]'System.Management.Automation.ArgumentCompletionsAttribute'"
        }

        It 'bigint' {
            $Object = Invoke-Expression "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'1234567890'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[bigint]'1234567890'"
        }

        It 'bool' {
            $Object = Invoke-Expression '[bool]$True'
            ConvertTo-Expression -InputObject $Object | Should -Be '$True'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be '$True'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be '[bool]$True'
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be '[bool]$True'
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be '[bool]$True'
        }

        It 'byte' {
            $Object = Invoke-Expression "[byte]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[byte]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[byte]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[byte]123"
        }

        It 'char' {
            $Object = Invoke-Expression "[char]'a'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'a'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "'a'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[char]'a'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[char]'a'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[char]'a'"
        }

        It 'ciminstance' {
            $Object = Invoke-Expression "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ciminstance]'Example'"
        }

        It 'CimSession' {
            $Object = Invoke-Expression "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[CimSession]'0123'"
        }

        It 'cimtype' {
            $Object = Invoke-Expression "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'Boolean'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[cimtype]'Boolean'"
        }

        It 'CmdletBinding' {
            $Object = Invoke-Expression "[CmdletBinding]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[CmdletBinding]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[CmdletBinding]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[CmdletBinding]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[CmdletBinding]@{}"
        }

        It 'cultureinfo' {
            $Object = Invoke-Expression "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'en-US'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[cultureinfo]'en-US'"
        }

        It 'datetime' {
            $Object = Invoke-Expression "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
        }

        It 'decimal' {
            $Object = Invoke-Expression "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0.123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[decimal]'0.123'"
        }

        It 'double' {
            $Object = Invoke-Expression "[double]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[double]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[double]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[double]123"
        }

        It 'DscLocalConfigurationManager' {
            $Object = Invoke-Expression "[DscLocalConfigurationManager]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[DscLocalConfigurationManager]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[DscLocalConfigurationManager]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[DscLocalConfigurationManager]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[DscLocalConfigurationManager]@{}"
        }

        It 'DscProperty' {
            $Object = Invoke-Expression "[DscProperty]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[DscProperty]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[DscProperty]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[DscProperty]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[DscProperty]@{}"
        }

        It 'DscResource' {
            $Object = Invoke-Expression "[DscResource]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[DscResource]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[DscResource]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[DscResource]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[DscResource]@{}"
        }

        It 'ExperimentAction' -Skip:(-not ('ExperimentAction' -as [Type])) {
            $Object = Invoke-Expression "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'None'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ExperimentAction]'None'"
        }

        It 'float' {
            $Object = Invoke-Expression "[float]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[float]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[float]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[float]123"
        }

        It 'guid' {
            $Object = Invoke-Expression "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
        }

        It 'int' {
            $Object = Invoke-Expression "[int]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[int]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[int]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[int]123"
        }

        It 'short' -Skip:(-not ('short' -as [Type])) {
            $Object = Invoke-Expression "[short]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[short]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[short]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[short]123"
        }

        It 'long' {
            $Object = Invoke-Expression "[long]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[long]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[long]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[long]123"
        }

        It 'ipaddress' {
            $Object = Invoke-Expression "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ipaddress]'198.168.1.1'"
        }

        It 'IPEndpoint' {
            $Object = Invoke-Expression "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object | Should -Be "(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[IPEndpoint]::new(16885958, 123)"
        }

        It 'mailaddress' {
            $Object = Invoke-Expression "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[mailaddress]'iron@contoso.com'"
        }

        It 'Microsoft.PowerShell.Commands.ModuleSpecification' {
            $Object = Invoke-Expression "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
        }

        It 'NoRunspaceAffinity' -Skip:(-not ('NoRunspaceAffinity' -as [Type])) {
            $Object = Invoke-Expression "[NoRunspaceAffinity]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[NoRunspaceAffinity]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[NoRunspaceAffinity]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[NoRunspaceAffinity]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[NoRunspaceAffinity]@{}"
        }

        It 'System.Object' {
            $Object = Invoke-Expression "[System.Object]::new()"
            ConvertTo-Expression -InputObject $Object | Should -Be "()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[System.Object]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[System.Object]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[System.Object]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[System.Object]::new()"
        }

        It 'OutputType' {
            $Object = Invoke-Expression "[OutputType][String[]]'bool'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'bool'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[OutputType][String[]]'bool'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[OutputType][String[]]'bool'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[OutputType][String[]]'bool'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[OutputType][String[]]'bool'"
        }

        It 'Parameter' {
            $Object = Invoke-Expression "[Parameter]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[Parameter]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[Parameter]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[Parameter]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[Parameter]@{}"
        }

        It 'PhysicalAddress' {
            $Object = Invoke-Expression "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[PhysicalAddress]'0123'"
        }

        It 'PSDefaultValue' {
            $Object = Invoke-Expression "[PSDefaultValue]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[PSDefaultValue]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[PSDefaultValue]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[PSDefaultValue]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[PSDefaultValue]@{}"
        }

        It 'pslistmodifier' {
            $Object = Invoke-Expression "[pslistmodifier]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[pslistmodifier]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[pslistmodifier]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[pslistmodifier]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[pslistmodifier]@{}"
        }

        It 'PSTypeNameAttribute' {
            $Object = Invoke-Expression "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[PSTypeNameAttribute]'0123'"
        }

        It 'regex' {
            $Object = Invoke-Expression "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[regex]'0123'"
        }

        It 'sbyte' {
            $Object = Invoke-Expression "[sbyte]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[sbyte]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[sbyte]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[sbyte]123"
        }

        It 'semver' -Skip:(-not ('semver' -as [Type])) {
            $Object = Invoke-Expression "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[semver]'1.2.0-a.1'"
        }

        It 'string' {
            $Object = Invoke-Expression "[string]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[string]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[string]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[string]'0123'"
        }

        It 'SupportsWildcards' {
            $Object = Invoke-Expression "[SupportsWildcards]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[SupportsWildcards]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[SupportsWildcards]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[SupportsWildcards]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[SupportsWildcards]@{}"
        }

        It 'timespan' {
            $Object = Invoke-Expression "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[timespan]'1.02:03:04.0050000'"
        }

        It 'ushort' -Skip:(-not ('ushort' -as [Type])) {
            $Object = Invoke-Expression "[ushort]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ushort]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ushort]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ushort]123"
        }

        It 'uint' -Skip:(-not ('uint' -as [Type])) {
            $Object = Invoke-Expression "[uint]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[uint]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[uint]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[uint]123"
        }

        It 'ulong' -Skip:(-not ('ulong' -as [Type])) {
            $Object = Invoke-Expression "[ulong]123"
            ConvertTo-Expression -InputObject $Object | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ulong]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ulong]123"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ulong]123"
        }

        It 'uri' {
            $Object = Invoke-Expression "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[uri]'0123'"
        }

        It 'ValidateDrive' {
            $Object = Invoke-Expression "[ValidateDrive]::new()"
            ConvertTo-Expression -InputObject $Object | Should -Be "()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateDrive]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateDrive]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateDrive]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateDrive]::new()"
        }

        It 'ValidateNotNull' {
            $Object = Invoke-Expression "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object | Should -Be "()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateNotNull]::new()"
        }

        It 'ValidateNotNullOrEmpty' {
            $Object = Invoke-Expression "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object | Should -Be "()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateNotNullOrEmpty]::new()"
        }

        It 'ValidateNotNullOrWhiteSpace' -Skip:(-not ('ValidateNotNullOrWhiteSpace' -as [Type])) {
            $Object = Invoke-Expression "[ValidateNotNullOrWhiteSpace]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateNotNullOrWhiteSpace]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateNotNullOrWhiteSpace]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateNotNullOrWhiteSpace]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateNotNullOrWhiteSpace]@{}"
        }

        It 'ValidatePattern' {
            $Object = Invoke-Expression "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'Pattern'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidatePattern]'Pattern'"
        }

        It 'ValidateScript' {
            $Object = Invoke-Expression "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object | Should -Be "{'Validate'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateScript]{'Validate'}"
        }

        It 'ValidateSet' {
            $Object = Invoke-Expression "[ValidateSet][String[]]('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object | Should -Be "('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateSet][String[]]('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateSet][String[]]('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateSet][String[]]('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateSet][String[]]('Value1', 'Value2')"
        }

        It 'ValidateTrustedData' {
            $Object = Invoke-Expression "[ValidateTrustedData]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateTrustedData]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateTrustedData]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateTrustedData]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateTrustedData]@{}"
        }

        It 'ValidateUserDrive' {
            $Object = Invoke-Expression "[ValidateUserDrive]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be '$Null'
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[ValidateUserDrive]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[ValidateUserDrive]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[ValidateUserDrive]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[ValidateUserDrive]@{}"
        }

        It 'version' {
            $Object = Invoke-Expression "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[version]'0.1.2.3'"
        }

        It 'WildcardPattern' {
            $Object = Invoke-Expression "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[WildcardPattern]'_T?e%s*t'"
        }

        It 'wmi' {
            $Object = Invoke-Expression "[wmi]''"
            ConvertTo-Expression -InputObject $Object | Should -Be "''"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[wmi]''"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[wmi]''"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[wmi]''"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[wmi]''"
        }

        It 'wmiclass' {
            $Object = Invoke-Expression "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
        }

        It 'wmisearcher' {
            $Object = Invoke-Expression "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'QueryString'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[wmisearcher]'QueryString'"
        }

        It 'X500DistinguishedName' {
            $Object = Invoke-Expression "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object | Should -Be "'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
        }

        It 'X509Certificate' {
            $Object = Invoke-Expression "[X509Certificate]@{}"
            ConvertTo-Expression -InputObject $Object | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[X509Certificate]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[X509Certificate]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[X509Certificate]@{}"
            ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[X509Certificate]@{}"
        }

#         It 'xml' {
#             $Object = Invoke-Expression "[xml]@'
# <book>
#   <name>A Song of Ice and Fire</name>
#   <author>George R. R. Martin</author>
#   <language>English</language>
#   <genre>Epic fantasy</genre>
# </book>
# '@"
#             ConvertTo-Expression -InputObject $Object | Should -Be "@'
# <book>
#   <name>A Song of Ice and Fire</name>
#   <author>George R. R. Martin</author>
#   <language>English</language>
#   <genre>Epic fantasy</genre>
# </book>
# '@"
#             ConvertTo-Expression -InputObject $Object -LanguageMode Constrained | Should -Be "[xml]@'
# <book>
#   <name>A Song of Ice and Fire</name>
#   <author>George R. R. Martin</author>
#   <language>English</language>
#   <genre>Epic fantasy</genre>
# </book>
# '@"
#             ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit | Should -Be "[xml]@'
# <book>
#   <name>A Song of Ice and Fire</name>
#   <author>George R. R. Martin</author>
#   <language>English</language>
#   <genre>Epic fantasy</genre>
# </book>
# '@"
#             ConvertTo-Expression -InputObject $Object -LanguageMode Full | Should -Be "[xml]@'
# <book>
#   <name>A Song of Ice and Fire</name>
#   <author>George R. R. Martin</author>
#   <language>English</language>
#   <genre>Epic fantasy</genre>
# </book>
# '@"
#             ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit | Should -Be "[xml]@'
# <book>
#   <name>A Song of Ice and Fire</name>
#   <author>George R. R. Martin</author>
#   <language>English</language>
#   <genre>Epic fantasy</genre>
# </book>
# '@"
        # }

    }

    Context 'Formatting' {
        BeforeAll {
            $Object = [PSCustomObject]@{
                first_name = 'John'
                last_name = 'Smith'
                is_alive = $True
                age = 27
                address = [PSCustomObject]@{
                    street_address = '21 2nd Street'
                    city = 'New York'
                    state = 'NY'
                    postal_code = '10021-3100'
                }
                phone_numbers =[PSCustomObject] @(
                    @{
                        type = 'home'
                        number = '212 555-1234'
                    },
                    @{
                        type = 'office'
                        number = '646 555-4567'
                    }
                )
                children = @('Catherine')
                spouse = $Null
            }
        }

        It 'ConvertTo-Expression (Default)' {
            $Expression = ConvertTo-Expression -InputObject $Object
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = @{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{
            number = '212 555-1234'
            type = 'home'
        },
        @{
            number = '646 555-4567'
            type = 'office'
        }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = @{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{
            number = '212 555-1234'
            type = 'home'
        },
        @{
            number = '646 555-4567'
            type = 'office'
        }
    )
    children = @(
        'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = @{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234'; type = 'home' },
        @{ number = '646 555-4567'; type = 'office' }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton -ExpandDepth 2' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton -ExpandDepth 2
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = @{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234'; type = 'home' },
        @{ number = '646 555-4567'; type = 'office' }
    )
    children = @(
        'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = @{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }
    phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton -ExpandDepth 1' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton -ExpandDepth 1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = @{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }
    phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = @{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = @{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234';type='home' }, @{ number='646 555-4567';type='office' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234';type='home' }, @{ number='646 555-4567';type='office' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [PSCustomObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{
            number = '212 555-1234'
            type = 'home'
        },
        @{
            number = '646 555-4567'
            type = 'office'
        }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [System.Management.Automation.PSObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{
            number = '212 555-1234'
            type = 'home'
        },
        @{
            number = '646 555-4567'
            type = 'office'
        }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [PSCustomObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{
            number = '212 555-1234'
            type = 'home'
        },
        @{
            number = '646 555-4567'
            type = 'office'
        }
    )
    children = @(
        'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [System.Management.Automation.PSObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{
            number = '212 555-1234'
            type = 'home'
        },
        @{
            number = '646 555-4567'
            type = 'office'
        }
    )
    children = @(
        'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandDepth 2' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandDepth 2
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [PSCustomObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234'; type = 'home' },
        @{ number = '646 555-4567'; type = 'office' }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [System.Management.Automation.PSObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234'; type = 'home' },
        @{ number = '646 555-4567'; type = 'office' }
    )
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [PSCustomObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234'; type = 'home' },
        @{ number = '646 555-4567'; type = 'office' }
    )
    children = @(
        'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [System.Management.Automation.PSObject]@{
        street_address = '21 2nd Street'
        city = 'New York'
        state = 'NY'
        postal_code = '10021-3100'
    }
    phone_numbers = @(
        @{ number = '212 555-1234'; type = 'home' },
        @{ number = '646 555-4567'; type = 'office' }
    )
    children = @(
        'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandDepth 1' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandDepth 1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [PSCustomObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }
    phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [System.Management.Automation.PSObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }
    phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [PSCustomObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }
    phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = 'John'
    last_name = 'Smith'
    is_alive = $True
    age = 27
    address = [System.Management.Automation.PSObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }
    phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [PSCustomObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [System.Management.Automation.PSObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [PSCustomObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [System.Management.Automation.PSObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234'; type = 'home' }, @{ number = '646 555-4567'; type = 'office' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[PSCustomObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234';type='home' }, @{ number='646 555-4567';type='office' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[System.Management.Automation.PSObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234';type='home' }, @{ number='646 555-4567';type='office' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[PSCustomObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234';type='home' }, @{ number='646 555-4567';type='office' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[System.Management.Automation.PSObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234';type='home' }, @{ number='646 555-4567';type='office' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{
            number = [string]'212 555-1234'
            type = [string]'home'
        },
        [hashtable]@{
            number = [string]'646 555-4567'
            type = [string]'office'
        }
    )
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{
            number = [System.String]'212 555-1234'
            type = [System.String]'home'
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
            type = [System.String]'office'
        }
    )
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{
            number = [string]'212 555-1234'
            type = [string]'home'
        },
        [hashtable]@{
            number = [string]'646 555-4567'
            type = [string]'office'
        }
    )
    children = [array]@(
        [string]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{
            number = [System.String]'212 555-1234'
            type = [System.String]'home'
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
            type = [System.String]'office'
        }
    )
    children = [System.Object[]]@(
        [System.String]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' },
        [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }
    )
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 2 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 2 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }
    )
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' },
        [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }
    )
    children = [array]@(
        [string]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 2 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }
    )
    children = [System.Object[]]@(
        [System.String]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' })
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 1 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 1 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' })
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 1 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234';type=[string]'home' }, [hashtable]@{ number=[string]'646 555-4567';type=[string]'office' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234';type=[System.String]'home' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567';type=[System.String]'office' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234';type=[string]'home' }, [hashtable]@{ number=[string]'646 555-4567';type=[string]'office' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234';type=[System.String]'home' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567';type=[System.String]'office' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{
            number = [string]'212 555-1234'
            type = [string]'home'
        },
        [hashtable]@{
            number = [string]'646 555-4567'
            type = [string]'office'
        }
    )
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{
            number = [System.String]'212 555-1234'
            type = [System.String]'home'
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
            type = [System.String]'office'
        }
    )
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{
            number = [string]'212 555-1234'
            type = [string]'home'
        },
        [hashtable]@{
            number = [string]'646 555-4567'
            type = [string]'office'
        }
    )
    children = [array]@(
        [string]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{
            number = [System.String]'212 555-1234'
            type = [System.String]'home'
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
            type = [System.String]'office'
        }
    )
    children = [System.Object[]]@(
        [System.String]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandDepth 2' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandDepth 2
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' },
        [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }
    )
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }
    )
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' },
        [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }
    )
    children = [array]@(
        [string]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }
    )
    children = [System.Object[]]@(
        [System.String]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandDepth 1' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandDepth 1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' })
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' })
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234';type=[string]'home' }, [hashtable]@{ number=[string]'646 555-4567';type=[string]'office' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234';type=[System.String]'home' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567';type=[System.String]'office' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234';type=[string]'home' }, [hashtable]@{ number=[string]'646 555-4567';type=[string]'office' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234';type=[System.String]'home' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567';type=[System.String]'office' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{
            number = [string]'212 555-1234'
            type = [string]'home'
        },
        [hashtable]@{
            number = [string]'646 555-4567'
            type = [string]'office'
        }
    )
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{
            number = [System.String]'212 555-1234'
            type = [System.String]'home'
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
            type = [System.String]'office'
        }
    )
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{
            number = [string]'212 555-1234'
            type = [string]'home'
        },
        [hashtable]@{
            number = [string]'646 555-4567'
            type = [string]'office'
        }
    )
    children = [array]@(
        [string]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{
            number = [System.String]'212 555-1234'
            type = [System.String]'home'
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
            type = [System.String]'office'
        }
    )
    children = [System.Object[]]@(
        [System.String]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' },
        [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }
    )
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 2 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 2 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }
    )
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 2 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 2 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{
        street_address = [string]'21 2nd Street'
        city = [string]'New York'
        state = [string]'NY'
        postal_code = [string]'10021-3100'
    }
    phone_numbers = [array]@(
        [hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' },
        [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }
    )
    children = [array]@(
        [string]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 2 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 2 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{
        street_address = [System.String]'21 2nd Street'
        city = [System.String]'New York'
        state = [System.String]'NY'
        postal_code = [System.String]'10021-3100'
    }
    phone_numbers = [System.Object[]]@(
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }
    )
    children = [System.Object[]]@(
        [System.String]'Catherine'
    )
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' })
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 1 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 1 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 1 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 1 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{
    first_name = [string]'John'
    last_name = [string]'Smith'
    is_alive = [bool]$True
    age = [int]27
    address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' })
    children = [array]@([string]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 1 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 1 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{
    first_name = [System.String]'John'
    last_name = [System.String]'Smith'
    is_alive = [System.Boolean]$True
    age = [System.Int32]27
    address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234'; type = [string]'home' }, [hashtable]@{ number = [string]'646 555-4567'; type = [string]'office' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234'; type = [System.String]'home' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567'; type = [System.String]'office' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234';type=[string]'home' }, [hashtable]@{ number=[string]'646 555-4567';type=[string]'office' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234';type=[System.String]'home' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567';type=[System.String]'office' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234';type=[string]'home' }, [hashtable]@{ number=[string]'646 555-4567';type=[string]'office' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234';type=[System.String]'home' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567';type=[System.String]'office' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
    }

    Context 'Issues' {

        It '#59 quoting bug' {
            @{ Test = "foo'bar" } | ConvertTo-Expression | Should -Be "@{ Test = 'foo''bar' }"
        }
    }
}