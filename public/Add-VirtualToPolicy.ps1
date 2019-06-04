Function Add-VirtualToPolicy {
<#
.SYNOPSIS
 Adds and ASM policy to a virutal Server
.DESCRIPTION
 
.PARAMETER serverName
 Name of the virtual server

.PARAMETER policyName
 Name of existing ASM policy you wish to apply to a virtual server.

.EXAMPLE
 Add-ASMtoVirutal -serverName newsite.com -policyName newsite.com_asm

.NOTES
 Requires f5-ltm from github
 
#>
    [cmdletBinding()]
    param(
        
        [Parameter(Mandatory=$true)]
        [string[]]$serverName,

        [Parameter(Mandatory=$true)]
        [string[]]$policyName
    )

    begin {
        #Test that the F5 session is in a valid format
        Check-F5Token
        }

    process {


        foreach ($policy in $policyName) {

            #Append Virtual Servers to Policy
            $existingPolicy = Get-ASMPolicies -name $policyName
          
            $servers = $existingPolicy.virtualServers += "/Common/$serverName"
            
            #$object = [pscustomobject]@{ 'kind' = 'tm:asm:policies:policystate' ; 'virtualServers' = @()}
            $object = [pscustomobject]@{ 'virtualServers' = @()}
            
            $object.virtualServers += $servers
                       
            #Build API URI
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies/$($existingPolicy.id)")

            $jsonbody =  $object | ConvertTo-Json

            try {
                    
                    Write-Verbose "PATCHing to uri: $uri" 
                    Write-Verbose "With JSON: "
                    Write-Verbose $jsonbody

                    #Patch HTTP request
                    Invoke-RestMethodOverride -Method PATCH `
                                              -Uri $URI -Body $jsonbody `
                                              -ContentType 'application/json' `
                                              -WebSession $F5Session.WebSession

            }

            catch {
                    
                    Write-Error "Failure Adding Virtual server to Policy $policy"
                    Write-Error $_

            }


        }
        
    }#end process
}#end function

