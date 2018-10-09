function Generate-RemovalCmds {

        @"

                Removal Commands

Remove-iRuleFromVirtualServer -Name '$wsa' -iRuleName '${vsname}'
Remove-iRule -Name '${vsname}' -Confirm:`$false
Remove-VirtualServer -Name ${vsName} -Confirm:`$false
Remove-Pool -PoolName ${vsName} -Confirm:`$false
"@

 
}