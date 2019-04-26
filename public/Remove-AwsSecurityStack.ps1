function Remove-AwsSecurityStack {
<#
.SYNOPSIS

Removes core services F5 vpn config from a specified Jira Ticket.
May be used in conjuntion with Find-VCD to determine if LTM config is required to be removed.

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

Remove-AwsSecurityStack -crNumber "CR-4509" -f5creds $saved_credentials -jiracreds $saved_jiracreds

.Notes

.EXAMPLE




#>
  [CmdletBinding()]
  param(

    [ValidatePattern("[a-zA-Z]{2}-[0-9]*")]
    [Parameter(Mandatory = $true)]
    [string]$crnumber = '',

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$f5creds,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$jiracreds,

   [Parameter(Mandatory = $false)]
    [string]$onrpemf5ip = 'onpremf5.boozallencsn.com',

    [Parameter(Mandatory = $false)]
    [string]$awsf5ip = 'ec2f5.boozallencsn.com',

    [Validateset('dev', 'prod')]
    [Parameter(Mandatory = $false)]
    [string]$role = 'prod'

  )

  process {

    #Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'  first time jira setup

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if( $role -eq 'dev' ){ 
        $vpnrole = "aggregate_acl_act_full_resource_assign_ag"
    }

    else { $vpnrole = "acl_1_act_full_resource_assign_ag" }

    #if creds are null
    if( !($jiracreds) ) {
        Write-Output "Please enter your Jira credentials."
        $jiracreds = Get-Credential -Message "Please enter credentials to access Jira"
    }

    $jiraSesh = New-JiraSession -Credential $jiracreds -ErrorAction Stop

    if ([string]::IsNullOrEmpty($jiraSesh)) {

      Write-Warning "Jira session has expired, or bad username and password."

      break

    }

    $awsId = Get-AwsIdFromJira -crNumber "$crnumber"

    if ([string]::IsNullOrEmpty($awsID)) {

      Write-Warning "Jira was unable to locate ticked based on $crNumber"

      break

    }

         try {
          #f5 null creds
          if( !($f5creds) ) {
              Write-Output "Please enter you F5 credentials."
              $f5creds = Get-Credential -Message "Please enter credentials to access the F5 load balancer"
          }
          $Global:F5Session = New-F5Session -LTMName $onrpemf5ip -LTMCredentials $f5creds -Default -PassThru -ErrorAction Stop

         }

        catch {

          Write-Warning "F5 was unable to connect please check your username, password, and network connection."
          throw $_.Exception.Message
          break

        }

    try {
      Write-Output "Removing existing Role mapping......"
      Remove-APMRole -acl $awsId -group $awsID -name $vpnrole | Out-Null
      Write-Output "Removed $awsId mapping from group $awsId"
    }
    catch {
      Write-Warning "Removing APM Role mapping failed."
      throw $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Removing ACl......"
      Remove-Acl -name $awsId | Out-Null
      Write-Output "Removed ACL $awsID."
    }

    catch {
      Write-Warning "Removing ACL failed."
      throw $_.Exception.ErrorDetails
      break
    }

    Write-Output "Update APM Policy......"

    try{
      Update-APMPolicy -Name "CSN_VPN_Streamlined" -ErrorAction Stop | Write-Verbose
      Write-Output "Policy Updated"
    }

    catch{
      Write-Warning "Updating APM Policy failed."
      throw $_.Exception.Message
      break
    }

    try{
      Write-Output "Syncing Device to Group......"
      Sync-DeviceToGroup -GroupName "Sync_Group" | Write-Verbose
      Write-Output "Synced"
    }
    catch{
      Write-Warning "Syncing Device to Group failed."
      throw $_.Exception.Message
      break
    }
  #============================================================================================================
  #Add Same ACL build to AWS F5
  
   try {

          Write-Output "Connecting to AWS F5 (ec2f5.boozallencsn.com)......"
          $Global:F5Session = New-F5Session -LTMName $awsf5ip -LTMCredentials $f5creds -Default -PassThru -ErrorAction Stop
          Write-Output "OK. Connected to AWS F5!"
         }

  catch {

          Write-Warning "F5 was unable to connect please check your username, password, and network connection."
          throw $_.Exception.Message
          break

        }

    try {  
      Write-Output "Removing existing Role mapping......"
      Remove-APMRole -acl $awsId -group $awsID -name $vpnrole | Out-Null
      Write-Output "Removed $awsId mapping from group $awsId"
    }
    catch {
      Write-Warning "Removing APM Role mapping failed."
      throw $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Removing ACl......"
      Remove-Acl -name $awsId | Out-Null
      Write-Output "Removed ACL $awsID."
    }

    catch {
      Write-Warning "Removing ACL failed."
      throw $_.ErrorDetails
      break
    }

   

    try{
      Write-Output "Update APM Policy......"
      Update-APMPolicy -Name "CSN_VPN_Streamlined" -ErrorAction Stop | Write-Verbose
      Write-Output "Policy Updated"
    }

    catch{
      Write-Warning "Updating APM Policy failed."
      throw $_.Exception.Message
      break
    }

    try{
      
      #Close out Comments 
      Add-JiraIssueComment -Comment "Core Services VPN Config Removal Complete" -Issue $crnumber -VisibleRole 'All Users' | Out-Null
      Write-Output "[Added Closing Comment]......"
    }

    catch{
      Write-Warning "Updating Jira comments failed."
      throw $_.Exception.Message
      break
    }

    try{
         #Close Out Ticket
      Get-JiraIssue -Key $crnumber | Invoke-JiraIssueTransition -Transition 81 | Out-Null
      Write-Output "Ticket Closed......"
      Write-Output "VPN Removal Complete!"
    }

    catch{
      Write-Warning "Updating Jira comments failed."
      throw $_.Exception.Message
      break
    }

  }
   
  }#end function brace
  

