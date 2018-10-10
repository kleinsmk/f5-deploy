

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
           
             #check for existing policy with default dns name
             $asmPolicy = Get-ASMPolicies -name $asmPolicyName 
               
             if(!([string]::IsNullOrEmpty($asmPolicy))){
                Write-Output "Using existing ASM Policy: $asmPolicyName"
             }
             else{
                Write-Output "Policy name $asmPolicyName was not found. Skipping Policy Creation."
            }
                      
         }

         #if policy wasn't specified create a new one using default name
         else{
                #check for existing policy with default dns name
                $asmPolicy = Get-ASMPolicies -name $dns
                 
                #if something came back  
                if(!([string]::IsNullOrEmpty($asmPolicy))){
                  Write-Output "Using existing ASM Policy: $dns"  
                }

                else{
                  Write-Output "Creating New ASM policy....."
                  New-ASMPolicy -policyname $dns -Verbose | Out-Null
                  Write-Output "New ASM Policy $dns has been created."
                }
            }
    }

    #New ASM
    catch
    {
         Write-Warning $_.Exception.Message
         Write-Warning "Failed to create ASM Policy."
         break
    }

    #New SSL Profiles
    try{
        
        if($buildtype -eq "HTTPS"){

            #Powershell makes this soo eloquent! Check if Both profiles arguments are NOT empty or Null.  This way we don't run profile calls if it's not required
            If( (!([string]::IsNullOrEmpty($sslClientProfile))) -and (!([string]::IsNullOrEmpty($SSLServerProfile))) ){
                #Build both
                Write-Output "Creating new Client profile....."
                New-SSLClient -profileName $sslClientProfile -cert $certname -key $keyname | Out-Null
                Write-Output "Client Profile created."
                $clientProfileCreated = $true
                Write-Output "Creating new Server profile....."
                New-SSLServer -profileName $SSLServerProfile -cert $certname -key $keyname | Out-Null
                Write-Output "Server Profile created."
                $serverProfileCreated = $true
            }
            Elseif( !([string]::IsNullOrEmpty($sslClientProfile)) ){
                #Build only client
                Write-Output "Creating new Client profile....."
                New-SSLClient -profileName $sslClientProfile -cert $certname -key $keyname | Out-Null
                Write-Output "Client Profile created."
                $clientProfileCreated = $true
            }
            Elseif( !([string]::IsNullOrEmpty($SSLServerProfile)) ){
                #Build only server
                Write-Output "Creating new Server profile....."
                New-SSLServer -profileName $SSLServerProfile -cert $certname -key $keyname | Out-Null
                Write-Output "Server Profile created."
                $serverProfileCreated = $true
            } 

        }
    }

    #New SSL Profiles
    catch{

             Write-Warning $_         
             Write-Warning "Failed to create SSL profile.  Please ensure Cert and Key are present and files names match exactly."
             Rollback-VCD -rollBack_Element @('serverssl','clientssl')
             break
         

    }  

    #New Node
    try
    {
        #Check for existing node
        $node = Get-Node -Address $nodeIP            
        if([string]::IsNullOrEmpty($node)){
          Write-Host "Creating new node......"
          New-Node -Name "$nodeName" -Address "$nodeIP" -Description $desc | Out-Null
          Write-Host "Successfully created New Node $nodeName with IP $nodeIP"
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
      Write-Warning "Failed to create node."
      Rollback-VCD -rollBack_Element @('serverssl','clientssl')
      break
    }

    #Add New Pool
    try 
    {
      Write-Output "Creating New Pool....."
      New-Pool -Name "$vsName" -LoadBalancingMode round-robin -Description $desc -ErrorAction Stop | Out-Null
      Write-Output "Successfully Created New Pool $vsName"

    }

    #Add New Pool
    catch 
    {

      Write-Warning $_.Exception.Message
      Write-Warning "Failed to create pool."
      Rollback-VCD -rollBack_Element @('node','serverssl','clientssl')
      break

    }

    #Add Pool Member
    try 
    { 
      Write-Output "Adding pool member $nodeName to pool $vsName....."
      Add-PoolMember -PoolName "$vsName" -Name "$nodeName" -PortNumber "$nodePort" -Status Enabled -Description $desc -ErrorAction Stop | Out-Null
      Write-Output "Successfully Added New Pool Member $nodeIP"

    }

    #Add Pool Member
    catch
    {
      Write-Warning $_.Exception.Message
      Write-Warning "Failed to add pool member to pool."
      Rollback-VCD -rollBack_Element @('pool','node','serverssl','clientssl')
      break

    }

    #Add pool monitor
    try     
    { 
      Write-Output "Adding pool TCP health monitor....." 
      Add-PoolMonitor -PoolName "$vsName" -Name tcp -ErrorAction Stop | Out-Null
      Write-Output "Successfully Added pool TCP health monitor." 
      
    }

    #Add pool monitor
    catch
    {
      Write-Warning $_.Exception.Message
      Write-Warning "Failed to add pool monitor."
      Rollback-VCD -rollBack_Element @('pool','node','serverssl','clientssl')
      break

    }

    #Add New Virtual Server
    try
    { 
            
            #when both profile arguments have been passed in
            If( !([string]::IsNullOrEmpty($sslClientProfile)) -and !([string]::IsNullOrEmpty($SSLServerProfile)) ){
                #Build with both profiles
                Write-Output "Adding new Virtual Server with client profile $sslClientProfile and server profile $SSLServerProfile....."
                New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
                -ipProtocol tcp -DefaultPool $vsName -ProfileNames @("http-X-Forwarder","$sslClientProfile","$SSLServerProfile") -Description $desc -ErrorAction Stop | Out-Null
                Write-Output "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " 

            }
            Elseif( !([string]::IsNullOrEmpty($sslClientProfile)) ){
                #Build only client
                 Write-Output "Adding new Virtual Server with client profile $sslClientProfile....."
                 New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
                -ipProtocol tcp -DefaultPool $vsName -ProfileNames @("http-X-Forwarder","$sslClientProfile") -Description $desc -ErrorAction Stop | Out-Null
                Write-Output "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " 
            }
            Elseif( !([string]::IsNullOrEmpty($SSLServerProfile)) ){
                #Build only server
                Write-Output "Adding new Virtual Server with server profile $SSLServerProfile....."
                 New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
                -ipProtocol tcp -DefaultPool $vsName -ProfileNames @("http-X-Forwarder","$SSLServerProfile") -Description $desc -ErrorAction Stop | Out-Null
                Write-Output "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " 

            }
            #build without profiles
            Else{
                Write-Output "Adding new Virtual Server without SSL profiles....."
                New-VirtualServer -Name "$vsName" -DestinationPort "$vsPort" -DestinationIP "$vsIP" -SourceAddressTranslationType automap `
                -ipProtocol tcp -DefaultPool $vsName -ProfileNames "http-X-Forwarder" -Description $desc -ErrorAction Stop | Out-Null
                Write-Output "Successfully Added New Virtual Server $vsName ${vsIP}:${vsPort} " 
            
            }
    }#end New VS Try       

    #Add New Virtual Server
    catch
    {
      Write-Warning $_.Exception.Message
      Write-Warning "Failed to create virtual server."
      Rollback-VCD -rollBack_Element @('pool','node','serverssl','clientssl')
      break

    }
    
    #Add iRule
    try
    { 
      $irule = "when HTTP_REQUEST {switch -glob [HTTP::host] {`"$dns`" { virtual $vsName }}}"
      Set-iRule -Name "$vsName" -iRuleContent $irule -WarningAction Stop | Out-Null 
      Write-Output "Successfully Created New iRule $dns" 
    }

    #Add iRule
    catch
    {

      Write-Warning $_.Exception.Message
      Write-Warning "Failed to create iRule."
      Rollback-VCD -rollBack_Element @('virtual','pool','node','serverssl','clientssl')
      break

    }

    #Apply iRule
    try  
    {
      Add-iRuleToVirtualServer -Name $wsa -iRuleName "$vsname" -WarningAction Stop | Out-Null; Write-Output "Successfully applied New iRule $dns to $wsa "
    }

    #Apply iRule
    catch
    {
      
      Write-Warning $_.Exception.Message
      Rollback-VCD -rollBack_Element @('irule','virtual','pool','node','serverssl','clientssl')
      break
    }

    Generate-Removalcmds


  
  
} #end process block 

}#end function              







