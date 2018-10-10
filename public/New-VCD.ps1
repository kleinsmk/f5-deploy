

function New-CSN-VCD {
<#
.SYNOPSIS
    Adds a new VCD stack to F5
.NOTES
    Requires F5-LTM modules from github
#>
  [CmdletBinding()]
  param(

    [Alias("DNS Name of instance")]
    [Parameter(Mandatory = $true)]
    [string]$dns = '',

    [Alias("Node IP")]
    [Parameter(Mandatory = $true)]
    [string]$nodeIP = '',

    [Alias("Node Port ")]
    [Parameter(Mandatory = $true)]
    [string]$nodePort = '',

    [Alias("Virtual Destination Port")]
    [Parameter(Mandatory = $true)]
    [string]$vsPort = '',

    [Alias("VS IP")]
    [Parameter(Mandatory = $true)]
    [string]$vsIP = '',

    [Alias("Cert Name")]
    [Parameter(Mandatory = $false)]
    [string]$certname = '',

    [Alias("Key Name")]
    [Parameter(Mandatory = $false)]
    [string]$keyname = '',

    [Alias("ASM")]
    [Parameter(Mandatory = $false)]
    [string]$asmpolicy = '',

    [Alias("Description")]
    [Parameter(Mandatory = $false)]
    [string]$desc = '',

    [ValidateSet('HTTP','HTTPS')]
    [Parameter(Mandatory = $true)]
    [string]$buildtype = ''

    #Commenting out to add hardcoded options probably a bad idea
    #[ValidateSet('AWS_WSA_vs','AWS_WSA_redirect_vs')]
    #[Parameter(Mandatory = $true)]
    #[string]$wsa = ''


  )

  begin {
    
    Check-F5Token

    switch ($buildtype) {

       "HTTP" {
            $ssl = $false
            $vsName = $dns + "_http"
            $nodeName = $dns
            $wsa = 'AWS_WSA_redirect_vs'
            break
       }

       "HTTPS" {
            $ssl = $true
            $vsName = $dns + "_https"
            $nodeName = $dns 
            $wsa = 'AWS_WSA_vs'
            break
       }

    }

  }#end begin block

  process {

    #Check for existing node
    $node = Get-Node -Address $nodeIP

    #New Node
    try
    {            
        if([string]::IsNullOrEmpty($node)){
          New-Node -Name "$nodeName" -Address "$nodeIP" -Description $desc
          Write-Host "Successfully created New Node $vsname"
        }

        else{
             $nodeName = $node.name 
             Write-Host "Using Existing Node $nodeName"
        }
    }

    catch #New Node Catch
    {
      Write-Warning $_.Exception.Message
      Write-Error "Failed to create node."
      break
    }

    try #Add New Pool
    {
      New-Pool -Name "$vsName" -LoadBalancingMode round-robin -Description $desc -ErrorAction Stop
      Write-Verbose "Successfully Created New Pool $vsName"

    }

    catch #add New Pool
    {

      Write-Error $_.Exception.Message
      Write-Error "Failed to create pool."
      Rollback-VCD -rollBack_Element @('node')
      break

    }

    try #Add Pool Member
    { 
      Add-PoolMember -PoolName "$vsName" -Name "$nodeName" -PortNumber "$nodePort" -Status Enabled -Description $desc -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Pool Member $nodeIP"

    }

    catch #Add Pool Member Catch
    {
      Write-Error $_.Exception.Message
      Write-Error "Failed to add pool member to pool."
      Rollback-VCD -rollBack_Element @('pool','node')
      break

    }

    try #Add pool monitor    
    { 
      Add-PoolMonitor -PoolName "$vsName" -Name tcp -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Pool Monitor" 
      
    }

    catch #Add pool monitor catch
    {
      Write-Error $_.Exception.Message
      Write-Error "Failed to add pool monitor."
      Rollback-VCD -rollBack_Element @('pool','node')
      break

    }

    try #Add New Virtual Server
    { 
      New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
         -ipProtocol tcp -DefaultPool $vsName -ProfileNames "http-X-Forwarder" -Description $desc -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " }

    catch # Add New Virtual Server Catch
    {
      Write-Error $_.Exception.Message
      Write-Error "Failed to create virtual server."
      Rollback-VCD -rollBack_Element @('pool','node')
      break

    }

    try #Add iRule
    { 
      $irule = "when HTTP_REQUEST {switch -glob [HTTP::host] {`"$dns`" { virtual $vsName }}}"
      Set-iRule -Name "$vsName" -iRuleContent $irule -WarningAction Stop | Out-Null 
      Write-Verbose "Successfully Created New iRule $dns" 
    }

    catch #Add irule Catch
    {

      Write-Error $_.Exception.Message
      Write-Error "Failed to create iRule."
      Rollback-VCD -rollBack_Element @('virtual','pool','node')
      break

    }

    try #Apply iRule 
    {
      Add-iRuleToVirtualServer -Name $wsa -iRuleName "$vsname" -WarningAction Stop | Out-Null; Write-Verbose "Successfully applied New iRule $dns to $wsa "
    }

    catch #Apply iRule Catch
    {
      
      Write-Error $_.Exception.Message
      Rollback-VCD -rollBack_Element @('irule','virtual','pool','node')
      break
    }

    Generate-Removalcmds


  } #end process block               

}





