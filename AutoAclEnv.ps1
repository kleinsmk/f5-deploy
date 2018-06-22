#Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'  first time jira setup

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$creds = Get-credential

 $jiraSesh = New-JiraSession -Credential $creds -ErrorAction Stop

 if( [string]::IsNullOrEmpty($jiraSesh) ) {
 
 Write-Warning "Jira session has expired or no longer exists"
 
 break
 
 }

    $newEnv = Get-JiraTicketInfo -crNumber "CR-3787"

    if( [string]::IsNullOrEmpty($newEnv) ) {
 
 Write-Warning "Jira was unable to locate ticked based on $crNumber"
 
 break
 
 }
        
        #Connect-F5 -ip $ip -ErrorAction Stop 

            New-DefaultAcl -name $newEnv.aws_group -subnet $newEnv.subnet -ErrorAction Stop

                #change for prod
                Add-APMRole -name "aggregate_acl_act_full_resource_assign_ag" -acl $newEnv.aws_group -group $newEnv.aws_group -ErrorAction stop

                    Update-APMPolicy -name "CSN_VPN_Streamlined" -ErrorAction Stop

#Sync-DeviceToGroup -GroupName "Sync_Group"


#NEED TO Create a CASCADING ORDER TO PREVENT Fuckups

