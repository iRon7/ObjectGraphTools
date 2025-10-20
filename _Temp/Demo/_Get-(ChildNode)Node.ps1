$Soesterberg = Import-PowerShellDataFile $PSScriptRoot\Soesterberg.psd1 -SkipLimitCheck

$Soesterberg.AllNodes.NodeName = 'localhost2' # InvalidOperation: The property 'NodeName' cannot be found on this object. Verify that the property exists and can be set.

$Soesterberg | Get-ChildNode
$Soesterberg | Get-ChildNode NodeName -Recurse

$Soesterberg | Get-ChildNode *Group* -Recurse
$Soesterberg | Get-ChildNode *Group* -Recurse -Leaf

$Soesterberg.NonNodeData.Teams.GroupPoliciesAssignment[0].GroupDisplayName
$MyGroupNode = $Soesterberg | Get-Node NonNodeData.Teams.GroupPoliciesAssignment[0].GroupDisplayName
$MyGroupNode | Select-Object *
$MyGroupNode.ParentNode | Select-Object *
$MyGroupNode.ParentNode.ChildNodes

$Soesterberg | Get-Node ~UniqueId
$Soesterberg | Get-Node ~UniqueId=AllMailTips
$Soesterberg | Get-Node ~UniqueId=AllMailTips..Organization
$MailOrg = $Soesterberg | Get-Node ~UniqueId=AllMailTips..Organization
$MailOrg.Value
$MailOrg.Value = 'gouda.onmicrosoft.com'

$Soesterberg | ConvertTo-Expression

$MailOrg.PSNodeType
$MailOrg | Get-Member

$MailOrg.ParentNode
$MailOrg.ParentNode.PSNodeType
$MailOrg.ParentNode | Get-Member

$MailOrg.ParentNode.Add('Foo', 'Bar')
$MailOrg.ParentNode.Remove('Foo')

$Test = $Soesterberg | Copy-ObjectGraph
$Soesterberg | ConvertTo-Expression -LanguageMode Full
$Test = $Soesterberg | Copy-ObjectGraph -MapAs PSCustomObject
$Test | ConvertTo-Expression -LanguageMode Full



# UniqueID