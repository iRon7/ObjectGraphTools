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
            $Object = [adsi]'WinNT://WORKGROUP/./Administrator'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[adsi]'WinNT://WORKGROUP/./Administrator'"
        }

        It 'adsisearcher' {
            $Object = [adsisearcher]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[adsisearcher]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[adsisearcher]'0123'"
        }

        It 'Alias' {
            $Object = [Alias]::new('Example')
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@('Example')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[Alias]::new('Example')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[Alias]::new('Example')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[Alias]::new('Example')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[Alias]::new('Example')"
        }

        It 'AllowEmptyCollection' {
            $Object = [AllowEmptyCollection]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[AllowEmptyCollection]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[AllowEmptyCollection]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[AllowEmptyCollection]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[AllowEmptyCollection]::new()"
        }

        It 'AllowEmptyString' {
            $Object = [AllowEmptyString]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[AllowEmptyString]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[AllowEmptyString]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[AllowEmptyString]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[AllowEmptyString]::new()"
        }

        It 'AllowNull' {
            $Object = [AllowNull]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[AllowNull]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[AllowNull]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[AllowNull]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[AllowNull]::new()"
        }

        It 'ArgumentCompleter' {
            $Object = [ArgumentCompleter]{'Example'}
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "{'Example'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ArgumentCompleter]{'Example'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ArgumentCompleter]{'Example'}"
        }

        It 'bigint' {
            $Object = [bigint]'1234567890'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'1234567890'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[bigint]'1234567890'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[bigint]'1234567890'"
        }

        It 'bool' {
            $Object = [bool]$True
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be '$True'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be '$True'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be '[bool]$True'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be '[bool]$True'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be '[bool]$True'
        }

        It 'byte' {
            $Object = [byte]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[byte]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[byte]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[byte]123"
        }

        It 'char' {
            $Object = [char]'a'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'a'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "'a'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[char]'a'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[char]'a'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[char]'a'"
        }

        It 'ciminstance' {
            $Object = [ciminstance]'Example'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'Example'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ciminstance]'Example'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ciminstance]'Example'"
        }

        It 'CimSession' {
            $Object = [CimSession]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[CimSession]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[CimSession]'0123'"
        }

        It 'cimtype' {
            $Object = [cimtype]'Boolean'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'Boolean'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[cimtype]'Boolean'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[cimtype]'Boolean'"
        }

        # It 'CmdletBinding' {
        #     $Object = [CmdletBinding]@{ PositionalBinding = [bool]$True; DefaultParameterSetName = [string]''; SupportsShouldProcess = [bool]$False; SupportsPaging = [bool]$False; SupportsTransactions = [bool]$False; ConfirmImpact = [System.Management.Automation.ConfirmImpact]'None'; HelpUri = [string]''; RemotingCapability = [System.Management.Automation.RemotingCapability]'None' }
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be '@{ PositionalBinding = $True; DefaultParameterSetName = ''; SupportsShouldProcess = $False; SupportsPaging = $False; SupportsTransactions = $False; ConfirmImpact = 'None'; HelpUri = ''; RemotingCapability = 'None' }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be '[CmdletBinding]@{ PositionalBinding = $True; DefaultParameterSetName = ''; SupportsShouldProcess = $False; SupportsPaging = $False; SupportsTransactions = $False; ConfirmImpact = [System.Management.Automation.ConfirmImpact]'None'; HelpUri = ''; RemotingCapability = [System.Management.Automation.RemotingCapability]'None' }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be '[CmdletBinding]@{ PositionalBinding = [bool]$True; DefaultParameterSetName = [string]''; SupportsShouldProcess = [bool]$False; SupportsPaging = [bool]$False; SupportsTransactions = [bool]$False; ConfirmImpact = [System.Management.Automation.ConfirmImpact]'None'; HelpUri = [string]''; RemotingCapability = [System.Management.Automation.RemotingCapability]'None' }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be '[CmdletBinding]@{ PositionalBinding = [bool]$True; DefaultParameterSetName = [string]''; SupportsShouldProcess = [bool]$False; SupportsPaging = [bool]$False; SupportsTransactions = [bool]$False; ConfirmImpact = [System.Management.Automation.ConfirmImpact]'None'; HelpUri = [string]''; RemotingCapability = [System.Management.Automation.RemotingCapability]'None' }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be '[CmdletBinding]@{ PositionalBinding = [bool]$True; DefaultParameterSetName = [string]''; SupportsShouldProcess = [bool]$False; SupportsPaging = [bool]$False; SupportsTransactions = [bool]$False; ConfirmImpact = [System.Management.Automation.ConfirmImpact]'None'; HelpUri = [string]''; RemotingCapability = [System.Management.Automation.RemotingCapability]'None' }'
        # }

        It 'cultureinfo' {
            $Object = [cultureinfo]'en-US'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'en-US'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[cultureinfo]'en-US'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[cultureinfo]'en-US'"
        }

        It 'datetime' {
            $Object = [datetime]'1963-10-07T17:56:53.8139055'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[datetime]'1963-10-07T17:56:53.8139055'"
        }

        It 'decimal' {
            $Object = [decimal]'0.123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0.123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[decimal]'0.123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[decimal]'0.123'"
        }

        It 'double' {
            $Object = [double]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[double]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[double]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[double]123"
        }

        It 'DscLocalConfigurationManager' {
            $Object = [DscLocalConfigurationManager]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[DscLocalConfigurationManager]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[DscLocalConfigurationManager]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[DscLocalConfigurationManager]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[DscLocalConfigurationManager]::new()"
        }

        It 'DscProperty' {
            $Object = [DscProperty]@{ Key = [bool]$False; Mandatory = [bool]$False; NotConfigurable = [bool]$False }
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be '@{ Key = $False; Mandatory = $False; NotConfigurable = $False }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be '[DscProperty]@{ Key = $False; Mandatory = $False; NotConfigurable = $False }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be '[DscProperty]@{ Key = [bool]$False; Mandatory = [bool]$False; NotConfigurable = [bool]$False }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be '[DscProperty]@{ Key = [bool]$False; Mandatory = [bool]$False; NotConfigurable = [bool]$False }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be '[DscProperty]@{ Key = [bool]$False; Mandatory = [bool]$False; NotConfigurable = [bool]$False }'
        }

        It 'DscResource' {
            $Object = [DscResource]@{ RunAsCredential = [System.Management.Automation.DSCResourceRunAsCredential]'Default' }
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{ RunAsCredential = 'Default' }"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[DscResource]@{ RunAsCredential = [System.Management.Automation.DSCResourceRunAsCredential]'Default' }"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[DscResource]@{ RunAsCredential = [System.Management.Automation.DSCResourceRunAsCredential]'Default' }"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[DscResource]@{ RunAsCredential = [System.Management.Automation.DSCResourceRunAsCredential]'Default' }"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[DscResource]@{ RunAsCredential = [System.Management.Automation.DSCResourceRunAsCredential]'Default' }"
        }

        It 'ExperimentAction' -Skip:(-not ('ExperimentAction' -as [Type])) {
            $Object = [ExperimentAction]'None'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'None'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ExperimentAction]'None'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ExperimentAction]'None'"
        }

        It 'float' {
            $Object = [float]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[float]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[float]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[float]123"
        }

        It 'guid' {
            $Object = [guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[guid]'19631007-bd7b-41cc-a6c7-bb1772d6ef46'"
        }

        It 'int' {
            $Object = [int]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[int]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[int]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[int]123"
        }

        It 'short' -Skip:(-not ('short' -as [Type])) {
            $Object = [short]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[short]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[short]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[short]123"
        }

        It 'long' {
            $Object = [long]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[long]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[long]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[long]123"
        }

        It 'ipaddress' {
            $Object = [ipaddress]'198.168.1.1'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ipaddress]'198.168.1.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ipaddress]'198.168.1.1'"
        }

        It 'IPEndpoint' {
            $Object = [IPEndpoint]::new(16885958, 123)
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[IPEndpoint]::new(16885958, 123)"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[IPEndpoint]::new(16885958, 123)"
        }

        It 'mailaddress' {
            $Object = [mailaddress]'iron@contoso.com'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[mailaddress]'iron@contoso.com'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[mailaddress]'iron@contoso.com'"
        }

        It 'Microsoft.PowerShell.Commands.ModuleSpecification' {
            $Object = [Microsoft.PowerShell.Commands.ModuleSpecification]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[Microsoft.PowerShell.Commands.ModuleSpecification]'0123'"
        }

        It 'NoRunspaceAffinity' -Skip:(-not ('NoRunspaceAffinity' -as [Type])) {
            $Object = [NoRunspaceAffinity]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[NoRunspaceAffinity]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[NoRunspaceAffinity]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[NoRunspaceAffinity]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[NoRunspaceAffinity]::new()"
        }

        It 'OutputType' {
            $Object = [OutputType]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[OutputType]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[OutputType]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[OutputType]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[OutputType]::new()"
        }

        # It 'Parameter' {
        #     $Object = [Parameter]@{ Position = [int]1 }
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be '@{ ExperimentName = $Null; ExperimentAction = 'None'; Position = 1; ParameterSetName = '__AllParameterSets'; Mandatory = $False; ValueFromPipeline = $False; ValueFromPipelineByPropertyName = $False; ValueFromRemainingArguments = $False; HelpMessage = $Null; HelpMessageBaseName = $Null; HelpMessageResourceId = $Null; DontShow = $False }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be '[Parameter]@{ ExperimentName = $Null; ExperimentAction = [ExperimentAction]'None'; Position = 1; ParameterSetName = '__AllParameterSets'; Mandatory = $False; ValueFromPipeline = $False; ValueFromPipelineByPropertyName = $False; ValueFromRemainingArguments = $False; HelpMessage = $Null; HelpMessageBaseName = $Null; HelpMessageResourceId = $Null; DontShow = $False }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be '[Parameter]@{ ExperimentName = $Null; ExperimentAction = [ExperimentAction]'None'; Position = [int]1; ParameterSetName = [string]'__AllParameterSets'; Mandatory = [bool]$False; ValueFromPipeline = [bool]$False; ValueFromPipelineByPropertyName = [bool]$False; ValueFromRemainingArguments = [bool]$False; HelpMessage = $Null; HelpMessageBaseName = $Null; HelpMessageResourceId = $Null; DontShow = [bool]$False }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be '[Parameter]@{ ExperimentName = $Null; ExperimentAction = [ExperimentAction]'None'; Position = [int]1; ParameterSetName = [string]'__AllParameterSets'; Mandatory = [bool]$False; ValueFromPipeline = [bool]$False; ValueFromPipelineByPropertyName = [bool]$False; ValueFromRemainingArguments = [bool]$False; HelpMessage = $Null; HelpMessageBaseName = $Null; HelpMessageResourceId = $Null; DontShow = [bool]$False }'
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be '[Parameter]@{ ExperimentName = $Null; ExperimentAction = [ExperimentAction]'None'; Position = [int]1; ParameterSetName = [string]'__AllParameterSets'; Mandatory = [bool]$False; ValueFromPipeline = [bool]$False; ValueFromPipelineByPropertyName = [bool]$False; ValueFromRemainingArguments = [bool]$False; HelpMessage = $Null; HelpMessageBaseName = $Null; HelpMessageResourceId = $Null; DontShow = [bool]$False }'
        # }

        It 'PhysicalAddress' {
            $Object = [PhysicalAddress]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[PhysicalAddress]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[PhysicalAddress]'0123'"
        }

        It 'PSDefaultValue' {
            $Object = [PSDefaultValue]@{ Value = $Null; Help = [string]'' }
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be '@{ Value = $Null; Help = '''' }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be '[PSDefaultValue]@{ Value = $Null; Help = '''' }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be '[PSDefaultValue]@{ Value = $Null; Help = [string]'''' }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be '[PSDefaultValue]@{ Value = $Null; Help = [string]'''' }'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be '[PSDefaultValue]@{ Value = $Null; Help = [string]'''' }'
        }

        It 'pslistmodifier' {
            $Object = [pslistmodifier]''
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[pslistmodifier]''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[pslistmodifier]''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[pslistmodifier]''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[pslistmodifier]''"
        }

        It 'PSTypeNameAttribute' {
            $Object = [PSTypeNameAttribute]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[PSTypeNameAttribute]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[PSTypeNameAttribute]'0123'"
        }

        It 'regex' {
            $Object = [regex]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[regex]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[regex]'0123'"
        }

        It 'sbyte' {
            $Object = [sbyte]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[sbyte]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[sbyte]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[sbyte]123"
        }

        It 'semver' -Skip:(-not ('semver' -as [Type])) {
            $Object = [semver]'1.2.0-a.1'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[semver]'1.2.0-a.1'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[semver]'1.2.0-a.1'"
        }

        It 'string' {
            $Object = [string]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[string]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[string]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[string]'0123'"
        }

        It 'SupportsWildcards' {
            $Object = [SupportsWildcards]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[SupportsWildcards]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[SupportsWildcards]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[SupportsWildcards]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[SupportsWildcards]::new()"
        }

        It 'timespan' {
            $Object = [timespan]'1.02:03:04.0050000'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[timespan]'1.02:03:04.0050000'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[timespan]'1.02:03:04.0050000'"
        }

        It 'ushort' -Skip:(-not ('ushort' -as [Type])) {
            $Object = [ushort]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ushort]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ushort]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ushort]123"
        }

        It 'uint' -Skip:(-not ('uint' -as [Type])) {
            $Object = [uint]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[uint]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[uint]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[uint]123"
        }

        It 'ulong' -Skip:(-not ('ulong' -as [Type])) {
            $Object = [ulong]123
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ulong]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ulong]123"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ulong]123"
        }

        It 'uri' {
            $Object = [uri]'0123'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[uri]'0123'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[uri]'0123'"
        }

        # It 'ValidateDrive' {
        #     $Object = [ValidateDrive]::new()
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{ ValidRootDrives = @() }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateDrive]@{ ValidRootDrives = @() }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateDrive]@{ ValidRootDrives = [string[]]@() }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateDrive]@{ ValidRootDrives = [string[]]@() }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateDrive]@{ ValidRootDrives = [string[]]@() }"
        # }

        It 'ValidateNotNull' {
            $Object = [ValidateNotNull]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateNotNull]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateNotNull]::new()"
        }

        It 'ValidateNotNullOrEmpty' {
            $Object = [ValidateNotNullOrEmpty]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateNotNullOrEmpty]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateNotNullOrEmpty]::new()"
        }

        It 'ValidateNotNullOrWhiteSpace' -Skip:(-not ('ValidateNotNullOrWhiteSpace' -as [Type])) {
            $Object = [ValidateNotNullOrWhiteSpace]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateNotNullOrWhiteSpace]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateNotNullOrWhiteSpace]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateNotNullOrWhiteSpace]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateNotNullOrWhiteSpace]::new()"
        }

        It 'ValidatePattern' {
            $Object = [ValidatePattern]'Pattern'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'Pattern'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidatePattern]'Pattern'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidatePattern]'Pattern'"
        }

        It 'ValidateScript' {
            $Object = [ValidateScript]{'Validate'}
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "{'Validate'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateScript]{'Validate'}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateScript]{'Validate'}"
        }

        It 'ValidateSet' {
            $Object = [ValidateSet]::new('Value1', 'Value2')
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateSet]::new('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateSet]::new('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateSet]::new('Value1', 'Value2')"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateSet]::new('Value1', 'Value2')"
        }

        It 'ValidateTrustedData' {
            $Object = [ValidateTrustedData]::new()
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{}"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateTrustedData]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateTrustedData]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateTrustedData]::new()"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateTrustedData]::new()"
        }

        # It 'ValidateUserDrive' {
        #     $Object = [ValidateUserDrive]::new()
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "@{ ValidRootDrives = @('User') }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[ValidateUserDrive]@{ ValidRootDrives = @('User') }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[ValidateUserDrive]@{ ValidRootDrives = [string[]]@([string]'User') }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[ValidateUserDrive]@{ ValidRootDrives = [string[]]@([string]'User') }"
        #     ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[ValidateUserDrive]@{ ValidRootDrives = [string[]]@([string]'User') }"
        # }

        It 'version' {
            $Object = [version]'0.1.2.3'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[version]'0.1.2.3'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[version]'0.1.2.3'"
        }

        It 'WildcardPattern' {
            $Object = [WildcardPattern]'_T?e%s*t'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[WildcardPattern]'_T?e%s*t'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[WildcardPattern]'_T?e%s*t'"
        }

        It 'wmi' {
            $Object = [wmi]''
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[wmi]''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[wmi]''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[wmi]''"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[wmi]''"
        }

        It 'wmiclass' {
            $Object = [wmiclass]'\\LAP70223274\ROOT\Cimv2:Win32_BIOS'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[wmiclass]'\\$($Env:ComputerName)\ROOT\Cimv2:Win32_BIOS'"
        }

        It 'wmisearcher' {
            $Object = [wmisearcher]'QueryString'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'QueryString'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[wmisearcher]'QueryString'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[wmisearcher]'QueryString'"
        }

        It 'X500DistinguishedName' {
            $Object = [X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 | Should -Be "'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
            ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit | Should -Be "[X500DistinguishedName]'CN=123,OID.0.9.2342.19200300.100.1.1=321'"
        }

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
                    @{ number = '212 555-1234' },
                    @{ number = '646 555-4567' }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        },
        @{
            number = '646 555-4567'
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
    phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' })
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
    phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = @{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = @{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{number='212 555-1234' }, @{number='646 555-4567' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandSingleton -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandSingleton -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234' }, @{ number='646 555-4567' });children=@('Catherine');spouse=$Null }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        },
        @{
            number = '646 555-4567'
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
        },
        @{
            number = '646 555-4567'
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
        @{ number = '212 555-1234' },
        @{ number = '646 555-4567' }
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
    phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' })
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
    phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' })
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
    phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' })
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
    phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' })
    children = @('Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [PSCustomObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [System.Management.Automation.PSObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [PSCustomObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = 'John'; last_name = 'Smith'; is_alive = $True; age = 27; address = [System.Management.Automation.PSObject]@{ street_address = '21 2nd Street'; city = 'New York'; state = 'NY'; postal_code = '10021-3100' }; phone_numbers = @(@{ number = '212 555-1234' }, @{ number = '646 555-4567' }); children = @('Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Constrained -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Constrained -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[PSCustomObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{number='212 555-1234' }, @{number='646 555-4567' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[System.Management.Automation.PSObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{number='212 555-1234' }, @{number='646 555-4567' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[PSCustomObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234' }, @{ number='646 555-4567' });children=@('Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name='John';last_name='Smith';is_alive=$True;age=27;address=[System.Management.Automation.PSObject]@{ street_address='21 2nd Street';city='New York';state='NY';postal_code='10021-3100' };phone_numbers=@(@{ number='212 555-1234' }, @{ number='646 555-4567' });children=@('Catherine');spouse=$Null }
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
        },
        [hashtable]@{
            number = [string]'646 555-4567'
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
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' })
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
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' })
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
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' })
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
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{number=[string]'212 555-1234' }, [hashtable]@{number=[string]'646 555-4567' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{number=[System.String]'212 555-1234' }, [System.Collections.Hashtable]@{number=[System.String]'646 555-4567' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234' }, [hashtable]@{ number=[string]'646 555-4567' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Constrained -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
        },
        [hashtable]@{
            number = [string]'646 555-4567'
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
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' })
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
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' })
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
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' })
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
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandDepth 0' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandDepth 0
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -LanguageMode Full -ExpandDepth -1' {
            $Expression = ConvertTo-Expression -InputObject $Object -LanguageMode Full -ExpandDepth -1
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{number=[string]'212 555-1234' }, [hashtable]@{number=[string]'646 555-4567' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{number=[System.String]'212 555-1234' }, [System.Collections.Hashtable]@{number=[System.String]'646 555-4567' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -ExpandSingleton' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -ExpandSingleton
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234' }, [hashtable]@{ number=[string]'646 555-4567' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -FullTypeName' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -FullTypeName
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
        },
        [hashtable]@{
            number = [string]'646 555-4567'
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
        },
        [System.Collections.Hashtable]@{
            number = [System.String]'646 555-4567'
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
        [hashtable]@{ number = [string]'212 555-1234' },
        [hashtable]@{ number = [string]'646 555-4567' }
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
        [System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' },
        [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }
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
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' })
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
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' })
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
    phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' })
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
    phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' })
    children = [System.Object[]]@([System.String]'Catherine')
    spouse = $Null
}
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name = [string]'John'; last_name = [string]'Smith'; is_alive = [bool]$True; age = [int]27; address = [PSCustomObject]@{ street_address = [string]'21 2nd Street'; city = [string]'New York'; state = [string]'NY'; postal_code = [string]'10021-3100' }; phone_numbers = [array]@([hashtable]@{ number = [string]'212 555-1234' }, [hashtable]@{ number = [string]'646 555-4567' }); children = [array]@([string]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth 0 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name = [System.String]'John'; last_name = [System.String]'Smith'; is_alive = [System.Boolean]$True; age = [System.Int32]27; address = [System.Management.Automation.PSObject]@{ street_address = [System.String]'21 2nd Street'; city = [System.String]'New York'; state = [System.String]'NY'; postal_code = [System.String]'10021-3100' }; phone_numbers = [System.Object[]]@([System.Collections.Hashtable]@{ number = [System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number = [System.String]'646 555-4567' }); children = [System.Object[]]@([System.String]'Catherine'); spouse = $Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{number=[string]'212 555-1234' }, [hashtable]@{number=[string]'646 555-4567' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Full -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Full -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{number=[System.String]'212 555-1234' }, [System.Collections.Hashtable]@{number=[System.String]'646 555-4567' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[PSCustomObject]@{ first_name=[string]'John';last_name=[string]'Smith';is_alive=[bool]$True;age=[int]27;address=[PSCustomObject]@{ street_address=[string]'21 2nd Street';city=[string]'New York';state=[string]'NY';postal_code=[string]'10021-3100' };phone_numbers=[array]@([hashtable]@{ number=[string]'212 555-1234' }, [hashtable]@{ number=[string]'646 555-4567' });children=[array]@([string]'Catherine');spouse=$Null }
'@
        }
        It 'ConvertTo-Expression -FullTypeName -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit' {
            $Expression = ConvertTo-Expression -InputObject $Object -FullTypeName -ExpandDepth -1 -LanguageMode Full -ExpandSingleton -Explicit
            { Invoke-Expression $Expression } | Should -not -Throw
            $Expression | Should -Be @'
[System.Management.Automation.PSObject]@{ first_name=[System.String]'John';last_name=[System.String]'Smith';is_alive=[System.Boolean]$True;age=[System.Int32]27;address=[System.Management.Automation.PSObject]@{ street_address=[System.String]'21 2nd Street';city=[System.String]'New York';state=[System.String]'NY';postal_code=[System.String]'10021-3100' };phone_numbers=[System.Object[]]@([System.Collections.Hashtable]@{ number=[System.String]'212 555-1234' }, [System.Collections.Hashtable]@{ number=[System.String]'646 555-4567' });children=[System.Object[]]@([System.String]'Catherine');spouse=$Null }
'@
        }
    }

    Context 'Issues' {

        It '#59 quoting bug' {
            @{ Test = "foo'bar" } | ConvertTo-Expression | Should -Be "@{ Test = 'foo''bar' }"
        }
    }
}