function New-AwsSubnet {
<#
.SYNOPSIS

Creates a new project VPN config for a specified subnet and group.

This cmdlet is used when a new environment needs vpn configuration setup but there isn't a properly formed ticket to scrape from.
Example use cases would be new on-prem projects etc.

.PARAMETER awsID

The AD group that wil be used for both the ACL name and the the LDAP mapping.  Generally this is an AWS Account but could also be something like BLUE_DNS

.PARAMETER subnet

The subnet you wish to use to create the default ACL with

.PARAMETER f5creds

Powershell crednetial object containing F5 login credentials.  Can be omitted or passed to save time.

.PARAMETER jiracreds

Powershell crednetial object containing F5 login credentials.  Can be omitted or passed to save time.

.PARAMETER onpremf5ip

IP or DNS of onpremise F5 device.  Defaults to onpremf5.boozallencsn.com and generally can be omitted.

.PARAMETER awsf5ip

IP or DNS of AWS F5 device in VCD.  Defaults to ec2f5.boozallencsn.com and generally can be omitted.

.PARAMETER role

Switch paramter for dev or prod.  Defaults to prod if omitted.

.EXAMPLE

New-AWSSubnet -awsID AWS_0989809809808 -subnet 10.22.33.0/24

Creates a new allow ACL for the default port range to 10.22.33.0/24 and maps AD group AWS_0989809809808 to this ACL
.Notes

  It is required that the jirasever have been set using JiraPS module Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'

#>
  [CmdletBinding()]
  param(

    [Parameter(Mandatory = $true)]
    [string]$awsId = '',

    [Parameter(Mandatory = $true)]
    [string]$subnet = '',

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
      New-DefaultAcl -Name $awsId -subnet $subnet -aclOrder $aclOrder -ErrorAction Stop | Write-Verbose
      Write-Output "Added $($awsId) with subnet $($subnet)"
    }
    catch {
      Write-Warning "Adding ACL failed."
      $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Mapping ACl to VPN access role......"
      Add-APMRole -Name $vpnrole -acl $awsId -group $awsId -ErrorAction stop | Write-Verbose
      Write-Output "Mapped ACL $($awsId) to group  $($awsId)."
    }

    catch {
      Write-Warning "Mapping ACL to VPN role failed."
      $_.Exception.Message
      Write-Output "Rolling back changes......"
      Remove-Acl -name $awsId
      Write-Output "ACL $($awsId) has been removed."
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
      New-DefaultAcl -Name $awsId -subnet $subnet -aclOrder $aclOrder -ErrorAction Stop | Write-Verbose
      Write-Output "Added $($awsId) with subnet $($subnet)"
    }
    catch {
      Write-Warning "Adding ACL failed."
      $_.ErrorDetails.Message
      break
    }

    try {
      Write-Output "Mapping ACl to VPN access role on AWS F5......"
      Add-APMRole -Name $vpnrole -acl $awsId -group $awsId -ErrorAction stop | Write-Verbose
      Write-Output "Mapped ACL $($awsId) to group  $($subnet)."
    }

    catch {
      Write-Warning "Mapping ACL to VPN role failed."
      $_.Exception.Message
      Write-Output "Rolling back changes......"
      Remove-Acl -name $awsId
      Write-Output "ACL $($awsId) has been removed."
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
  }
 
  

   
  }#end function brace
  

