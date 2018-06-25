Function New-AwsSecurityStack {
<#
.SYNOPSIS

Creates a new AWS VCD stack on the f5 load balancer from a specified Jira Ticket.
Scrapes the parameters from tickets that look like

Actions:
  User Account Creation:
    Owner/Manager: [3]Smith, Hayden [USA]
    Technical POC: [4]Smith, Hayden [USA]
    Project Admin: [5]Smith, Hayden [USA]
    Project Admin: [6]Grebbien, Danielle [USA]
    Create a CSN AD security group named: AWS_293853093962

AWS Security Information:
  AWS Account #: 293853093962
  Environment ID: CSN-ENV-C-168
  Environment CSR EIP: 34.200.66.43
  Environment CSR Internal IP: 10.194.83.148
  Security Stack VPC CIDR: 10.194.83.128/25
  User Private Subnet: 10.194.83.192/26

.PARAMETER crnumber

CR Number from Jira in the format "4340"


.EXAMPLE




#>
    [cmdletBinding()]
    param(
        
        [Alias("existing acl Name")]
        [Parameter(Mandatory=$true)]
        [string]$crnumber='',
        [Parameter(Mandatory=$true)]
        [string]$ip='10.219.1.183'

        )

begin {

    #Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'  first time jira setup

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Output "Please enter your Jira credentials."

    $creds = Get-credential

    $jiraSesh = New-JiraSession -Credential $creds -ErrorAction Stop

     if( [string]::IsNullOrEmpty($jiraSesh) ) {
 
         Write-Warning "Jira session has expired, or bad username and password."
 
         break
 
     }

   $newEnv = Get-JiraTicketInfo -crNumber "CR-$crnumber"

     if( [string]::IsNullOrEmpty($newEnv) ) {
 
         Write-Warning "Jira was unable to locate ticked based on $crNumber"
 
         break
 
     }
        try{
                
                Write-Output "Please enter you F5 credentials."
                Connect-F5 -ip $ip -ErrorAction Stop 

        }

        catch{

               Write-Warning "F5 was unable to connect please check your username, password, and network connection."
               $_.Exception.Message
               break

            }


            try {
            New-DefaultAcl -name $newEnv.aws_group -subnet $newEnv.subnet -ErrorAction Stop
            }
            catch {
            Write-Error "Adding ACL failed."
            $_.Exception.Message
            break
            }

                #change for prod

            try {
                Add-APMRole -name "aggregate_acl_act_full_resource_assign_ag" -acl $newEnv.aws_group -group $newEnv.aws_group -ErrorAction stop
            }

            catch{
                Write-Warning "Mapping ACL to VPN role failed."
                $_.Exception.Message
                break
                }

            Update-APMPolicy -name "CSN_VPN_Streamlined" -ErrorAction Stop

            Sync-DeviceToGroup -GroupName "Sync_Group"

}
#NEED TO Create a CASCADING ORDER TO PREVENT Fuckups

