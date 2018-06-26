function New-AwsSecurityStack {
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
  [CmdletBinding()]
  param(

    [Alias("existing acl Name")]
    [Parameter(Mandatory = $true)]
    [string]$crnumber = '',

    [Parameter(Mandatory = $true)]
    [string]$f5ip = '10.219.1.183',

    [Validateset('dev', 'prod')]
    [Parameter(Mandatory = $false)]
    [string]$role = 'dev'

  )

  process {

    #Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'  first time jira setup

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if( $role -eq 'dev' ){ 
        $vpnrole = "aggregate_acl_act_full_resource_assign_ag"
    }

    else { $vpnrole = "acl_1_act_full_resource_assign_ag" }

    Write-Output "Please enter your Jira credentials."

    $creds = Get-Credential -Message "Please enter credentials to access Jira"

    $jiraSesh = New-JiraSession -Credential $creds -ErrorAction Stop

    if ([string]::IsNullOrEmpty($jiraSesh)) {

      Write-Warning "Jira session has expired, or bad username and password."

      break

    }

    $newEnv = Get-JiraTicketInfo -crNumber "CR-$crnumber"

    if ([string]::IsNullOrEmpty($newEnv)) {

      Write-Warning "Jira was unable to locate ticked based on $crNumber"

      break

    }
    try {

      Write-Output "Please enter you F5 credentials."
      Connect-F5 -ip $f5ip -ErrorAction Stop

    }

    catch {

      Write-Warning "F5 was unable to connect please check your username, password, and network connection."
      $_.Exception.Message
      break

    }


    try {
      Write-Output "Adding new ACL......"
      New-DefaultAcl -Name $newEnv.aws_group -subnet $newEnv.subnet -ErrorAction Stop
      Write-Output "Added $newEnv.aws_group with subnet $newEnv.subnet"
    }
    catch {
      Write-Error "Adding ACL failed."
      $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Mapping ACl to VPN access role......"
      Add-APMRole -Name $vpnrole -acl $newEnv.aws_group -group $newEnv.aws_group -ErrorAction stop
      Write-Output "Mapped ACL $newEnv.aws_group to group  $newEnv.subnet."
    }

    catch {
      Write-Warning "Mapping ACL to VPN role failed."
      $_.Exception.Message
      Write-Output "Rolling back changes......"
      Remove-Acl -name $newEnv.aws_group
      Write-Output "ACL $newEnv.aws_group has been removed."
      break
    }

    Write-Output "Apply APM Policy......"

    try{
      Update-APMPolicy -Name "CSN_VPN_Streamlined" -ErrorAction Stop
      Write-Output "Policy Applied"
    }

    catch{
      Write-Warning "Updating APM Policy failed."
      $_.Exception.Message
      break
    }

    try{
      Write-Output "Syncing Device to Group......"
      Sync-DeviceToGroup -GroupName "Sync_Group"
      Write-Output "Synced"
    }
    catch{
      Write-Warning "Syncing Device to Group failed."
      $_.Exception.Message
      break
    }
  }
  
}
