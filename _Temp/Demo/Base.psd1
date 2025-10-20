@{
    AllNodes    = @(
        @{
            NodeName        = 'localhost'
            CertificateFile = '.\DSCCertificate.cer'
        }
    )

    NonNodeData = @{
        Exchange = @{
            OrganizationConfig     = @{
                ActivityBasedAuthenticationTimeoutEnabled                 = $true
                ActivityBasedAuthenticationTimeoutInterval                = '06:00:00'
                ActivityBasedAuthenticationTimeoutWithSingleSignOnEnabled = $true
                AppsForOfficeEnabled                                      = $true
            }
            AuthenticationPolicies = @(
                @{
                    Identity                   = 'BlockBasic637775045994108741'
                    AllowBasicAuthActiveSync   = $false
                    AllowBasicAuthAutodiscover = $false
                    AllowBasicAuthImap         = $true
                    Ensure                     = 'Present'
                }
            )
            CASMailboxPlans        = @(
                @{
                    Identity         = 'ExchangeOnlineEnterprise-4aad1894-b847-4488-bb47-df02c2f2aef4'
                    ImapEnabled      = $false
                    OwaMailboxPolicy = 'OwaMailboxPolicy-Default'

                }
                @{
                    Identity         = 'ExchangeOnlineDeskless-3967a644-75e7-44fc-a644-ce517aa649b3'
                    ImapEnabled      = $false
                    OwaMailboxPolicy = 'OwaMailboxPolicy-Default'
                }
            )
        }
    }
}