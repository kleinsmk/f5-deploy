

function New-VCD {
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

    [ValidateSet('true','false')]
    [Parameter(Mandatory = $true)]
    [string]$ssl = '',

    [ValidateSet('AWS_WSA_vs','AWS_WSA_redirect_vs')]
    [Parameter(Mandatory = $true)]
    [string]$wsa = ''


  )
  begin {

    if ($ssl -eq 'true') { $vsName = $dns + "_https" }
    else { $vsName = $dns + "_http" }

    #Test that the F5 session is in a valid format
    Test-F5Session ($F5Session) | Out-Null

    $exp = $F5Session.WebSession.Headers. 'Token-Expiration'
    #Test if session valid
    if ($exp -lt (date)) {

      throw "F5 Session is not active or has expired."

    }

  }
  process {

    try #Add New Pool

    {
      New-Pool -Name "$vsName" -LoadBalancingMode round-robin -ErrorAction Stop
      Write-Verbose "Successfully Created New Pool $vsName"

    }

    catch

    {

      Write-Error $_.Exception.Message
      break

    }


    try #Add Pool Member Try Catch

    {
      Add-PoolMember -PoolName "$vsName" -Address "$nodeIP" -PortNumber "$nodePort" -Status Enabled -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Pool Member $nodeIP"

    }

    catch #Add Pool Member Try Catch

    {
      Write-Error $_.Exception.Message

      Write-Warning "Rolling back changes....."
      Write-Warning "Removing Pool...."
      Remove-Pool -PoolName ${vsName} -Confirm:$false
      Write-Warning "Pool ${vsName} has been removed."
      break

    }


    try 
    
    { 
      Add-PoolMonitor -PoolName "$vsName" -Name tcp -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Pool Monitor" 
      
    }

    catch

    {
      Write-Error $_.Exception.Message
      Write-Warning "Rolling back changes....."
      Write-Warning "Removing Pool...."
      Remove-Pool -PoolName ${vsName} -Confirm:$false
      Write-Warning "Pool ${vsName} has been removed."
      break

    }

    try 

    { 
      New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
         -ipProtocol tcp -DefaultPool $vsName -ProfileNames "http-X-Forwarder" -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " }

    catch

    {
      Write-Error $_.Exception.Message


      Write-Warning "Rolling back changes....."
      Write-Warning "Removing Pool...."
      Remove-Pool -PoolName ${vsName} -Confirm:$false | Out-Null
      Write-Warning "Pool ${vsName} has been removed."
      break

    }

    #add ssl to asa VS

    $irule = "when HTTP_REQUEST {switch -glob [HTTP::host] {`"$dns`" { virtual $vsName }}}"

    try { Set-iRule -Name "$vsName" -iRuleContent $irule -WarningAction Stop | Out-Null; Write-Verbose "Successfully Created New iRule $dns" }

    catch

    {

      $_.Exception.Message
      Write-Warning "Rolling back changes....."
      Write-Warning "Revmoing Virtual Sever....."
      Remove-VirtualServer -Name ${vsName} -Confirm:$false | Out-Null
      Write-Warning "Virtual server $vsname has been removed."
      Write-Warning "Removing Pool...."
      Remove-Pool -PoolName ${vsName} -Confirm:$false | Out-Null
      Write-Warning "Pool ${vsName} has been removed."
      break

    }


    try {


      Add-iRuleToVirtualServer -Name $wsa -iRuleName "$vsname" -WarningAction Stop | Out-Null; Write-Verbose "Successfully applied New iRule $dns to $wsa "
    }
    catch
    {
      Write-Error "Failed to Add New iRule to Virutal $vsName"
      $_.Exception.Message

      Write-Warning "Rolling back changes....."
      Write-Warning "Removing iRule from Virtual Server"
      Remove-iRuleFromVirtualServer -Name $wsa -iRuleName $vsname
      Write-Output "Removed iRule $vsname fom Virtual $vsname"
      Write-Warning "Removing iRule"
      Remove-iRule -Name $vsname -Confirm:$false
      Write-Warning "Removed iRule $vsname ."
      Write-Warning "Removing Virtual Server"
      Remove-VirtualServer -Name ${vsName} -Confirm:$false | Out-Null
      Write-Warning "Virtual server $vsname has been removed."
      Write-Warning "Removing Pool...."
      Remove-Pool -PoolName ${vsName} -Confirm:$false
      Write-Warning "Pool ${vsName} has been removed."
      break



    }


    @"

                Removal Commands

Remove-iRuleFromVirtualServer -Name '$wsa' -iRuleName '${vsname}'
Remove-iRule -Name '${vsname}' -Confirm:`$false
Remove-VirtualServer -Name ${vsName} -Confirm:`$false
Remove-Pool -PoolName ${vsName} -Confirm:`$false
"@









  } #end process block               

}





