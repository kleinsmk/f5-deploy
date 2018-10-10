

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

    [Alias("Client SSL Profile")]
    [Parameter(Mandatory = $false)]
    [string]$sslClientProfile = '',

    [Alias("Server SSL Profile")]
    [Parameter(Mandatory = $false)]
    [string]$SSLServerProfile = '',

      [Alias("Cert Name")]
    [Parameter(Mandatory = $false)]
    [string]$certname = '',

    [Alias("Key Name")]
    [Parameter(Mandatory = $false)]
    [string]$keyname = '',

    [Alias("ASM")]
    [Parameter(Mandatory = $false)]
    [string]$asmPolicyName = '',

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

    #New ASM
    try
    {
         #skip if parameter was left blank
         if(!([string]::IsNullOrEmpty($asmPolicyName))){   
             #Only build new policy if there is not an existing one on F5
             $asmPolicy = Get-ASMPolicies -name $asmPolicyName   
             if([string]::IsNullOrEmpty($asmPolicy)){
                New-ASMPolicy -policyname $dns
             }
         }
    }

    #New ASM
    catch
    {
         Write-Error $_.Exception.Message
         Write-Error "Failed to create ASM Policy."
         break
    }

    #New SSL Profiles
    try{
        
        if($buildtype -eq "HTTPS"){

            #Powershell makes this soo eloquent! Check if Both profiles arguments are NOT empty or Null.  This way we don't run profile calls if it's not required
            If( !([string]::IsNullOrEmpty($sslClientProfile)) -and !([string]::IsNullOrEmpty($SSLServerProfile)) ){
                #Build both
                New-SSLClient -profileName $sslClientProfile -cert $certname -key $keyname
                $clientProfileCreated = $true
                New-SSLServer -profileName $SSLServerProfile -cert $certname -key $keyname
                $serverProfileCreated = $true
            }
            Elseif( [string]::IsNullOrEmpty($sslClientProfile) ){
                #Build only client
                New-SSLClient -profileName $sslClientProfile -cert $certname -key $keyname
                $clientProfileCreated = $true
            }
            Elseif( [string]::IsNullOrEmpty($SSLServerProfile) ){
                #Build only server
                New-SSLServer -profileName $SSLServerProfile -cert $certname -key $keyname
                $serverProfileCreated = $true
            } 

        }
    }

    #New SSL Profiles
    catch{

             Write-Error $_.Exception.Message         
             Write-Error "Failed to create SSL profile."
             Rollback-VCD -rollBack_Element @('serverssl','clientssl')
             break
         }

    }  

    #New Node
    try
    {
        #Check for existing node
        $node = Get-Node -Address $nodeIP            
        if([string]::IsNullOrEmpty($node)){
          New-Node -Name "$nodeName" -Address "$nodeIP" -Description $desc
          Write-Host "Successfully created New Node $vsname"
        }

        else{
             $nodeName = $node.name 
             Write-Host "Using Existing Node $nodeName"
        }
    }

    #New Node
    catch 
    {
      Write-Warning $_.Exception.Message
      Write-Error "Failed to create node."
      break
    }

    #Add New Pool
    try 
    {
      New-Pool -Name "$vsName" -LoadBalancingMode round-robin -Description $desc -ErrorAction Stop
      Write-Verbose "Successfully Created New Pool $vsName"

    }

    #Add New Pool
    catch 
    {

      Write-Error $_.Exception.Message
      Write-Error "Failed to create pool."
      Rollback-VCD -rollBack_Element @('node')
      break

    }

    #Add Pool Member
    try 
    { 
      Add-PoolMember -PoolName "$vsName" -Name "$nodeName" -PortNumber "$nodePort" -Status Enabled -Description $desc -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Pool Member $nodeIP"

    }

    #Add Pool Member
    catch
    {
      Write-Error $_.Exception.Message
      Write-Error "Failed to add pool member to pool."
      Rollback-VCD -rollBack_Element @('pool','node')
      break

    }

    #Add pool monitor
    try     
    { 
      Add-PoolMonitor -PoolName "$vsName" -Name tcp -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Pool Monitor" 
      
    }

    #Add pool monitor
    catch
    {
      Write-Error $_.Exception.Message
      Write-Error "Failed to add pool monitor."
      Rollback-VCD -rollBack_Element @('pool','node')
      break

    }

    #Add New Virtual Server
    try
    { 
      New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
         -ipProtocol tcp -DefaultPool $vsName -ProfileNames "http-X-Forwarder" -Description $desc -ErrorAction Stop | Out-Null
      Write-Verbose "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " }

    #Add New Virtual Server
    catch
    {
      Write-Error $_.Exception.Message
      Write-Error "Failed to create virtual server."
      Rollback-VCD -rollBack_Element @('pool','node')
      break

    }
    
    #Add iRule
    try
    { 
      $irule = "when HTTP_REQUEST {switch -glob [HTTP::host] {`"$dns`" { virtual $vsName }}}"
      Set-iRule -Name "$vsName" -iRuleContent $irule -WarningAction Stop | Out-Null 
      Write-Verbose "Successfully Created New iRule $dns" 
    }

    #Add iRule
    catch
    {

      Write-Error $_.Exception.Message
      Write-Error "Failed to create iRule."
      Rollback-VCD -rollBack_Element @('virtual','pool','node')
      break

    }

    #Apply iRule
    try  
    {
      Add-iRuleToVirtualServer -Name $wsa -iRuleName "$vsname" -WarningAction Stop | Out-Null; Write-Verbose "Successfully applied New iRule $dns to $wsa "
    }

    #Apply iRule
    catch
    {
      
      Write-Error $_.Exception.Message
      Rollback-VCD -rollBack_Element @('irule','virtual','pool','node')
      break
    }

    Generate-Removalcmds


  } #end process block               

}





