<#
.SYNOPSIS
        Creates Removal commands for New-F5 stack.
.DESCRIPTION
        This is a private funciton.  Will need to explore migrating this to a true private folder.
#>
function Generate-RemovalCmds {

        @"

                Removal Commands

Remove-iRuleFromVirtualServer -Name '$wsa' -iRuleName '${vsname}'
Remove-iRule -Name '${vsname}' -Confirm:`$false
Remove-VirtualServer -Name ${vsName} -Confirm:`$false
Remove-Pool -PoolName ${vsName} -Confirm:`$false
Remove-Node -Name ${nodeName} -Confirm:`$false
Remove-Asm -policyname ${asmPolicyName} -Confirm:`$false
"@

if ( -not [string]::IsNullOrEmpty($sslClientProfile) ){
"Remove-SSLClient -profileName $sslClientProfile"
}

if ( -not [string]::IsNullOrEmpty($SSLServerProfile) -and ($SSLServerProfile -ne "serverssl") ){
"Remove-SSLServer -profileName $SSLServerProfile"
}



 
}