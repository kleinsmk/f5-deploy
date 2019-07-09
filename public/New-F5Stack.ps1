

function New-F5Stack {
<#
.SYNOPSIS
   Automates the deployment of a new project for inbound access on a given domain name.
.Description
    Creates a new node, new pool, new listening virtual server, client ssl profile, server ssl profile,
    switching irule, and ASM policy for given parameters.  Applies the irule to the appropriate proxy VS.
    ======Does not currently apply SSLcleint profiles to main proxy routing VS and this must be done manually.======
.PARAMETER dns

    The dns name which we would like to open via the reverse proxy.

.PARAMETER nodeIP

    The ip of the intenral node and or AWS instance in the VCD.  Pass either IP or FQDN not both.

.PARAMETER nodeFQDN

    The FQDN of the intenral node and or AWS instance in the VCD.  Pass either IP or FQDN not both.

.PARAMETER nodePort

    The internal port the node is listening on.

.PARAMETER vsPort

    The port the virutal server will be listening on

.PARAMETER vsIP

    The IP the virutal server will be configured to use.

.PARAMETER sslClientProfile

    The name of the client profile you wish to create.  May be omitted.
    Can specify the default clientssl profile as well.

.PARAMETER sslServerProfile

    The name of the client profile you wish to create.  May be omitted.
    Gernally the serverssl profile should simply be provided as this keep config to a minimum

 .PARAMETER  certname

    Name of certificate to be attched to profile.  In format something.com.crt

 .PARAMETER  keyname

    Name of key to be attched to profile.  In format something.com.key

.PARAMETER asmPolicyName

    Used to specify and existing ASM policy to use as when doing multiple builds with the same policy.
    Should otherwise be left blank.

.PARAMETER desc

    Description for each LTM object to be tagged into the description field. Should be the AWS_ID generally.

.PARAMETER buildtype

    Switch to set the type of build required. HTTP or HTTPS are valid options.

.Example 

New-F5Stack -dns funtimes.boozallencsn.com -nodeIP 10.194.55.109 -nodePort 80 -vsPort 443 -vsIP 1.1.1.256 -sslClientProfile funtimes.boozallencsn.com -desc AWS_309304096838 -certname funtimes.boozallencsn.com.crt -keyname funtimes.boozallencsn.com.key -buildtype HTTPS

Create new node 10.194.55.109:80, new virtual server named funtimes.boozallencsn.com listening at 443, new pool pointed to new node, new ssl client profile, new irule, and new asm profile


.NOTES
    Requires F5-LTM modules from github
    
#>
  [CmdletBinding()]
  param(

    [Alias("DNS Name of instance")]
    [Parameter(Mandatory = $true)]
    [string]$dns = '',

    [Alias("Node IP")]
    [Parameter(Mandatory = $false)]
    [string]$nodeIP = '',
    
    [Alias("Node FQDN")]
    [Parameter(Mandatory = $false)]
    [string]$nodeFQDN = '',

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
    [string]$buildtype = '',

    #Commenting out to add hardcoded options probably a bad idea
    #[ValidateSet('AWS_WSA_vs','AWS_WSA_redirect_vs')]
    #[Parameter(Mandatory = $true)]
    #[string]$wsa = ''

    [ValidateSet('AWS','Azure')]
    [Parameter(Mandatory = $false)]
    [string]$environment = 'AWS'

  )

  begin {
    
    Check-F5Token

    switch ($buildtype) {

       "HTTP" {
            $ssl = $false
            #trim removes incompatiable wild card from valid *.something.com FQDNS
            $vsName = $dns.TrimStart('*.') + "_http"
            $nodeName = $dns.TrimStart('*.')

            if( $environment -eq "Azure" ) { 
                $wsa = 'AZURE_WSA_http_vs' 
            }

            else { $wsa = 'AWS_WSA_redirect_vs' } 
                      
            $iruleDns = $dns
            break
       }

       "HTTPS" {
            $ssl = $true
            $vsName = $dns.TrimStart('*.') + "_https"
            $nodeName = $dns.TrimStart('*.') 

            if( $environment -eq "Azure" ) { 
                $wsa = 'AZURE_WSA_https_vs' 
            }

            else { $wsa = 'AWS_WSA_vs' }
            
            $iruleDns = $dns
            break
       }

    }

  }#end begin block

  process {

    Write-Output "Starting new build....."

    #New SSL Profiles
    try{
        #skip if HTTP only build
        if($buildtype -eq "HTTPS"){

            #Powershell makes this soo eloquent! Check if Both profiles arguments are NOT empty or Null.  This way we don't run profile calls if it's not required
            If( (!([string]::IsNullOrEmpty($sslClientProfile))) -and (!([string]::IsNullOrEmpty($SSLServerProfile))) ){
                
                #Build both
                Write-Output "Creating new Client profile....."
                New-SSLClient -profileName $sslClientProfile -cert $certname -key $keyname | Out-Null
                Write-Output "Client Profile created."
                $clientProfileCreated = $true
                #check for default ssl profile
                if( $SSLServerProfile -eq "serverssl" ){
                    Write-Output "Using deafult serverssl profile."
                    $serverProfileCreated = $true
                }
                Else{
                    Write-Output "Creating new Server profile....."
                    New-SSLServer -profileName $SSLServerProfile -cert $certname -key $keyname | Out-Null
                    Write-Output "Server Profile created."
                    $serverProfileCreated = $true
                }
            }
            Elseif( !([string]::IsNullOrEmpty($sslClientProfile)) ){
                #Build only client

                #check for existing profile
                try {
                    if(Get-SSLClient $sslClientProfile -ErrorAction Continue){
                    Write-Output "Using existing Client profile $sslClientProfile....."
                    $clientProfileCreated = $true
                    }
                }

                catch{               

                Write-Output "Creating new Client profile....."
                New-SSLClient -profileName $sslClientProfile -cert $certname -key $keyname | Out-Null
                Write-Output "Client Profile created."
                $clientProfileCreated = $true

                }
            
            }
            Elseif( !([string]::IsNullOrEmpty($SSLServerProfile)) ){
                #Build only server
                #check for default ssl option
                if( $SSLServerProfile -eq "serverssl" ){
                    Write-Output "Using deafult serverssl profile."
                    $serverProfileCreated = $true
                }
                Else{
                    Write-Output "Creating new Server profile....."
                    New-SSLServer -profileName $SSLServerProfile -cert $certname -key $keyname | Out-Null
                    Write-Output "Server Profile created."
                    $serverProfileCreated = $true
                }
            } 

        }
    }

    #New SSL Profiles
    catch{
              
             [string]$message =  $_
             #clean up error output a bit
             Write-Warning ($message -replace "{`"code`":409,`"message`":`"01020066:3: ")        
             Write-Warning "Failed to create SSL profile.  Please ensure Cert and Key are present and files names match exactly."
             Rollback-VCD -rollBack_Element @('serverssl','clientssl')
             break
         

    }  

    #New Node
    try
    {
        #if nodeip is not empty
        if( !([string]::IsNullOrEmpty($nodeIP)) ) {
            #Check for existing node
            $node = Get-Node -Address $nodeIP
            #if node does not exist            
            if([string]::IsNullOrEmpty($node)){
              Write-Host "Creating new node......"
              New-Node -Name "$nodeName" -Address "$nodeIP" -Description $desc -ErrorAction Stop | Out-Null
              Write-Host "Successfully created New Node $nodeName with IP $nodeIP"
            }
            #otherwise use the existing node
            else{
             
                 $nodeName = $node.name 
                 Write-Host "Using Existing Node $nodeName"
            }
        }
        #Use FQDN instead of IP
        else {

            $existingNode = Get-NodebyFQDN -fqdn $nodeFQDN

            #if node does not exist            
            if([string]::IsNullOrEmpty($existingNode)){

              Write-Host "Creating new node......"
              New-Node -Name "$nodeName" -FQDN $nodeFQDN -AddressType ipv4 -AutoPopulate disabled -Description $desc -ErrorAction Stop| Out-Null
              Write-Host "Successfully created New Node $nodeName with FQDN $nodeFQDN"
  
            }

            else {

              $nodeName = $node 
              Write-Host "Using Existing Node $nodeName"


            }

            
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
                -ipProtocol tcp -DefaultPool $vsName -ProfileNames @("rewrite_http_redirect_SSL","$sslClientProfile") -Description $desc -ErrorAction Stop | Out-Null
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

     #New ASM
    try
    {
         Write-Output "Checking for existing ASM policy....."  
         #If existing policy parameter has been passed
         if(!([string]::IsNullOrEmpty($asmPolicyName))){ 
           
             #Check passed policy for existing policy on F5
             $asmPolicy = Get-ASMPolicies -name $asmPolicyName 
             
             #if policy exits   
             if(!([string]::IsNullOrEmpty($asmPolicy))){
                Write-Output "Using existing ASM Policy: $asmPolicyName"
             }
             #otherwise skip policy creation
             else{
                Write-Output "Policy name $asmPolicyName was not found. Skipping Policy Creation and application."
                #set policy null
                Write-Output "New F5 VCD Build succeeded!!!!"
                Generate-RemovalCmds
                break
            }
                      
         }

         #if policy wasn't specified create a new one using default dns name
         else{
                $asmPolicyName = $dns.TrimStart('*.')
                
                #check for existing policy with default dns name
                $asmPolicy = Get-ASMPolicies -name $asmPolicyName 
                 
                #if something came back use the existing policy
                if(!([string]::IsNullOrEmpty($asmPolicy))){
                  Write-Output "Using existing ASM Policy: $asmPolicyName"
                }
                #otherwise build a new one out
                else{
                  Write-Output "Creating New ASM policy....."
                  New-ASMPolicy -policyname $asmPolicyName -Verbose | Out-Null
                  Write-Output "New ASM Policy $asmPolicyName has been created."                
                }
            }
    }

    #New ASM
    catch
    {
         Write-Warning $_.Exception.Message
         Write-Warning "Failed to create ASM Policy.  Run `"New-ASMPolicy -policyname name`" manually."
         break
    }


    #apply asm policy to VS
    try
    {

            Write-Output "Applying policy to virtual server $vsName.....(this may take a moment)"
            Add-VirtualToPolicy -serverName $vsName -policyName $asmPolicyName | Out-Null
            Write-Output "ASM policy successfully applied to virtual server $vsName."

    }

    catch
    {
            Write-Warning $_
            Write-Warning "Failed to Apply ASM Policy.  Run `" Add-VirtualToPolicy`" manually."
            Generate-Removalcmds
            break   
    }

    #Set Log illegal Requests
    try
    {

            Write-Output "Setting logging policy on virtual server $vsName....."
            Add-LogIllegalRequests -serverName $vsName | Out-Null
            Write-Output "Log illegal requests setting successfully applied to virtual server $vsName."

    }

    catch
    {
            Write-Warning $_
            Write-Warning "Failed to apply logging settings.  Apply them manually."
            Generate-Removalcmds
            break   
    }

    Write-Output "New F5 VCD Build succeeded!!!!"

    Generate-Removalcmds

    #For the future maintainer this was written by a programming Sysadmin. Mybad.  It got the job done at the time and follows bracket style.
    #Some comments were even put in for your condieration.
  
} #end process block 

}#end function              







