function New-VcdDeployment {
<#
.SYNOPSIS

Creates a new project VPN config from a specified Jira Ticket.  Currently only works iwth single subnet projects.
Scrapes the parameters from tickets that look like

Actions:
    Create a CSN AD security group named: AWS_293853093962

AWS Security Information:
  User Private Subnet: 10.194.83.192/26

.PARAMETER crnumber

CR Number from Jira in the format "CR-4340"

.PARAMETER f5creds

Powershell crednetial object containing F5 login credentials

.PARAMETER jiracreds

Powershell crednetial object containing F5 login credentials

.PARAMETER onpremf5ip

IP or DNS of onpremise F5 device.  Defaults to onpremf5.boozallencsn.com and generally can be omitted.

.PARAMETER awsf5ip

IP or DNS of AWS F5 device in VCD.  Defaults to ec2f5.boozallencsn.com and generally can be omitted.

.PARAMETER role

Switch paramter for dev or prod.  Defaults to prod if omitted.

.EXAMPLE

New-AwsSecurityStack -crNumber "CR-4509" -f5creds $saved_credentials -jiracreds $save_jiracreds
.Notes

  It is required that the jirasever have been set using JiraPS module Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'

#>
  [CmdletBinding()]
  param(

    [Alias("existing acl Name")]
    [ValidatePattern("[a-zA-Z]{2}-[0-9]*")]
    [Parameter(Mandatory = $true)]
    [string]$crnumber = '',
    
    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$f5creds,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$jiracreds,

    [Parameter(Mandatory = $false)]
    [string]$onpremf5ip = 'onpremf5.boozallencsn.com',

    [Parameter(Mandatory = $false)]
    [string]$awsf5ip = 'ec2f5.boozallencsn.com',

    [Validateset('dev', 'prod')]
    [Parameter(Mandatory = $false)]
    [string]$role = 'prod'

  )

  process {



    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if( $role -eq 'dev' ){ 
        $vpnrole = "aggregate_acl_act_full_resource_assign_ag"
    }

    else { $vpnrole = "acl_1_act_full_resource_assign_ag" }

    #if creds are null
    if( !($jiracreds) ) {

        $jiracreds = Get-Credential -Message "Please enter credentials to access Jira"
    }

    $jiraSesh = New-JiraSession -Credential $jiracreds -ErrorAction Stop

    if ([string]::IsNullOrEmpty($jiraSesh)) {

      Write-Warning "Jira session has expired, or bad username and password."

      break

    }

    #scrape info from jira 
    $newEnv = Get-JiraTicketInfo -crNumber "$crnumber"

    #change CIDR subnet from /something to /27. Example: 128.1.2.0/24 to 128.1.2.0.24/27    
    $rejectSubnet = .subnet.split("/")[0] + "/27"

    if ([string]::IsNullOrEmpty($newEnv)) {

      Write-Warning "Jira was unable to locate ticked based on $crNumber"

      break

    }

    try {
          #f5 null creds
          if( !($f5creds) ) {
            Write-Output "Please enter you F5 credentials."
            $creds = Get-Credential -Message "Please enter credentials to access the F5 load balancer"    
          }

        $Global:F5Session = New-F5Session -LTMName $onpremf5ip -LTMCredentials $f5creds -Default -PassThru -ErrorAction Stop

    }

        catch {

          Write-Warning "F5 was unable to connect please check your username, password, and network connection."
          throw $_.Exception.Message
          break

        }

    try {
      Write-Output "Adding new ACL......"
      $aclOrder = (Get-NextAclOrder)
      New-DefaultAcl -Name $newEnv.aws_group -action reject -subnet $rejectSubnet -aclOrder $aclOrder -ErrorAction Stop | Write-Verbose
      Add-DefaultAclSubnet -name $newEnv.aws_group -dstSubnet $newEnv.subnet
      Write-Output "Added $($newEnv.aws_group) with subnet $($newEnv.subnet)"
    }
    catch {
      Write-Warning "Adding ACL failed."
      $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Mapping ACl to VPN access role......"
      Add-APMRole -Name $vpnrole -acl $newEnv.aws_group -group $newEnv.aws_group -ErrorAction stop | Write-Verbose
      Write-Output "Mapped ACL $($newEnv.aws_group) to group  $($newEnv.subnet)."
    }

    catch {
      Write-Warning "Mapping ACL to VPN role failed."
      $_.Exception.Message
      Write-Output "Rolling back changes......"
      Remove-Acl -name $newEnv.aws_group
      Write-Output "ACL $($newEnv.aws_group) has been removed."
      break
    }

    Write-Output "Apply APM Policy......"

    try{
      Update-APMPolicy -Name "CSN_VPN_Streamlined" -ErrorAction Stop | Write-Verbose
      Write-Output "Policy Applied"
    }

    catch{
      Write-Warning "Updating APM Policy failed."
      $_.Exception.Message
      break
    }

    try{
      Write-Output "Syncing Device to Group......"
      Sync-DeviceToGroup -GroupName "Sync_Group" | Write-Verbose
      Write-Output "Synced"
    }
    catch{
      Write-Warning "Syncing Device to Group failed."
      $_.Exception.Message
      break
    }
  #============================================================================================================
  #Add Same ACL build to AWS F5 this needs to be modularized in a future relase for maintainability
  
   try {

          Write-Output "Connecting to AWS F5 (ec2f5.boozallencsn.com)......"
          $Global:F5Session = New-F5Session -LTMName $awsf5ip -LTMCredentials $f5creds -Default -PassThru -ErrorAction Stop

         }

  catch {

          Write-Warning "F5 was unable to connect please check your username, password, and network connection."
          $_.Exception.Message
          break

        }

  try {
      Write-Output "Adding new ACL to AWS F5......"
      New-DefaultAcl -Name $newEnv.aws_group -action reject -subnet $rejectSubnet -aclOrder $aclOrder -ErrorAction Stop | Write-Verbose
      Add-DefaultAclSubnet -name $newEnv.aws_group -dstSubnet $newEnv.subnet
      Write-Output "Added $($newEnv.aws_group) with subnet $($newEnv.subnet)"
    }
    catch {
      Write-Warning "Adding ACL failed."
      throw $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Mapping ACl to VPN access role on AWS F5......"
      Add-APMRole -Name $vpnrole -acl $newEnv.aws_group -group $newEnv.aws_group -ErrorAction stop | Write-Verbose
      Write-Output "Mapped ACL $($newEnv.aws_group) to group  $($newEnv.subnet)."
    }

    catch {
      Write-Warning "Mapping ACL to VPN role failed."
      $_.Exception.Message
      Write-Output "Rolling back changes......"
      Remove-Acl -name $newEnv.aws_group
      Write-Output "ACL $($newEnv.aws_group) has been removed."
      break
    }

    Write-Output "Apply APM Policy on AWS F5......"

    try{
      Update-APMPolicy -Name "CSN_VPN_Streamlined" -ErrorAction Stop | Write-Verbose
      Write-Output "Policy Applied"
    }

    catch{
      Write-Warning "Updating APM Policy failed."
      throw $_.Exception.Message
      break
    }

    

    try{
      
      #Close out Comments 
      Add-JiraIssueComment -Comment "Core Services VPN Config Complete" -Issue $crnumber -VisibleRole 'All Users' -ErrorAction Stop | Out-Null
      Write-Output "[Added Closing Comment]......"
    }

    catch{
      Write-Warning "Updating Jira comments failed."
      throw $_.Exception.Message
      break
    }

    try{
         #Close Out Ticket
      Get-JiraIssue -Key $crnumber | Invoke-JiraIssueTransition -Transition 81 -ErrorAction Stop | Out-Null 
      Write-Output "Ticket Closed......"
      Write-Output "New Build Complete!"
    }

    catch{
      Write-Warning "Updating Jira comments failed."
      throw $_.Exception.Message
      break
    }


  }
 
  

   
  }#end function brace
  

