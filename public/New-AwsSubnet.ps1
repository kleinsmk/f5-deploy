function New-AwsSubnet {
<#
.SYNOPSIS

Creates a new AWS VCD stack on the f5 load balancer from specified subnet and aws ID.

.PARAMETER crnumber

CR Number from Jira in the format "4340"


.EXAMPLE




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
  

