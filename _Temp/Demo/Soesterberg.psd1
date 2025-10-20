@{
    AllNodes    = @(
        @{
            NodeName        = 'localhost'
            CertificateFile = '.\DSCCertificate.cer'
        }
    )
    NonNodeData = @{
        Environment    = @{
            Name             = 'soesterberg'
            ShortName        = 'SSB'
            TenantId         = 'soesterberg.onmicrosoft.com'
            OrganizationName = 'soesterberg'
        }
        Accounts = @{}
        AppCredentials = @(
            @{
                Workload       = 'Exchange'
                ApplicationId  = 'c073960f-846b-4cb7-9249-a01eeda3a1b6'
                CertThumbprint = '65E427769F27CDA198231B2A7FF03940897FB687'
            }
            @{
                Workload       = 'Intune'
                ApplicationId  = 'c073960f-846b-4cb7-9249-a01eeda3a1b6'
                CertThumbprint = '65E427769F27CDA198231B2A7FF03940897FB687'
            }
            @{
                Workload       = 'Office365'
                ApplicationId  = 'c073960f-846b-4cb7-9249-a01eeda3a1b6'
                CertThumbprint = '65E427769F27CDA198231B2A7FF03940897FB687'
            }
            @{
                Workload       = 'SharePoint'
                ApplicationId  = 'c073960f-846b-4cb7-9249-a01eeda3a1b6'
                CertThumbprint = '65E427769F27CDA198231B2A7FF03940897FB687'
            }
            @{
                Workload       = 'Teams'
                ApplicationId  = 'c073960f-846b-4cb7-9249-a01eeda3a1b6'
                CertThumbprint = '65E427769F27CDA198231B2A7FF03940897FB687'
            }
        )
        AAD            = @{
            AuthenticationMethodPoliciesFido2 = @(
                @{
                    IncludeTargets = @(
                        @{
                            Id       = 'GRP-99100z99-SEC-ROL-WindowsHelloforBusiness'
                            UniqueID = 'UniqueFido'
                            #TargetType = 'String | Optional | user / group / unknownFutureValue'
                        }
                    )
                }
            )
            ConditionalAccessPolicies         = @(
                @{
                    UniqueID                             = 'IosAndroidAccessBrowserUnmanaged'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @('grp-99100z99-rol-g-MobileMAM')
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('android', 'iOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @()
                }
                @{
                    UniqueID                             = 'IosAndroidAccessBrowsermanagedLowrisk'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @('grp-99100z99-rol-g-MobileMAM')
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('android', 'iOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'IosAndroidAccessAppsUnmanaged'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c', 'fc780465-2017-40d4-a0c5-307022471b92')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @('grp-99100z99-rol-g-MobileMAM')
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('android', 'iOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @()
                }
                @{
                    UniqueID                             = 'IosAndroidAccessAppsmanagedlowRisk'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @()
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('windows')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')

                }
                @{
                    UniqueID                             = 'Windows10dAccessBrowsermanagedLowrisk'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @('grp-99100z99-SEC-ROL-Beheerder')
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @('Application Administrator', 'Application Developer', 'Attack Payload Author', 'Attack Simulation Administrator', 'Attribute Assignment Administrator', 'Attribute Assignment Reader', 'Attribute Definition Administrator', 'Attribute Definition Reader', 'Authentication Administrator', 'Authentication Policy Administrator', 'Azure AD Joined Device Local Administrator', 'Azure DevOps Administrator', 'Azure Information Protection Administrator', 'B2C IEF Keyset Administrator', 'B2C IEF Policy Administrator', 'Billing Administrator', 'Cloud App Security Administrator', 'Cloud Application Administrator', 'Cloud Device Administrator', 'Compliance Administrator', 'Compliance Data Administrator', 'Conditional Access Administrator', 'Desktop Analytics Administrator', 'Directory Readers', 'Directory Synchronization Accounts', 'Directory Writers', 'Domain Name Administrator', 'Dynamics 365 Administrator', 'Edge Administrator', 'Exchange Administrator', 'Exchange Recipient Administrator', 'External ID User Flow Administrator', 'External ID User Flow Attribute Administrator', 'External Identity Provider Administrator', 'Global Administrator', 'Global Reader', 'Groups Administrator', 'Guest Inviter', 'Hybrid Identity Administrator', 'Helpdesk Administrator', 'Identity Governance Administrator', 'Insights Administrator', 'Insights Business Leader', 'Intune Administrator', 'Kaizala Administrator', 'Knowledge Administrator', 'Knowledge Manager', 'License Administrator', 'Message Center Privacy Reader', 'Message Center Reader', 'Network Administrator', 'Office Apps Administrator', 'Password Administrator', 'Fabric Administrator', 'Power Platform Administrator', 'Printer Administrator', 'Printer Technician', 'Privileged Authentication Administrator', 'Privileged Role Administrator', 'Reports Reader', 'Search Administrator', 'Search Editor', 'Security Operator', 'Security Administrator', 'Security Reader', 'Service Support Administrator', 'SharePoint Administrator', 'Skype for Business Administrator', 'Teams Administrator', 'Teams Communications Administrator', 'Teams Communications Support Engineer', 'Teams Communications Support Specialist', 'Teams Devices Administrator', 'Usage Summary Reports Reader', 'User Administrator', 'Windows 365 Administrator', 'Windows Update Deployment Administrator', 'Virtual Visits Administrator', 'Insights Analyst', 'Lifecycle Workflows Administrator', 'Permissions Management Administrator', 'Yammer Administrator', 'Customer LockBox Access Approver', 'Microsoft Hardware Warranty Administrator', 'Microsoft Hardware Warranty Specialist', 'Organizational Messages Writer', 'Tenant Creator', 'User Experience Success Manager', 'Authentication Extensibility Administrator', 'Viva Goals Administrator')
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('windows')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'GeneralBlockUnsupported'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @('android', 'iOS', 'windows', 'macOS')
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @('Azure-Atos@frs99100.onmicrosoft.com', 'azure-frs99100@frs99100.onmicrosoft.com')
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('all')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'MacOSAppsLowRiskAccess'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @()
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('macOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'MFAPolicy'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @()
                    IncludeRoles                         = @('Application Administrator', 'Application Developer', 'Attack Payload Author', 'Attack Simulation Administrator', 'Attribute Assignment Administrator', 'Attribute Assignment Reader', 'Attribute Definition Administrator', 'Attribute Definition Reader', 'Authentication Administrator', 'Authentication Policy Administrator', 'Azure AD Joined Device Local Administrator', 'Azure DevOps Administrator', 'Azure Information Protection Administrator', 'B2C IEF Keyset Administrator', 'B2C IEF Policy Administrator', 'Billing Administrator', 'Cloud App Security Administrator', 'Cloud Application Administrator', 'Cloud Device Administrator', 'Compliance Administrator', 'Compliance Data Administrator', 'Conditional Access Administrator', 'Desktop Analytics Administrator', 'Directory Readers', 'Directory Synchronization Accounts', 'Directory Writers', 'Domain Name Administrator', 'Dynamics 365 Administrator', 'Edge Administrator', 'Exchange Administrator', 'Exchange Recipient Administrator', 'External ID User Flow Administrator', 'External ID User Flow Attribute Administrator', 'External Identity Provider Administrator', 'Global Administrator', 'Global Reader', 'Groups Administrator', 'Guest Inviter', 'Helpdesk Administrator', 'Hybrid Identity Administrator', 'Identity Governance Administrator', 'Insights Administrator', 'Insights Business Leader', 'Intune Administrator', 'Kaizala Administrator', 'Knowledge Administrator', 'Knowledge Manager', 'License Administrator', 'Message Center Privacy Reader', 'Message Center Reader', 'Network Administrator', 'Office Apps Administrator', 'Password Administrator', 'Fabric Administrator', 'Power Platform Administrator', 'Printer Administrator', 'Printer Technician', 'Privileged Authentication Administrator', 'Privileged Role Administrator', 'Reports Reader', 'Search Administrator', 'Search Editor', 'Security Administrator', 'Security Operator', 'Security Reader', 'Service Support Administrator', 'SharePoint Administrator', 'Teams Administrator', 'Teams Communications Administrator', 'Teams Communications Support Engineer', 'Skype for Business Administrator', 'Teams Communications Support Specialist', 'Teams Devices Administrator', 'Usage Summary Reports Reader', 'User Administrator', 'Windows 365 Administrator', 'Windows Update Deployment Administrator', 'Virtual Visits Administrator', 'Insights Analyst', 'Lifecycle Workflows Administrator', 'Permissions Management Administrator', 'Yammer Administrator', 'Organizational Messages Writer', 'Tenant Creator', 'Authentication Extensibility Administrator', 'User Experience Success Manager', 'Viva Goals Administrator', 'Microsoft Hardware Warranty Administrator', 'Microsoft Hardware Warranty Specialist', 'Global Secure Access Administrator', 'Extended Directory User Administrator')
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @()
                }
                @{
                    UniqueID                             = 'MacOSAccessBrowser'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @()
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('macOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')

                }
                @{
                    UniqueID                             = 'IosAndroidAppsManagedLowSign'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @('grp-99100z99-rol-g-MobileMAM')
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('android', 'iOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'GuestAccessID'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = 'all'
                    IncludeGroups                        = @()
                    IncludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'serviceProvider')
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('all')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @()
                }
                @{
                    UniqueID                             = 'BreaktheGlass'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @('Nederland')
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @('All')
                    IncludePlatforms                     = @()
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('Azure-Atos@frs99100.onmicrosoft.com', 'azure-frs99100@frs99100.onmicrosoft.com')
                }
                @{
                    UniuqeID                             = 'IdprotUserrisk'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @('Azure-Atos@frs99100.onmicrosoft.com', 'azure-frs99100@frs99100.onmicrosoft.com')
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @()
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'GeneralDeviceRegistration'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('0000000a-0000-0000-c000-000000000000', 'd4ebce55-015a-49b5-a083-c84d1797ae8c')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @()
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'BlockUnregisterdDevices'
                    ExcludeApplications                  = @('0000000a-0000-0000-c000-000000000000', 'd4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @('grp-99100z99-SEC-ROL-GlobalReader', 'grp-99100z99-SEC-ROL-SOC', 'grp-99100z99-SEC-ROL-GlobalAdmin', 'grp-99100z99-SEC-ROL-Beheerder', 'grp-99100z99-rol-g-eDiscovery', 'grp-99100z99-SEC-ROL-BLC')
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @('Citrix Opgang')
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @('Application Administrator', 'Application Developer', 'Attack Payload Author', 'Attack Simulation Administrator', 'Attribute Assignment Administrator', 'Attribute Assignment Reader', 'Attribute Definition Administrator', 'Attribute Definition Reader', 'Authentication Administrator', 'Authentication Policy Administrator', 'Azure AD Joined Device Local Administrator', 'Azure DevOps Administrator', 'Azure Information Protection Administrator', 'B2C IEF Keyset Administrator', 'B2C IEF Policy Administrator', 'Billing Administrator', 'Cloud App Security Administrator', 'Cloud Application Administrator', 'Cloud Device Administrator', 'Compliance Administrator', 'Compliance Data Administrator', 'Conditional Access Administrator', 'Desktop Analytics Administrator', 'Directory Readers', 'Customer LockBox Access Approver', 'Directory Synchronization Accounts', 'Directory Writers', 'Domain Name Administrator', 'Dynamics 365 Administrator', 'Edge Administrator', 'Exchange Administrator', 'Exchange Recipient Administrator', 'External ID User Flow Administrator', 'External ID User Flow Attribute Administrator', 'External Identity Provider Administrator', 'Global Administrator', 'Global Reader', 'Groups Administrator', 'Guest Inviter', 'Helpdesk Administrator', 'Hybrid Identity Administrator', 'Identity Governance Administrator', 'Insights Administrator', 'Insights Analyst', 'Insights Business Leader', 'Intune Administrator', 'Kaizala Administrator', 'Knowledge Administrator', 'Knowledge Manager', 'License Administrator', 'Lifecycle Workflows Administrator', 'Message Center Privacy Reader', 'Message Center Reader', 'Network Administrator', 'Office Apps Administrator', 'Organizational Messages Writer', 'Password Administrator', 'Permissions Management Administrator', 'Fabric Administrator', 'Power Platform Administrator', 'Printer Administrator', 'Printer Technician', 'Privileged Authentication Administrator', 'Privileged Role Administrator', 'Reports Reader', 'Search Administrator', 'Search Editor', 'Security Administrator', 'Security Operator', 'Security Reader', 'Service Support Administrator', 'SharePoint Administrator', 'Skype for Business Administrator', 'Teams Administrator', 'Teams Communications Administrator', 'Teams Communications Support Engineer', 'Teams Communications Support Specialist', 'Teams Devices Administrator', 'Tenant Creator', 'Usage Summary Reports Reader', 'User Administrator', 'Virtual Visits Administrator', 'Windows 365 Administrator', 'Windows Update Deployment Administrator', 'Authentication Extensibility Administrator', 'Microsoft Hardware Warranty Administrator', 'Microsoft Hardware Warranty Specialist', 'User Experience Success Manager', 'Viva Goals Administrator', 'Yammer Administrator')
                    ExcludeUsers                         = @('azure-frs99100@frs99100.onmicrosoft.com', 'Azure-Atos@frs99100.onmicrosoft.com')
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @('All')
                    IncludePlatforms                     = @('android', 'iOS', 'windows', 'macOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
                @{
                    UniqueID                             = 'CASBControl'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('Office365')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @('grp-99100z99-rol-g-WerkProfiel01')
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @()
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @()
                }
                @{
                    UniqueID                             = 'Win10AccessWIP'
                    ExcludeApplications                  = @('d4ebce55-015a-49b5-a083-c84d1797ae8c')
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = 'all'
                    ExcludeGroups                        = @()
                    ExcludeGuestOrExternalUserTypes      = @('internalGuest', 'b2bCollaborationGuest', 'b2bCollaborationMember', 'b2bDirectConnectUser', 'otherExternalUser', 'serviceProvider')
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('windows')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')

                }
                @{
                    UniqueID                             = 'UnsupportedLocations'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @('a098f889-9341-480c-8788-254c3988b4c5')
                    ExcludeExternalTenantsMembershipKind = 'enumerated'
                    ExcludeGroups                        = @()
                    ExcludeGuestOrExternalUserTypes      = @('serviceProvider')
                    ExcludeLocations                     = @('Citrix Opgang')
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @()
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @('All')
                    IncludePlatforms                     = @()
                    IncludeRoles                         = @('Application Administrator', 'Application Developer', 'Attack Payload Author', 'Attack Simulation Administrator', 'Attribute Assignment Administrator', 'Attribute Assignment Reader', 'Attribute Definition Administrator', 'Attribute Definition Reader', 'Authentication Administrator', 'Azure AD Joined Device Local Administrator', 'Authentication Policy Administrator', 'Azure Information Protection Administrator', 'Azure DevOps Administrator', 'B2C IEF Keyset Administrator', 'B2C IEF Policy Administrator', 'Billing Administrator', 'Cloud App Security Administrator', 'Cloud Application Administrator', 'Cloud Device Administrator', 'Compliance Administrator', 'Compliance Data Administrator', 'Conditional Access Administrator', 'Directory Writers', 'Directory Synchronization Accounts', 'Directory Readers', 'Desktop Analytics Administrator', 'Customer LockBox Access Approver', 'Domain Name Administrator', 'Dynamics 365 Administrator', 'Edge Administrator', 'Exchange Administrator', 'Exchange Recipient Administrator', 'External ID User Flow Attribute Administrator', 'External ID User Flow Administrator', 'External Identity Provider Administrator', 'Global Administrator', 'Global Reader', 'Groups Administrator', 'Guest Inviter', 'Helpdesk Administrator', 'Hybrid Identity Administrator', 'Identity Governance Administrator', 'Intune Administrator', 'Insights Business Leader', 'Insights Analyst', 'Insights Administrator', 'Kaizala Administrator', 'Knowledge Administrator', 'Knowledge Manager', 'License Administrator', 'Lifecycle Workflows Administrator', 'Message Center Privacy Reader', 'Microsoft Hardware Warranty Administrator', 'Message Center Reader', 'Microsoft Hardware Warranty Specialist', 'Network Administrator', 'Office Apps Administrator', 'Organizational Messages Writer', 'Password Administrator', 'Permissions Management Administrator', 'Fabric Administrator', 'Power Platform Administrator', 'Printer Administrator', 'Printer Technician', 'Privileged Authentication Administrator', 'Privileged Role Administrator', 'Reports Reader', 'Search Administrator', 'Search Editor', 'Security Administrator', 'Security Operator', 'Security Reader', 'Service Support Administrator', 'SharePoint Administrator', 'Skype for Business Administrator', 'Teams Administrator', 'Teams Communications Administrator', 'Teams Communications Support Engineer', 'Teams Communications Support Specialist', 'Teams Devices Administrator', 'Tenant Creator', 'Usage Summary Reports Reader', 'User Administrator', 'User Experience Success Manager', 'Virtual Visits Administrator', 'Windows 365 Administrator', 'Windows Update Deployment Administrator', 'Yammer Administrator')
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @()
                }
                @{
                    UniqueID                             = 'IdprotSigninRisk'
                    ExcludeApplications                  = @()
                    ExcludeExternalTenantsMembers        = @()
                    ExcludeExternalTenantsMembershipKind = ''
                    ExcludeGroups                        = @()
                    ExcludeLocations                     = @()
                    ExcludePlatforms                     = @()
                    ExcludeRoles                         = @()
                    ExcludeUsers                         = @('Azure-Atos@frs99100.onmicrosoft.com', 'azure-frs99100@frs99100.onmicrosoft.com')
                    IncludeApplications                  = @('All')
                    IncludeExternalTenantsMembers        = @()
                    IncludeExternalTenantsMembershipKind = ''
                    IncludeGroups                        = @()
                    IncludeLocations                     = @()
                    IncludePlatforms                     = @('android', 'iOS', 'windows', 'macOS')
                    IncludeRoles                         = @()
                    IncludeUserActions                   = @()
                    IncludeUsers                         = @('All')
                }
            )
            GroupLifecyclePolicy              = @{

                UniqueID                    = 'GroupLifecyclePolicy'
                AlternateNotificationEmails = @()
            }
            GroupsSettings                    = @{
                UniqueID                      = 'GroupCreation'
                GroupCreationAllowedGroupName = 'grp-99100z99-rol-g-AddM365Groups'
            }
        }
        Exchange       = @{
            MailTips        = @(
                @{
                    UniqueId     = 'AllMailTips'
                    Organization = 'soesterberg.onmicrosoft.com'
                }
            )
            AcceptedDomains = @(
                @{
                    UniqueId = 'Default'
                    Identity = 'soesterberg.onmicrosoft.com'
                }
            )
        }
        Teams          = @{
            AppSetupPolicies        = @(
                @{
                    UniqueId         = 'PinnedAppBarGlobal'
                    PinnedAppBarApps = @('14d6962d-6eeb-4f48-8890-de55454bb136', '86fcd49b-61a2-4701-b771-54728cd291fb', '2a84919f-59d8-4441-a975-2a8c2643b741', 'ef56c0de-36fc-4ef8-b417-3d82ba9d073c', '20c3440d-c67e-4420-9f80-0e50c39693df', '5af6a76b-40fc-4ba1-af29-8f49b08e44fd')
                }
                @{
                    UniqueId         = 'PinnedAppBarFirst'
                    PinnedAppBarApps = @('14d6962d-6eeb-4f48-8890-de55454bb136', '86fcd49b-61a2-4701-b771-54728cd291fb', '2a84919f-59d8-4441-a975-2a8c2643b741', 'ef56c0de-36fc-4ef8-b417-3d82ba9d073c', '20c3440d-c67e-4420-9f80-0e50c39693df', '5af6a76b-40fc-4ba1-af29-8f49b08e44fd')
                }
            )
            GroupPoliciesAssignment = @(
                @{
                    UniqueId         = 'GroupPolicyLiveEvents'
                    GroupDisplayName = 'grp-99100z99-rol-g-TeamsLiveEvent'
                    GroupId          = 'affaa8b1-8166-4d68-985b-9aa848beff42'
                }
            )
            UpgradePolicies         = @(
                @{
                    UniqueID = 'UpgradeToTeamsID'
                    Users    = @('')
                }
            )
        }
        Office365      = @{}
        SharePoint     = @{
            SharingSettings = @{
                UniqueId                 = 'SharingAllowList'
                SharingAllowedDomainList = @('jio.nl')
            }
        }
        OneDrive       = @{}
    <#Planner            = @{
            Buckets = @(
                @{}
            )
            Plans   = @(
                @{}
            )
            Tasks   = @(
                @{
                    Attachments = @(
                        @{
                            Alias = 'String | Optional'
                            Type = 'String | Optional | PowerPoint / Word / Excel / Other'
                            Uri = 'String | Optional'
                        }
                    )
                    Checklist   = @(
                        @{
                            Completed = 'String | Optional'
                            Title = 'String | Optional'
                        }
                    )
                }
            )
        }#>
    <#PowerPlatform      = @{
            PowerAppsEnvironments   = @(
                @{}
            )
            TenantIsolationSettings = @{
                RulesToExclude = @(
                    @{
                        TenantName = 'String | Required'
                        Direction = 'String | Required | Inbound / Outbound / Both'
                    }
                )
                RulesToInclude = @(
                    @{
                        TenantName = 'String | Required'
                        Direction = 'String | Required | Inbound / Outbound / Both'
                    }
                )
                Rules          = @(
                    @{
                        TenantName = 'String | Required'
                        Direction = 'String | Required | Inbound / Outbound / Both'
                    }
                )
            }
            TenantSettings          = @{}
        }#>
    <#Intune             = @{
            AntivirusPoliciesWindows10SettingCatalog                          = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            AppConfigurationPolicies                                          = @(
                @{
                    CustomSettings = @(
                        @{
                            value = 'String | Optional'
                            name  = 'String | Optional'
                        }
                    )
                    Assignments    = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            ApplicationControlPoliciesWindows10                               = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            AppProtectionPoliciesAndroid                                      = @(
                @{}
            )
            AppProtectionPoliciesiOS                                          = @(
                @{}
            )
            ASRRulesPoliciesWindows10                                         = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            AttackSurfaceReductionRulesPoliciesWindows10ConfigManager         = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceAndAppManagementAssignmentFilters                           = @(
                @{}
            )
            DeviceCategories                                                  = @(
                @{}
            )
            DeviceCompliancePoliciesAndroid                                   = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceCompliancePoliciesAndroidDeviceOwner                        = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceCompliancePoliciesAndroidWorkProfile                        = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceCompliancePoliciesiOs                                       = @(
                @{
                    Assignments    = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    RestrictedApps = @(
                        @{
                            publisher   = 'String | Optional'
                            name        = 'String | Optional'
                            appId       = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                        }
                    )
                }
            )
            DeviceCompliancePoliciesMacOS                                     = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceCompliancePoliciesWindows10                                 = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationAdministrativeTemplatePoliciesWindows10        = @(
                @{
                    DefinitionValues = @(
                        @{
                            ConfigurationType  = 'String | Optional | policy / preference'
                            PresentationValues = @(
                                @{
                                    BooleanValue                = 'Boolean | Optional'
                                    StringValue                 = 'String | Optional'
                                    Id                          = 'String | Optional'
                                    DecimalValue                = 'UInt64 | Optional'
                                    odataType                   = 'String | Optional | microsoft.graph.groupPolicyPresentationValueBoolean / microsoft.graph.groupPolicyPresentationValueDecimal / microsoft.graph.groupPolicyPresentationValueList / microsoft.graph.groupPolicyPresentationValueLongDecimal / microsoft.graph.groupPolicyPresentationValueMultiText / microsoft.graph.groupPolicyPresentationValueText'
                                    PresentationDefinitionLabel = 'String | Optional'
                                    KeyValuePairValues          = @(
                                        #@{
                                            Name  = 'String | Optional'
                                            Value = 'String | Optional'
                                        #}
                                    )
                                    PresentationDefinitionId    = 'String | Optional'
                                    StringValues                = 'StringArray | Optional'
                                }
                            )
                            Id                 = 'String | Optional'
                            Definition         = @{
                                CategoryPath          = 'String | Optional'
                                PolicyType            = 'String | Optional | admxBacked / admxIngested'
                                SupportedOn           = 'String | Optional'
                                MinDeviceCspVersion   = 'String | Optional'
                                MinUserCspVersion     = 'String | Optional'
                                ExplainText           = 'String | Optional'
                                Id                    = 'String | Optional'
                                ClassType             = 'String | Optional | user / machine'
                                GroupPolicyCategoryId = 'String | Optional'
                                HasRelatedDefinitions = 'Boolean | Optional'
                                DisplayName           = 'String | Optional'
                            }
                            Enabled            = 'Boolean | Optional'
                        }
                    )
                    Assignments      = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationCustomPoliciesWindows10                        = @(
                @{
                    OmaSettings = @(
                        @{
                            FileName               = 'String | Optional'
                            Description            = 'String | Optional'
                            OmaUri                 = 'String | Optional'
                            odataType              = 'String | Optional | microsoft.graph.omaSettingBase64 / microsoft.graph.omaSettingBoolean / microsoft.graph.omaSettingDateTime / microsoft.graph.omaSettingFloatingPoint / microsoft.graph.omaSettingInteger / microsoft.graph.omaSettingString / microsoft.graph.omaSettingStringXml'
                            SecretReferenceValueId = 'String | Optional'
                            Value                  = 'String | Optional'
                            IsReadOnly             = 'Boolean | Optional'
                            IsEncrypted            = 'Boolean | Optional'
                            DisplayName            = 'String | Optional'
                        }
                    )
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationDefenderForEndpointOnboardingPoliciesWindows10 = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationDeliveryOptimizationPoliciesWindows10          = @(
                @{
                    MaximumCacheSize = @{
                        MaximumCacheSizePercentage  = 'UInt32 | Optional'
                        MaximumCacheSizeInGigabytes = 'UInt64 | Optional'
                        odataType                   = 'String | Optional | microsoft.graph.deliveryOptimizationMaxCacheSizeAbsolute / microsoft.graph.deliveryOptimizationMaxCacheSizePercentage'
                    }
                    GroupIdSource    = @{
                        GroupIdCustom       = 'String | Optional'
                        GroupIdSourceOption = 'String | Optional | notConfigured / adSite / authenticatedDomainSid / dhcpUserOption / dnsSuffix'
                        odataType           = 'String | Optional | microsoft.graph.deliveryOptimizationGroupIdCustom / microsoft.graph.deliveryOptimizationGroupIdSourceOptions'
                    }
                    Assignments      = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    BandwidthMode    = @{
                        MaximumDownloadBandwidthInKilobytesPerSecond = 'UInt64 | Optional'
                        BandwidthBackgroundPercentageHours           = @{
                            BandwidthBeginBusinessHours             = 'UInt32 | Optional'
                            BandwidthPercentageOutsideBusinessHours = 'UInt32 | Optional'
                            BandwidthPercentageDuringBusinessHours  = 'UInt32 | Optional'
                            BandwidthEndBusinessHours               = 'UInt32 | Optional'
                        }
                        MaximumForegroundBandwidthPercentage         = 'UInt32 | Optional'
                        BandwidthForegroundPercentageHours           = @{
                            BandwidthBeginBusinessHours             = 'UInt32 | Optional'
                            BandwidthPercentageOutsideBusinessHours = 'UInt32 | Optional'
                            BandwidthPercentageDuringBusinessHours  = 'UInt32 | Optional'
                            BandwidthEndBusinessHours               = 'UInt32 | Optional'
                        }
                        MaximumBackgroundBandwidthPercentage         = 'UInt32 | Optional'
                        MaximumUploadBandwidthInKilobytesPerSecond   = 'UInt64 | Optional'
                        odataType                                    = 'String | Optional | microsoft.graph.deliveryOptimizationBandwidthAbsolute / microsoft.graph.deliveryOptimizationBandwidthHoursWithPercentage / microsoft.graph.deliveryOptimizationBandwidthPercentage'
                    }
                }
            )
            DeviceConfigurationDomainJoinPoliciesWindows10                    = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationEmailProfilePoliciesWindows10                  = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationEndpointProtectionPoliciesWindows10            = @(
                @{
                    UserRightsRemoteShutdown                         = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsManageVolumes                          = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsBackupData                             = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsLoadUnloadDrivers                      = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsIncreaseSchedulingPriority             = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsImpersonateClient                      = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsDebugPrograms                          = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsCreatePageFile                         = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsRestoreData                            = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsGenerateSecurityAudits                 = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    FirewallProfilePrivate                           = @{
                        PolicyRulesFromGroupPolicyNotMerged                = 'Boolean | Optional'
                        InboundNotificationsBlocked                        = 'Boolean | Optional'
                        OutboundConnectionsRequired                        = 'Boolean | Optional'
                        GlobalPortRulesFromGroupPolicyNotMerged            = 'Boolean | Optional'
                        ConnectionSecurityRulesFromGroupPolicyNotMerged    = 'Boolean | Optional'
                        UnicastResponsesToMulticastBroadcastsRequired      = 'Boolean | Optional'
                        PolicyRulesFromGroupPolicyMerged                   = 'Boolean | Optional'
                        UnicastResponsesToMulticastBroadcastsBlocked       = 'Boolean | Optional'
                        IncomingTrafficRequired                            = 'Boolean | Optional'
                        IncomingTrafficBlocked                             = 'Boolean | Optional'
                        ConnectionSecurityRulesFromGroupPolicyMerged       = 'Boolean | Optional'
                        StealthModeRequired                                = 'Boolean | Optional'
                        InboundNotificationsRequired                       = 'Boolean | Optional'
                        AuthorizedApplicationRulesFromGroupPolicyMerged    = 'Boolean | Optional'
                        InboundConnectionsBlocked                          = 'Boolean | Optional'
                        OutboundConnectionsBlocked                         = 'Boolean | Optional'
                        StealthModeBlocked                                 = 'Boolean | Optional'
                        GlobalPortRulesFromGroupPolicyMerged               = 'Boolean | Optional'
                        SecuredPacketExemptionBlocked                      = 'Boolean | Optional'
                        SecuredPacketExemptionAllowed                      = 'Boolean | Optional'
                        InboundConnectionsRequired                         = 'Boolean | Optional'
                        FirewallEnabled                                    = 'String | Optional | notConfigured / blocked / allowed'
                        AuthorizedApplicationRulesFromGroupPolicyNotMerged = 'Boolean | Optional'
                    }
                    Assignments                                      = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    FirewallProfilePublic                            = @{
                        PolicyRulesFromGroupPolicyNotMerged                = 'Boolean | Optional'
                        InboundNotificationsBlocked                        = 'Boolean | Optional'
                        OutboundConnectionsRequired                        = 'Boolean | Optional'
                        GlobalPortRulesFromGroupPolicyNotMerged            = 'Boolean | Optional'
                        ConnectionSecurityRulesFromGroupPolicyNotMerged    = 'Boolean | Optional'
                        UnicastResponsesToMulticastBroadcastsRequired      = 'Boolean | Optional'
                        PolicyRulesFromGroupPolicyMerged                   = 'Boolean | Optional'
                        UnicastResponsesToMulticastBroadcastsBlocked       = 'Boolean | Optional'
                        IncomingTrafficRequired                            = 'Boolean | Optional'
                        IncomingTrafficBlocked                             = 'Boolean | Optional'
                        ConnectionSecurityRulesFromGroupPolicyMerged       = 'Boolean | Optional'
                        StealthModeRequired                                = 'Boolean | Optional'
                        InboundNotificationsRequired                       = 'Boolean | Optional'
                        AuthorizedApplicationRulesFromGroupPolicyMerged    = 'Boolean | Optional'
                        InboundConnectionsBlocked                          = 'Boolean | Optional'
                        OutboundConnectionsBlocked                         = 'Boolean | Optional'
                        StealthModeBlocked                                 = 'Boolean | Optional'
                        GlobalPortRulesFromGroupPolicyMerged               = 'Boolean | Optional'
                        SecuredPacketExemptionBlocked                      = 'Boolean | Optional'
                        SecuredPacketExemptionAllowed                      = 'Boolean | Optional'
                        InboundConnectionsRequired                         = 'Boolean | Optional'
                        FirewallEnabled                                    = 'String | Optional | notConfigured / blocked / allowed'
                        AuthorizedApplicationRulesFromGroupPolicyNotMerged = 'Boolean | Optional'
                    }
                    UserRightsBlockAccessFromNetwork                 = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    FirewallProfileDomain                            = @{
                        PolicyRulesFromGroupPolicyNotMerged                = 'Boolean | Optional'
                        InboundNotificationsBlocked                        = 'Boolean | Optional'
                        OutboundConnectionsRequired                        = 'Boolean | Optional'
                        GlobalPortRulesFromGroupPolicyNotMerged            = 'Boolean | Optional'
                        ConnectionSecurityRulesFromGroupPolicyNotMerged    = 'Boolean | Optional'
                        UnicastResponsesToMulticastBroadcastsRequired      = 'Boolean | Optional'
                        PolicyRulesFromGroupPolicyMerged                   = 'Boolean | Optional'
                        UnicastResponsesToMulticastBroadcastsBlocked       = 'Boolean | Optional'
                        IncomingTrafficRequired                            = 'Boolean | Optional'
                        IncomingTrafficBlocked                             = 'Boolean | Optional'
                        ConnectionSecurityRulesFromGroupPolicyMerged       = 'Boolean | Optional'
                        StealthModeRequired                                = 'Boolean | Optional'
                        InboundNotificationsRequired                       = 'Boolean | Optional'
                        AuthorizedApplicationRulesFromGroupPolicyMerged    = 'Boolean | Optional'
                        InboundConnectionsBlocked                          = 'Boolean | Optional'
                        OutboundConnectionsBlocked                         = 'Boolean | Optional'
                        StealthModeBlocked                                 = 'Boolean | Optional'
                        GlobalPortRulesFromGroupPolicyMerged               = 'Boolean | Optional'
                        SecuredPacketExemptionBlocked                      = 'Boolean | Optional'
                        SecuredPacketExemptionAllowed                      = 'Boolean | Optional'
                        InboundConnectionsRequired                         = 'Boolean | Optional'
                        FirewallEnabled                                    = 'String | Optional | notConfigured / blocked / allowed'
                        AuthorizedApplicationRulesFromGroupPolicyNotMerged = 'Boolean | Optional'
                    }
                    UserRightsDenyLocalLogOn                         = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    BitLockerSystemDrivePolicy                       = @{
                        PrebootRecoveryEnableMessageAndUrl       = 'Boolean | Optional'
                        StartupAuthenticationTpmPinUsage         = 'String | Optional | blocked / required / allowed / notConfigured'
                        EncryptionMethod                         = 'String | Optional | aesCbc128 / aesCbc256 / xtsAes128 / xtsAes256'
                        MinimumPinLength                         = 'UInt32 | Optional'
                        PrebootRecoveryMessage                   = 'String | Optional'
                        StartupAuthenticationTpmPinAndKeyUsage   = 'String | Optional | blocked / required / allowed / notConfigured'
                        StartupAuthenticationRequired            = 'Boolean | Optional'
                        RecoveryOptions                          = @{
                            RecoveryInformationToStore                     = 'String | Optional | passwordAndKey / passwordOnly'
                            HideRecoveryOptions                            = 'Boolean | Optional'
                            BlockDataRecoveryAgent                         = 'Boolean | Optional'
                            RecoveryKeyUsage                               = 'String | Optional | blocked / required / allowed / notConfigured'
                            EnableBitLockerAfterRecoveryInformationToStore = 'Boolean | Optional'
                            EnableRecoveryInformationSaveToStore           = 'Boolean | Optional'
                            RecoveryPasswordUsage                          = 'String | Optional | blocked / required / allowed / notConfigured'
                        }
                        PrebootRecoveryUrl                       = 'String | Optional'
                        StartupAuthenticationTpmUsage            = 'String | Optional | blocked / required / allowed / notConfigured'
                        StartupAuthenticationTpmKeyUsage         = 'String | Optional | blocked / required / allowed / notConfigured'
                        StartupAuthenticationBlockWithoutTpmChip = 'Boolean | Optional'
                    }
                    UserRightsLocalLogOn                             = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsModifyObjectLabels                     = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    BitLockerFixedDrivePolicy                        = @{
                        RecoveryOptions                 = @{
                            RecoveryInformationToStore                     = 'String | Optional | passwordAndKey / passwordOnly'
                            HideRecoveryOptions                            = 'Boolean | Optional'
                            BlockDataRecoveryAgent                         = 'Boolean | Optional'
                            RecoveryKeyUsage                               = 'String | Optional | blocked / required / allowed / notConfigured'
                            EnableBitLockerAfterRecoveryInformationToStore = 'Boolean | Optional'
                            EnableRecoveryInformationSaveToStore           = 'Boolean | Optional'
                            RecoveryPasswordUsage                          = 'String | Optional | blocked / required / allowed / notConfigured'
                        }
                        RequireEncryptionForWriteAccess = 'Boolean | Optional'
                        EncryptionMethod                = 'String | Optional | aesCbc128 / aesCbc256 / xtsAes128 / xtsAes256'
                    }
                    UserRightsDelegation                             = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsAllowAccessFromNetwork                 = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsCreatePermanentSharedObjects           = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    FirewallRules                                    = @(
                        @{
                            LocalAddressRanges      = 'StringArray | Optional'
                            Action                  = 'String | Optional | notConfigured / blocked / allowed'
                            Description             = 'String | Optional'
                            InterfaceTypes          = 'String | Optional | notConfigured / remoteAccess / wireless / lan'
                            RemotePortRanges        = 'StringArray | Optional'
                            DisplayName             = 'String | Optional'
                            FilePath                = 'String | Optional'
                            LocalUserAuthorizations = 'String | Optional'
                            Protocol                = 'UInt32 | Optional'
                            TrafficDirection        = 'String | Optional | notConfigured / out / in'
                            RemoteAddressRanges     = 'StringArray | Optional'
                            PackageFamilyName       = 'String | Optional'
                            ServiceName             = 'String | Optional'
                            LocalPortRanges         = 'StringArray | Optional'
                            ProfileTypes            = 'String | Optional | notConfigured / domain / private / public'
                            EdgeTraversal           = 'String | Optional | notConfigured / blocked / allowed'
                        }
                    )
                    UserRightsModifyFirmwareEnvironment              = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    BitLockerRemovableDrivePolicy                    = @{
                        RequireEncryptionForWriteAccess   = 'Boolean | Optional'
                        BlockCrossOrganizationWriteAccess = 'Boolean | Optional'
                        EncryptionMethod                  = 'String | Optional | aesCbc128 / aesCbc256 / xtsAes128 / xtsAes256'
                    }
                    UserRightsCreateToken                            = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsProfileSingleProcess                   = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsChangeSystemTime                       = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsCreateGlobalObjects                    = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsTakeOwnership                          = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsLockMemory                             = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsManageAuditingAndSecurityLogs          = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsAccessCredentialManagerAsTrustedCaller = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    DefenderDetectedMalwareActions                   = @{
                        LowSeverity      = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                        SevereSeverity   = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                        ModerateSeverity = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                        HighSeverity     = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                    }
                    UserRightsActAsPartOfTheOperatingSystem          = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsRemoteDesktopServicesLogOn             = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                    UserRightsCreateSymbolicLinks                    = @{
                        State              = 'String | Optional | notConfigured / blocked / allowed'
                        LocalUsersOrGroups = @(
                            @{
                                Description        = 'String | Optional'
                                Name               = 'String | Optional'
                                SecurityIdentifier = 'String | Optional'
                            }
                        )
                    }
                }
            )
            DeviceConfigurationFirmwareInterfacePoliciesWindows10             = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationHealthMonitoringConfigurationPoliciesWindows10 = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationIdentityProtectionPoliciesWindows10            = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationImportedPfxCertificatePoliciesWindows10        = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationKioskPoliciesWindows10                         = @(
                @{
                    WindowsKioskForceUpdateSchedule = @{
                        RunImmediatelyIfAfterStartDateTime = 'Boolean | Optional'
                        StartDateTime                      = 'String | Optional'
                        DayofMonth                         = 'UInt32 | Optional'
                        Recurrence                         = 'String | Optional | none / daily / weekly / monthly'
                        DayofWeek                          = 'String | Optional | sunday / monday / tuesday / wednesday / thursday / friday / saturday'
                    }
                    Assignments                     = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    KioskProfiles                   = @(
                        @{
                            ProfileId                 = 'String | Optional'
                            UserAccountsConfiguration = @(
                                @{
                                    GroupId           = 'String | Optional'
                                    UserName          = 'String | Optional'
                                    UserPrincipalName = 'String | Optional'
                                    odataType         = 'String | Optional | microsoft.graph.windowsKioskActiveDirectoryGroup / microsoft.graph.windowsKioskAutologon / microsoft.graph.windowsKioskAzureADGroup / microsoft.graph.windowsKioskAzureADUser / microsoft.graph.windowsKioskLocalGroup / microsoft.graph.windowsKioskLocalUser / microsoft.graph.windowsKioskVisitor'
                                    GroupName         = 'String | Optional'
                                    UserId            = 'String | Optional'
                                    DisplayName       = 'String | Optional'
                                }
                            )
                            ProfileName               = 'String | Optional'
                            AppConfiguration          = @{
                                UwpApp                       = @{
                                    EdgeNoFirstRun              = 'Boolean | Optional'
                                    Name                        = 'String | Optional'
                                    EdgeKiosk                   = 'String | Optional'
                                    ClassicAppPath              = 'String | Optional'
                                    AppId                       = 'String | Optional'
                                    AppUserModelId              = 'String | Optional'
                                    EdgeKioskIdleTimeoutMinutes = 'UInt32 | Optional'
                                    AutoLaunch                  = 'Boolean | Optional'
                                    StartLayoutTileSize         = 'String | Optional | hidden / small / medium / wide / large'
                                    AppType                     = 'String | Optional | unknown / store / desktop / aumId'
                                    EdgeKioskType               = 'String | Optional | publicBrowsing / fullScreen'
                                    ContainedAppId              = 'String | Optional'
                                    DesktopApplicationId        = 'String | Optional'
                                    DesktopApplicationLinkPath  = 'String | Optional'
                                    Path                        = 'String | Optional'
                                    odataType                   = 'String | Optional | microsoft.graph.windowsKioskDesktopApp / microsoft.graph.windowsKioskUWPApp / microsoft.graph.windowsKioskWin32App'
                                }
                                Win32App                     = @{
                                    EdgeNoFirstRun              = 'Boolean | Optional'
                                    Name                        = 'String | Optional'
                                    EdgeKiosk                   = 'String | Optional'
                                    ClassicAppPath              = 'String | Optional'
                                    EdgeKioskIdleTimeoutMinutes = 'UInt32 | Optional'
                                    AppUserModelId              = 'String | Optional'
                                    AppId                       = 'String | Optional'
                                    AutoLaunch                  = 'Boolean | Optional'
                                    StartLayoutTileSize         = 'String | Optional | hidden / small / medium / wide / large'
                                    AppType                     = 'String | Optional | unknown / store / desktop / aumId'
                                    EdgeKioskType               = 'String | Optional | publicBrowsing / fullScreen'
                                    ContainedAppId              = 'String | Optional'
                                    DesktopApplicationId        = 'String | Optional'
                                    DesktopApplicationLinkPath  = 'String | Optional'
                                    Path                        = 'String | Optional'
                                    odataType                   = 'String | Optional | microsoft.graph.windowsKioskDesktopApp / microsoft.graph.windowsKioskUWPApp / microsoft.graph.windowsKioskWin32App'
                                }
                                Apps                         = @(
                                    @{
                                        EdgeNoFirstRun              = 'Boolean | Optional'
                                        Name                        = 'String | Optional'
                                        EdgeKiosk                   = 'String | Optional'
                                        ClassicAppPath              = 'String | Optional'
                                        AppId                       = 'String | Optional'
                                        AppUserModelId              = 'String | Optional'
                                        EdgeKioskIdleTimeoutMinutes = 'UInt32 | Optional'
                                        AutoLaunch                  = 'Boolean | Optional'
                                        StartLayoutTileSize         = 'String | Optional | hidden / small / medium / wide / large'
                                        AppType                     = 'String | Optional | unknown / store / desktop / aumId'
                                        EdgeKioskType               = 'String | Optional | publicBrowsing / fullScreen'
                                        ContainedAppId              = 'String | Optional'
                                        DesktopApplicationId        = 'String | Optional'
                                        DesktopApplicationLinkPath  = 'String | Optional'
                                        Path                        = 'String | Optional'
                                        odataType                   = 'String | Optional | microsoft.graph.windowsKioskDesktopApp / microsoft.graph.windowsKioskUWPApp / microsoft.graph.windowsKioskWin32App'
                                    }
                                )
                                AllowAccessToDownloadsFolder = 'Boolean | Optional'
                                ShowTaskBar                  = 'Boolean | Optional'
                                DisallowDesktopApps          = 'Boolean | Optional'
                                odataType                    = 'String | Optional | microsoft.graph.windowsKioskMultipleApps / microsoft.graph.windowsKioskSingleUWPApp / microsoft.graph.windowsKioskSingleWin32App'
                                StartMenuLayoutXml           = 'String | Optional'
                            }
                        }
                    )
                }
            )
            DeviceConfigurationNetworkBoundaryPoliciesWindows10               = @(
                @{
                    WindowsNetworkIsolationPolicy = @{
                        EnterpriseProxyServers                 = 'StringArray | Optional'
                        EnterpriseInternalProxyServers         = 'StringArray | Optional'
                        EnterpriseIPRangesAreAuthoritative     = 'Boolean | Optional'
                        EnterpriseCloudResources               = @(
                            @{
                                Proxy           = 'String | Optional'
                                IpAddressOrFQDN = 'String | Optional'
                            }
                        )
                        EnterpriseProxyServersAreAuthoritative = 'Boolean | Optional'
                        EnterpriseNetworkDomainNames           = 'StringArray | Optional'
                        EnterpriseIPRanges                     = @(
                            @{
                                CidrAddress  = 'String | Optional'
                                UpperAddress = 'String | Optional'
                                LowerAddress = 'String | Optional'
                                odataType    = 'String | Optional | microsoft.graph.iPv4CidrRange / microsoft.graph.iPv6CidrRange / microsoft.graph.iPv4Range / microsoft.graph.iPv6Range'
                            }
                        )
                        NeutralDomainResources                 = 'StringArray | Optional'
                    }
                    Assignments                   = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationPkcsCertificatePoliciesWindows10               = @(
                @{
                    ExtendedKeyUsages             = @(
                        @{
                            ObjectIdentifier = 'String | Optional'
                            Name             = 'String | Optional'
                        }
                    )
                    Assignments                   = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    CustomSubjectAlternativeNames = @(
                        @{
                            SanType = 'String | Optional | none / emailAddress / userPrincipalName / customAzureADAttribute / domainNameService / universalResourceIdentifier'
                            Name    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationPoliciesAndroidDeviceAdministrator             = @(
                @{
                    Assignments          = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    AppsLaunchBlockList  = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    KioskModeApps        = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    CompliantAppsList    = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    AppsHideList         = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    AppsInstallAllowList = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                }
            )
            DeviceConfigurationPoliciesAndroidDeviceOwner                     = @(
                @{
                    Assignments                         = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    AzureAdSharedDeviceDataClearApps    = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    KioskModeApps                       = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    DeviceOwnerLockScreenMessage        = @{
                        localizedMessages = @(
                            @{
                                Value = 'String | Optional'
                                Name  = 'String | Optional'
                            }
                        )
                        defaultMessage    = 'String | Optional'
                    }
                    GlobalProxy                         = @{
                        excludedHosts      = 'StringArray | Optional'
                        host               = 'String | Optional'
                        port               = 'UInt32 | Optional'
                        proxyAutoConfigURL = 'String | Optional'
                        odataType          = 'String | Optional | microsoft.graph.androidDeviceOwnerGlobalProxyAutoConfig / microsoft.graph.androidDeviceOwnerGlobalProxyDirect'
                    }
                    KioskModeAppPositions               = @(
                        @{
                            item     = @{
                                folderName       = 'String | Optional'
                                folderIdentifier = 'String | Optional'
                                items            = @(
                                    @{
                                        className = 'String | Optional'
                                        package   = 'String | Optional'
                                        label     = 'String | Optional'
                                        link      = 'String | Optional'
                                        odataType = 'String | Optional | microsoft.graph.androidDeviceOwnerKioskModeApp / microsoft.graph.androidDeviceOwnerKioskModeWeblink'
                                    }
                                )
                                label            = 'String | Optional'
                                link             = 'String | Optional'
                                package          = 'String | Optional'
                                odataType        = 'String | Optional | microsoft.graph.androidDeviceOwnerKioskModeApp / microsoft.graph.androidDeviceOwnerKioskModeWeblink / microsoft.graph.androidDeviceOwnerKioskModeManagedFolder'
                                className        = 'String | Optional'
                            }
                            position = 'UInt32 | Optional'
                        }
                    )
                    KioskModeManagedFolders             = @(
                        @{
                            folderName       = 'String | Optional'
                            items            = @(
                                @{
                                    className = 'String | Optional'
                                    package   = 'String | Optional'
                                    label     = 'String | Optional'
                                    link      = 'String | Optional'
                                    odataType = 'String | Optional | microsoft.graph.androidDeviceOwnerKioskModeApp / microsoft.graph.androidDeviceOwnerKioskModeWeblink'
                                }
                            )
                            folderIdentifier = 'String | Optional'
                        }
                    )
                    ShortHelpText                       = @{
                        localizedMessages = @(
                            @{
                                Value = 'String | Optional'
                                Name  = 'String | Optional'
                            }
                        )
                        defaultMessage    = 'String | Optional'
                    }
                    PersonalProfilePersonalApplications = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    DetailedHelpText                    = @{
                        localizedMessages = @(
                            @{
                                Value = 'String | Optional'
                                Name  = 'String | Optional'
                            }
                        )
                        defaultMessage    = 'String | Optional'
                    }
                    SystemUpdateFreezePeriods           = @(
                        @{
                            endMonth   = 'UInt32 | Optional'
                            startMonth = 'UInt32 | Optional'
                            startDay   = 'UInt32 | Optional'
                            endDay     = 'UInt32 | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationPoliciesAndroidOpenSourceProject               = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationPoliciesAndroidWorkProfile                     = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationPoliciesiOS                                    = @(
                @{
                    MediaContentRatingGermany       = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / agesAbove6 / agesAbove12 / agesAbove16 / adults'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / general / agesAbove6 / agesAbove12 / agesAbove16 / adults'
                    }
                    MediaContentRatingFrance        = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / agesAbove10 / agesAbove12 / agesAbove16 / agesAbove18'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / agesAbove10 / agesAbove12 / agesAbove16 / agesAbove18'
                    }
                    MediaContentRatingUnitedKingdom = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / universalChildren / parentalGuidance / agesAbove12Video / agesAbove12Cinema / agesAbove15 / adults'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / caution'
                    }
                    MediaContentRatingCanada        = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / agesAbove14 / agesAbove18 / restricted'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / children / childrenAbove8 / general / parentalGuidance / agesAbove14 / agesAbove18'
                    }
                    MediaContentRatingJapan         = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / agesAbove15 / agesAbove18'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / explicitAllowed'
                    }
                    MediaContentRatingAustralia     = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / mature / agesAbove15 / agesAbove18'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / preschoolers / children / general / parentalGuidance / mature / agesAbove15 / agesAbove15AdultViolence'
                    }
                    Assignments                     = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    MediaContentRatingUnitedStates  = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / parentalGuidance13 / restricted / adults'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / childrenAll / childrenAbove7 / general / parentalGuidance / childrenAbove14 / adults'
                    }
                    AppsVisibilityList              = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    MediaContentRatingNewZealand    = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / mature / agesAbove13 / agesAbove15 / agesAbove16 / agesAbove18 / restricted / agesAbove16Restricted'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / adults'
                    }
                    AppsSingleAppModeList           = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    NetworkUsageRules               = @(
                        @{
                            cellularDataBlockWhenRoaming = 'Boolean | Optional'
                            managedApps                  = @(
                                @{
                                    appId       = 'String | Optional'
                                    publisher   = 'String | Optional'
                                    appStoreUrl = 'String | Optional'
                                    name        = 'String | Optional'
                                    odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                                }
                            )
                            cellularDataBlocked          = 'Boolean | Optional'
                        }
                    )
                    CompliantAppsList               = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                    MediaContentRatingIreland       = @{
                        movieRating = 'String | Optional | allAllowed / allBlocked / general / parentalGuidance / agesAbove12 / agesAbove15 / agesAbove16 / adults'
                        tvRating    = 'String | Optional | allAllowed / allBlocked / general / children / youngAdults / parentalSupervision / mature'
                    }
                }
            )
            DeviceConfigurationPoliciesMacOS                                  = @(
                @{
                    PrivacyAccessControls = @(
                        @{
                            systemPolicyRemovableVolumes = 'String | Optional | notConfigured / enabled / disabled'
                            accessibility                = 'String | Optional | notConfigured / enabled / disabled'
                            systemPolicyDesktopFolder    = 'String | Optional | notConfigured / enabled / disabled'
                            displayName                  = 'String | Optional'
                            postEvent                    = 'String | Optional | notConfigured / enabled / disabled'
                            speechRecognition            = 'String | Optional | notConfigured / enabled / disabled'
                            codeRequirement              = 'String | Optional'
                            fileProviderPresence         = 'String | Optional | notConfigured / enabled / disabled'
                            reminders                    = 'String | Optional | notConfigured / enabled / disabled'
                            systemPolicyNetworkVolumes   = 'String | Optional | notConfigured / enabled / disabled'
                            blockMicrophone              = 'Boolean | Optional'
                            mediaLibrary                 = 'String | Optional | notConfigured / enabled / disabled'
                            appleEventsAllowedReceivers  = @(
                                @{
                                    identifier      = 'String | Optional'
                                    identifierType  = 'String | Optional | bundleID / path'
                                    allowed         = 'Boolean | Optional'
                                    codeRequirement = 'String | Optional'
                                }
                            )
                            blockCamera                  = 'Boolean | Optional'
                            systemPolicyAllFiles         = 'String | Optional | notConfigured / enabled / disabled'
                            blockListenEvent             = 'Boolean | Optional'
                            identifier                   = 'String | Optional'
                            systemPolicyDocumentsFolder  = 'String | Optional | notConfigured / enabled / disabled'
                            staticCodeValidation         = 'Boolean | Optional'
                            photos                       = 'String | Optional | notConfigured / enabled / disabled'
                            systemPolicySystemAdminFiles = 'String | Optional | notConfigured / enabled / disabled'
                            systemPolicyDownloadsFolder  = 'String | Optional | notConfigured / enabled / disabled'
                            blockScreenCapture           = 'Boolean | Optional'
                            addressBook                  = 'String | Optional | notConfigured / enabled / disabled'
                            calendar                     = 'String | Optional | notConfigured / enabled / disabled'
                            identifierType               = 'String | Optional | bundleID / path'
                        }
                    )
                    Assignments           = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    CompliantAppsList     = @(
                        @{
                            appId       = 'String | Optional'
                            publisher   = 'String | Optional'
                            appStoreUrl = 'String | Optional'
                            name        = 'String | Optional'
                            odataType   = 'String | Optional | microsoft.graph.appleAppListItem'
                        }
                    )
                }
            )
            DeviceConfigurationPoliciesWindows10                              = @(
                @{
                    Assignments                      = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    EdgeSearchEngine                 = @{
                        EdgeSearchEngineOpenSearchXmlUrl = 'String | Optional'
                        EdgeSearchEngineType             = 'String | Optional | default / bing'
                        odataType                        = 'String | Optional | microsoft.graph.edgeSearchEngine / microsoft.graph.edgeSearchEngineCustom'
                    }
                    EdgeHomeButtonConfiguration      = @{
                        odataType           = 'String | Optional | microsoft.graph.edgeHomeButtonHidden / microsoft.graph.edgeHomeButtonLoadsStartPage / microsoft.graph.edgeHomeButtonOpensCustomURL / microsoft.graph.edgeHomeButtonOpensNewTab'
                        HomeButtonCustomURL = 'String | Optional'
                    }
                    Windows10AppsForceUpdateSchedule = @{
                        RunImmediatelyIfAfterStartDateTime = 'Boolean | Optional'
                        Recurrence                         = 'String | Optional | none / daily / weekly / monthly'
                        StartDateTime                      = 'String | Optional'
                    }
                    NetworkProxyServer               = @{
                        UseForLocalAddresses = 'Boolean | Optional'
                        Exceptions           = 'StringArray | Optional'
                        Address              = 'String | Optional'
                    }
                    DefenderDetectedMalwareActions   = @{
                        LowSeverity      = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                        SevereSeverity   = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                        ModerateSeverity = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                        HighSeverity     = 'String | Optional | deviceDefault / clean / quarantine / remove / allow / userDefined / block'
                    }
                }
            )
            DeviceConfigurationScepCertificatePoliciesWindows10               = @(
                @{
                    ExtendedKeyUsages             = @(
                        @{
                            ObjectIdentifier = 'String | Optional'
                            Name             = 'String | Optional'
                        }
                    )
                    Assignments                   = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    CustomSubjectAlternativeNames = @(
                        @{
                            SanType = 'String | Optional | none / emailAddress / userPrincipalName / customAzureADAttribute / domainNameService / universalResourceIdentifier'
                            Name    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationSecureAssessmentPoliciesWindows10              = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationSharedMultiDevicePoliciesWindows10             = @(
                @{
                    AccountManagerPolicy = @{
                        InactiveThresholdDays                 = 'UInt32 | Optional'
                        CacheAccountsAboveDiskFreePercentage  = 'UInt32 | Optional'
                        AccountDeletionPolicy                 = 'String | Optional | immediate / diskSpaceThreshold / diskSpaceThresholdOrInactiveThreshold'
                        RemoveAccountsBelowDiskFreePercentage = 'UInt32 | Optional'
                    }
                    Assignments          = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationTrustedCertificatePoliciesWindows10            = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationVpnPoliciesWindows10                           = @(
                @{
                    Assignments       = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    ServerCollection  = @(
                        @{
                            IsDefaultServer = 'Boolean | Optional'
                            Description     = 'String | Optional'
                            Address         = 'String | Optional'
                        }
                    )
                    CryptographySuite = @{
                        CipherTransformConstants         = 'String | Optional | aes256 / des / tripleDes / aes128 / aes128Gcm / aes256Gcm / aes192 / aes192Gcm / chaCha20Poly1305'
                        EncryptionMethod                 = 'String | Optional | aes256 / des / tripleDes / aes128 / aes128Gcm / aes256Gcm / aes192 / aes192Gcm / chaCha20Poly1305'
                        PfsGroup                         = 'String | Optional | pfs1 / pfs2 / pfs2048 / ecp256 / ecp384 / pfsMM / pfs24'
                        DhGroup                          = 'String | Optional | group1 / group2 / group14 / ecp256 / ecp384 / group24'
                        IntegrityCheckMethod             = 'String | Optional | sha2_256 / sha1_96 / sha1_160 / sha2_384 / sha2_512 / md5'
                        AuthenticationTransformConstants = 'String | Optional | md5_96 / sha1_96 / sha_256_128 / aes128Gcm / aes192Gcm / aes256Gcm'
                    }
                    SingleSignOnEku   = @{
                        ObjectIdentifier = 'String | Optional'
                        Name             = 'String | Optional'
                    }
                    ProxyServer       = @{
                        BypassProxyServerForLocalAddress = 'Boolean | Optional'
                        Address                          = 'String | Optional'
                        AutomaticConfigurationScriptUrl  = 'String | Optional'
                        AutomaticallyDetectProxySettings = 'Boolean | Optional'
                        Port                             = 'UInt32 | Optional'
                        odataType                        = 'String | Optional | microsoft.graph.windows10VpnProxyServer / microsoft.graph.windows81VpnProxyServer'
                    }
                    AssociatedApps    = @(
                        @{
                            Identifier = 'String | Optional'
                            AppType    = 'String | Optional | desktop / universal'
                        }
                    )
                    DnsRules          = @(
                        @{
                            Servers        = 'StringArray | Optional'
                            ProxyServerUri = 'String | Optional'
                            Name           = 'String | Optional'
                            Persistent     = 'Boolean | Optional'
                            AutoTrigger    = 'Boolean | Optional'
                        }
                    )
                    TrafficRules      = @(
                        @{
                            RemotePortRanges    = @(
                                @{
                                    LowerNumber = 'UInt32 | Optional'
                                    UpperNumber = 'UInt32 | Optional'
                                }
                            )
                            Name                = 'String | Optional'
                            AppId               = 'String | Optional'
                            LocalPortRanges     = @(
                                @{
                                    LowerNumber = 'UInt32 | Optional'
                                    UpperNumber = 'UInt32 | Optional'
                                }
                            )
                            AppType             = 'String | Optional | none / desktop / universal'
                            LocalAddressRanges  = @(
                                @{
                                    CidrAddress  = 'String | Optional'
                                    UpperAddress = 'String | Optional'
                                    LowerAddress = 'String | Optional'
                                    odataType    = 'String | Optional | microsoft.graph.iPv4CidrRange / microsoft.graph.iPv6CidrRange / microsoft.graph.iPv4Range / microsoft.graph.iPv6Range'
                                }
                            )
                            RemoteAddressRanges = @(
                                @{
                                    CidrAddress  = 'String | Optional'
                                    UpperAddress = 'String | Optional'
                                    LowerAddress = 'String | Optional'
                                    odataType    = 'String | Optional | microsoft.graph.iPv4CidrRange / microsoft.graph.iPv6CidrRange / microsoft.graph.iPv4Range / microsoft.graph.iPv6Range'
                                }
                            )
                            Claims              = 'String | Optional'
                            Protocols           = 'UInt32 | Optional'
                            RoutingPolicyType   = 'String | Optional | none / splitTunnel / forceTunnel'
                            VpnTrafficDirection = 'String | Optional | outbound / inbound / unknownFutureValue'
                        }
                    )
                    Routes            = @(
                        @{
                            PrefixSize        = 'UInt32 | Optional'
                            DestinationPrefix = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationWindowsTeamPoliciesWindows10                   = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceConfigurationWiredNetworkPoliciesWindows10                  = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            DeviceEnrollmentLimitRestrictions                                 = @(
                @{}
            )
            DeviceEnrollmentPlatformRestrictions                              = @(
                @{
                    Assignments               = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    WindowsHomeSkuRestriction = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    AndroidRestriction        = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    IosRestriction            = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    WindowsRestriction        = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    AndroidForWorkRestriction = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    MacOSRestriction          = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    WindowsMobileRestriction  = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                    MacRestriction            = @{
                        PlatformBlocked                 = 'Boolean | Optional'
                        OsMinimumVersion                = 'String | Optional'
                        BlockedSkus                     = 'StringArray | Optional'
                        BlockedManufacturers            = 'StringArray | Optional'
                        OsMaximumVersion                = 'String | Optional'
                        PersonalDeviceEnrollmentBlocked = 'Boolean | Optional'
                    }
                }
            )
            DeviceEnrollmentStatusPageWindows10s                              = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            EndpointDetectionAndResponsePoliciesWindows10                     = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            ExploitProtectionPoliciesWindows10SettingCatalog                  = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            PoliciesSets                                                      = @(
                @{
                    Items       = @(
                        @{
                            guidedDeploymentTags = 'StringArray | Optional'
                            payloadId            = 'String | Optional'
                            displayName          = 'String | Optional'
                            dataType             = 'String | Optional'
                            itemType             = 'String | Optional'
                        }
                    )
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            RoleAssignments                                                   = @(
                @{}
            )
            RoleDefinitions                                                   = @(
                @{}
            )
            SettingCatalogASRRulesPoliciesWindows10                           = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            SettingCatalogCustomPoliciesWindows10                             = @(
                @{
                    Assignments       = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                    TemplateReference = @{
                        TemplateId             = 'String | Optional'
                        TemplateDisplayVersion = 'String | Optional'
                        TemplateDisplayName    = 'String | Optional'
                        TemplateFamily         = 'String | Optional | none / endpointSecurityAntivirus / endpointSecurityDiskEncryption / endpointSecurityFirewall / endpointSecurityEndpointDetectionAndResponse / endpointSecurityAttackSurfaceReduction / endpointSecurityAccountProtection / endpointSecurityApplicationControl / endpointSecurityEndpointPrivilegeManagement / enrollmentConfiguration / appQuietTime / baseline / unknownFutureValue / deviceConfigurationScripts'
                    }
                    Settings          = @(
                        @{
                            Id              = 'String | Optional'
                            SettingInstance = @{
                                SimpleSettingCollectionValue     = @(
                                    @{
                                        StringValue                   = 'String | Optional'
                                        ValueState                    = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                        IntValue                      = 'UInt32 | Optional'
                                        SettingValueTemplateReference = @{
                                            useTemplateDefault     = 'Boolean | Optional'
                                            settingValueTemplateId = 'String | Optional'
                                        }
                                        Children                      = @(
                                            @{
                                                SimpleSettingCollectionValue     = @(
                                                    @{
                                                        odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                        IntValue    = 'UInt32 | Optional'
                                                        ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                        StringValue = 'String | Optional'
                                                    }
                                                )
                                                SettingDefinitionId              = 'String | Optional'
                                                odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                                ChoiceSettingCollectionValue     = @(
                                                    @{
                                                        odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                        Value     = 'String | Optional'
                                                    }
                                                )
                                                GroupSettingValue                = @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                                SettingInstanceTemplateReference = @{
                                                    SettingInstanceTemplateId = 'String | Optional'
                                                }
                                                SimpleSettingValue               = @{
                                                    odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                    IntValue    = 'UInt32 | Optional'
                                                    ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                    StringValue = 'String | Optional'
                                                }
                                                ChoiceSettingValue               = @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                                GroupSettingCollectionValue      = @(
                                                    @{
                                                        odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                        Value     = 'String | Optional'
                                                    }
                                                )
                                            }
                                        )
                                        odataType                     = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                    }
                                )
                                SettingDefinitionId              = 'String | Optional'
                                odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                ChoiceSettingCollectionValue     = @(
                                    @{
                                        SettingValueTemplateReference = @{
                                            useTemplateDefault     = 'Boolean | Optional'
                                            settingValueTemplateId = 'String | Optional'
                                        }
                                        odataType                     = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                        Value                         = 'String | Optional'
                                        Children                      = @(
                                            @{
                                                SimpleSettingCollectionValue     = @(
                                                    @{
                                                        odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                        IntValue    = 'UInt32 | Optional'
                                                        ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                        StringValue = 'String | Optional'
                                                    }
                                                )
                                                SettingDefinitionId              = 'String | Optional'
                                                odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                                ChoiceSettingCollectionValue     = @(
                                                    @{
                                                        odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                        Value     = 'String | Optional'
                                                    }
                                                )
                                                GroupSettingValue                = @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                                SettingInstanceTemplateReference = @{
                                                    SettingInstanceTemplateId = 'String | Optional'
                                                }
                                                SimpleSettingValue               = @{
                                                    odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                    IntValue    = 'UInt32 | Optional'
                                                    ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                    StringValue = 'String | Optional'
                                                }
                                                ChoiceSettingValue               = @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                                GroupSettingCollectionValue      = @(
                                                    @{
                                                        odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                        Value     = 'String | Optional'
                                                    }
                                                )
                                            }
                                        )
                                    }
                                )
                                GroupSettingValue                = @{
                                    odataType                     = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                    Value                         = 'String | Optional'
                                    SettingValueTemplateReference = @{
                                        useTemplateDefault     = 'Boolean | Optional'
                                        settingValueTemplateId = 'String | Optional'
                                    }
                                    Children                      = @(
                                        @{
                                            SimpleSettingCollectionValue     = @(
                                                @{
                                                    odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                    IntValue    = 'UInt32 | Optional'
                                                    ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                    StringValue = 'String | Optional'
                                                }
                                            )
                                            SettingDefinitionId              = 'String | Optional'
                                            odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                            ChoiceSettingCollectionValue     = @(
                                                @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                            )
                                            GroupSettingValue                = @{
                                                odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                Value     = 'String | Optional'
                                            }
                                            SettingInstanceTemplateReference = @{
                                                SettingInstanceTemplateId = 'String | Optional'
                                            }
                                            SimpleSettingValue               = @{
                                                odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                IntValue    = 'UInt32 | Optional'
                                                ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                StringValue = 'String | Optional'
                                            }
                                            ChoiceSettingValue               = @{
                                                odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                Value     = 'String | Optional'
                                            }
                                            GroupSettingCollectionValue      = @(
                                                @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                            )
                                        }
                                    )
                                }
                                SettingInstanceTemplateReference = @{
                                    SettingInstanceTemplateId = 'String | Optional'
                                }
                                SimpleSettingValue               = @{
                                    StringValue                   = 'String | Optional'
                                    ValueState                    = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                    IntValue                      = 'UInt32 | Optional'
                                    SettingValueTemplateReference = @{
                                        useTemplateDefault     = 'Boolean | Optional'
                                        settingValueTemplateId = 'String | Optional'
                                    }
                                    Children                      = @(
                                        @{
                                            SimpleSettingCollectionValue     = @(
                                                @{
                                                    odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                    IntValue    = 'UInt32 | Optional'
                                                    ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                    StringValue = 'String | Optional'
                                                }
                                            )
                                            SettingDefinitionId              = 'String | Optional'
                                            odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                            ChoiceSettingCollectionValue     = @(
                                                @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                            )
                                            GroupSettingValue                = @{
                                                odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                Value     = 'String | Optional'
                                            }
                                            SettingInstanceTemplateReference = @{
                                                SettingInstanceTemplateId = 'String | Optional'
                                            }
                                            SimpleSettingValue               = @{
                                                odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                IntValue    = 'UInt32 | Optional'
                                                ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                StringValue = 'String | Optional'
                                            }
                                            ChoiceSettingValue               = @{
                                                odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                Value     = 'String | Optional'
                                            }
                                            GroupSettingCollectionValue      = @(
                                                @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                            )
                                        }
                                    )
                                    odataType                     = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                }
                                ChoiceSettingValue               = @{
                                    SettingValueTemplateReference = @{
                                        useTemplateDefault     = 'Boolean | Optional'
                                        settingValueTemplateId = 'String | Optional'
                                    }
                                    odataType                     = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                    Value                         = 'String | Optional'
                                    Children                      = @(
                                        @{
                                            SimpleSettingCollectionValue     = @(
                                                @{
                                                    odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                    IntValue    = 'UInt32 | Optional'
                                                    ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                    StringValue = 'String | Optional'
                                                }
                                            )
                                            SettingDefinitionId              = 'String | Optional'
                                            odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                            ChoiceSettingCollectionValue     = @(
                                                @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                            )
                                            GroupSettingValue                = @{
                                                odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                Value     = 'String | Optional'
                                            }
                                            SettingInstanceTemplateReference = @{
                                                SettingInstanceTemplateId = 'String | Optional'
                                            }
                                            SimpleSettingValue               = @{
                                                odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                IntValue    = 'UInt32 | Optional'
                                                ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                StringValue = 'String | Optional'
                                            }
                                            ChoiceSettingValue               = @{
                                                odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                Value     = 'String | Optional'
                                            }
                                            GroupSettingCollectionValue      = @(
                                                @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                            )
                                        }
                                    )
                                }
                                GroupSettingCollectionValue      = @(
                                    @{
                                        odataType                     = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                        Value                         = 'String | Optional'
                                        SettingValueTemplateReference = @{
                                            useTemplateDefault     = 'Boolean | Optional'
                                            settingValueTemplateId = 'String | Optional'
                                        }
                                        Children                      = @(
                                            @{
                                                SimpleSettingCollectionValue     = @(
                                                    @{
                                                        odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                        IntValue    = 'UInt32 | Optional'
                                                        ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                        StringValue = 'String | Optional'
                                                    }
                                                )
                                                SettingDefinitionId              = 'String | Optional'
                                                odataType                        = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationChoiceSettingInstance / microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationGroupSettingInstance / microsoft.graph.deviceManagementConfigurationSettingGroupCollectionInstance / microsoft.graph.deviceManagementConfigurationSettingGroupInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance / microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'
                                                ChoiceSettingCollectionValue     = @(
                                                    @{
                                                        odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                        Value     = 'String | Optional'
                                                    }
                                                )
                                                GroupSettingValue                = @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                                SettingInstanceTemplateReference = @{
                                                    SettingInstanceTemplateId = 'String | Optional'
                                                }
                                                SimpleSettingValue               = @{
                                                    odataType   = 'String | Optional | microsoft.graph.deviceManagementConfigurationIntegerSettingValue / microsoft.graph.deviceManagementConfigurationStringSettingValue / microsoft.graph.deviceManagementConfigurationSecretSettingValue'
                                                    IntValue    = 'UInt32 | Optional'
                                                    ValueState  = 'String | Optional | invalid / notEncrypted / encryptedValueToken'
                                                    StringValue = 'String | Optional'
                                                }
                                                ChoiceSettingValue               = @{
                                                    odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                    Value     = 'String | Optional'
                                                }
                                                GroupSettingCollectionValue      = @(
                                                    @{
                                                        odataType = 'String | Optional | microsoft.graph.deviceManagementConfigurationChoiceSettingValue / microsoft.graph.deviceManagementConfigurationGroupSettingValue / microsoft.graph.deviceManagementConfigurationSimpleSettingValue'
                                                        Value     = 'String | Optional'
                                                    }
                                                )
                                            }
                                        )
                                    }
                                )
                            }
                        }
                    )
                }
            )
            WiFiConfigurationPoliciesAndroidDeviceAdministrator               = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesAndroidEnterpriseDeviceOwner             = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesAndroidEnterpriseWorkProfile             = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesAndroidForWork                           = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesAndroidOpenSourceProject                 = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesIOS                                      = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesMacOS                                    = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WifiConfigurationPoliciesWindows10                                = @(
                @{
                    Assignments = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WindowsAutopilotDeploymentProfilesAzureADHybridJoined             = @(
                @{
                    OutOfBoxExperienceSettings     = @{
                        HideEULA                  = 'Boolean | Optional'
                        HideEscapeLink            = 'Boolean | Optional'
                        HidePrivacySettings       = 'Boolean | Optional'
                        DeviceUsageType           = 'String | Optional | singleUser / shared'
                        SkipKeyboardSelectionPage = 'Boolean | Optional'
                        UserType                  = 'String | Optional | administrator / standard'
                    }
                    EnrollmentStatusScreenSettings = @{
                        HideInstallationProgress                         = 'Boolean | Optional'
                        BlockDeviceSetupRetryByUser                      = 'Boolean | Optional'
                        AllowLogCollectionOnInstallFailure               = 'Boolean | Optional'
                        AllowDeviceUseBeforeProfileAndAppInstallComplete = 'Boolean | Optional'
                        InstallProgressTimeoutInMinutes                  = 'UInt32 | Optional'
                        CustomErrorMessage                               = 'String | Optional'
                        AllowDeviceUseOnInstallFailure                   = 'Boolean | Optional'
                    }
                    Assignments                    = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WindowsAutopilotDeploymentProfilesAzureADJoined                   = @(
                @{
                    OutOfBoxExperienceSettings     = @{
                        HideEULA                  = 'Boolean | Optional'
                        HideEscapeLink            = 'Boolean | Optional'
                        HidePrivacySettings       = 'Boolean | Optional'
                        DeviceUsageType           = 'String | Optional | singleUser / shared'
                        SkipKeyboardSelectionPage = 'Boolean | Optional'
                        UserType                  = 'String | Optional | administrator / standard'
                    }
                    EnrollmentStatusScreenSettings = @{
                        HideInstallationProgress                         = 'Boolean | Optional'
                        BlockDeviceSetupRetryByUser                      = 'Boolean | Optional'
                        AllowLogCollectionOnInstallFailure               = 'Boolean | Optional'
                        AllowDeviceUseBeforeProfileAndAppInstallComplete = 'Boolean | Optional'
                        InstallProgressTimeoutInMinutes                  = 'UInt32 | Optional'
                        CustomErrorMessage                               = 'String | Optional'
                        AllowDeviceUseOnInstallFailure                   = 'Boolean | Optional'
                    }
                    Assignments                    = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WindowsInformationProtectionPoliciesWindows10MdmEnrolled          = @(
                @{
                    EnterpriseProxyServers         = @(
                        @{
                            DisplayName = 'String | Optional'
                            Resources   = 'StringArray | Optional'
                        }
                    )
                    EnterpriseProxiedDomains       = @(
                        @{
                            DisplayName    = 'String | Optional'
                            ProxiedDomains = @(
                                @{
                                    Proxy           = 'String | Optional'
                                    IpAddressOrFQDN = 'String | Optional'
                                }
                            )
                        }
                    )
                    EnterpriseInternalProxyServers = @(
                        @{
                            DisplayName = 'String | Optional'
                            Resources   = 'StringArray | Optional'
                        }
                    )
                    SmbAutoEncryptedFileExtensions = @(
                        @{
                            DisplayName = 'String | Optional'
                            Resources   = 'StringArray | Optional'
                        }
                    )
                    EnterpriseProtectedDomainNames = @(
                        @{
                            DisplayName = 'String | Optional'
                            Resources   = 'StringArray | Optional'
                        }
                    )
                    ProtectedApps                  = @(
                        @{
                            BinaryVersionLow  = 'String | Optional'
                            Description       = 'String | Optional'
                            odataType         = 'String | Optional | microsoft.graph.windowsInformationProtectionDesktopApp / microsoft.graph.windowsInformationProtectionStoreApp'
                            BinaryName        = 'String | Optional'
                            BinaryVersionHigh = 'String | Optional'
                            Denied            = 'Boolean | Optional'
                            PublisherName     = 'String | Optional'
                            ProductName       = 'String | Optional'
                            DisplayName       = 'String | Optional'
                        }
                    )
                    DataRecoveryCertificate        = @{
                        Description        = 'String | Optional'
                        SubjectName        = 'String | Optional'
                        ExpirationDateTime = 'String | Optional'
                        Certificate        = 'String | Optional'
                    }
                    EnterpriseNetworkDomainNames   = @(
                        @{
                            DisplayName = 'String | Optional'
                            Resources   = 'StringArray | Optional'
                        }
                    )
                    ExemptApps                     = @(
                        @{
                            BinaryVersionLow  = 'String | Optional'
                            Description       = 'String | Optional'
                            odataType         = 'String | Optional | microsoft.graph.windowsInformationProtectionDesktopApp / microsoft.graph.windowsInformationProtectionStoreApp'
                            BinaryName        = 'String | Optional'
                            BinaryVersionHigh = 'String | Optional'
                            Denied            = 'Boolean | Optional'
                            PublisherName     = 'String | Optional'
                            ProductName       = 'String | Optional'
                            DisplayName       = 'String | Optional'
                        }
                    )
                    EnterpriseIPRanges             = @(
                        @{
                            DisplayName = 'String | Optional'
                            Ranges      = @(
                                @{
                                    CidrAddress  = 'String | Optional'
                                    UpperAddress = 'String | Optional'
                                    LowerAddress = 'String | Optional'
                                    odataType    = 'String | Optional | microsoft.graph.iPv4CidrRange / microsoft.graph.iPv6CidrRange / microsoft.graph.iPv4Range / microsoft.graph.iPv6Range'
                                }
                            )
                        }
                    )
                    NeutralDomainResources         = @(
                        @{
                            DisplayName = 'String | Optional'
                            Resources   = 'StringArray | Optional'
                        }
                    )
                }
            )
            WindowsUpdateForBusinessFeatureUpdateProfilesWindows10            = @(
                @{
                    RolloutSettings = @{
                        OfferEndDateTimeInUTC   = 'String | Optional'
                        OfferStartDateTimeInUTC = 'String | Optional'
                        OfferIntervalInDays     = 'UInt32 | Optional'
                    }
                    Assignments     = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WindowsUpdateForBusinessRingUpdateProfilesWindows10               = @(
                @{
                    InstallationSchedule = @{
                        ActiveHoursStart     = 'String | Optional'
                        ScheduledInstallTime = 'String | Optional'
                        ScheduledInstallDay  = 'String | Optional | userDefined / everyday / sunday / monday / tuesday / wednesday / thursday / friday / saturday / noScheduledScan'
                        ActiveHoursEnd       = 'String | Optional'
                        odataType            = 'String | Optional | microsoft.graph.windowsUpdateActiveHoursInstall / microsoft.graph.windowsUpdateScheduledInstall'
                    }
                    Assignments          = @(
                        @{
                            deviceAndAppManagementAssignmentFilterType = 'String | Optional | none / include / exclude'
                            collectionId                               = 'String | Optional'
                            dataType                                   = 'String | Optional | microsoft.graph.groupAssignmentTarget / microsoft.graph.allLicensedUsersAssignmentTarget / microsoft.graph.allDevicesAssignmentTarget / microsoft.graph.exclusionGroupAssignmentTarget / microsoft.graph.configurationManagerCollectionAssignmentTarget'
                            deviceAndAppManagementAssignmentFilterId   = 'String | Optional'
                            groupId                                    = 'String | Optional'
                        }
                    )
                }
            )
            WindowsUpdateForBusinessRingUpdateProfileWindows10s               = @(
                @{}
            )
        }#>
    }
}
