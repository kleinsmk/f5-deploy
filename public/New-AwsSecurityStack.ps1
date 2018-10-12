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

.Notes

  You must run for the JiraPS module Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'




#>
  [CmdletBinding()]
  param(

    [Alias("existing acl Name")]
    [ValidatePattern("[a-zA-Z]{2}-[0-9]*")]
    [Parameter(Mandatory = $true)]
    [string]$crnumber = '',

    [Parameter(Mandatory = $false)]
    [string]$onrpemf5ip = 'onpremf5.boozallencsn.com',

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

    Write-Output "Please enter your Jira credentials."

    $creds = Get-Credential -Message "Please enter credentials to access Jira"

    $jiraSesh = New-JiraSession -Credential $creds -ErrorAction Stop

    if ([string]::IsNullOrEmpty($jiraSesh)) {

      Write-Warning "Jira session has expired, or bad username and password."

      break

    }


    $newEnv = Get-JiraTicketInfo -crNumber "$crnumber"

    if ([string]::IsNullOrEmpty($newEnv)) {

      Write-Warning "Jira was unable to locate ticked based on $crNumber"

      break

    }

         try {

          Write-Output "Please enter you F5 credentials."
          $creds = Get-Credential -Message "Please enter credentials to access the F5 load balancer"
          $Global:F5Session = New-F5Session -LTMName $onrpemf5ip -LTMCredentials $creds -Default -PassThru -ErrorAction Stop

         }

        catch {

          Write-Warning "F5 was unable to connect please check your username, password, and network connection."
          $_.Exception.Message
          break

        }

    try {
      Write-Output "Adding new ACL......"
      $aclOrder = (Get-NextAclOrder)
      New-DefaultAcl -Name $newEnv.aws_group -subnet $newEnv.subnet -aclOrder $aclOrder -ErrorAction Stop | Write-Verbose
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
  #Add Same ACL build to AWS F5
  
   try {

          Write-Output "Connecting to AWS F5 (ec2f5.boozallencsn.com)......"
          $Global:F5Session = New-F5Session -LTMName $awsf5ip -LTMCredentials $creds -Default -PassThru -ErrorAction Stop

         }

  catch {

          Write-Warning "F5 was unable to connect please check your username, password, and network connection."
          $_.Exception.Message
          break

        }

  try {
      Write-Output "Adding new ACL to AWS F5......"
      New-DefaultAcl -Name $newEnv.aws_group -subnet $newEnv.subnet -aclOrder $aclOrder -ErrorAction Stop | Write-Verbose
      Write-Output "Added $($newEnv.aws_group) with subnet $($newEnv.subnet)"
    }
    catch {
      Write-Warning "Adding ACL failed."
      $_.ErrorDetails.Message
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
      $_.Exception.Message
      break
    }

    

    try{
      
      #Close out Comments 
      Add-JiraIssueComment -Comment "Core Services VPN Config Complete" -Issue $crnumber -VisibleRole 'All Users' | Out-Null
      Write-Output "[Added Closing Comment]......"
    }

    catch{
      Write-Warning "Updating Jira comments failed."
      $_.Exception.Message
      break
    }

    try{
         #Close Out Ticket
      Get-JiraIssue -Key $crnumber | Invoke-JiraIssueTransition -Transition 81 | Out-Null
      Write-Output "Ticket Closed......"
      Write-Output "New Build Complete!"
    }

    catch{
      Write-Warning "Updating Jira comments failed."
      $_.Exception.Message
      break
    }


  }
 
  

   
  }#end function brace
  

