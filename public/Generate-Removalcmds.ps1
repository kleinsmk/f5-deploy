function Generate-RemovalCmds {

        @"

                Removal Commands

Remove-iRuleFromVirtualServer -Name '$wsa' -iRuleName '${vsname}'
Remove-iRule -Name '${vsname}' -Confirm:`$false
Remove-VirtualServer -Name ${vsName} -Confirm:`$false
Remove-Pool -PoolName ${vsName} -Confirm:`$false
"@

if ( -not [string]::IsNullOrEmpty($sslClientProfile) ){
"Remove-SSLClient -profileName $sslClientProfile"
}

if ( -not [string]::IsNullOrEmpty($SSLServerProfile) -and ($SSLServerProfile -ne "serverssl") ){
"Remove-SSLServer -profileName $SSLServerProfile"
}



 
}