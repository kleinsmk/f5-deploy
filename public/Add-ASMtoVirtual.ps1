Function Add-ASMtoVirutal {
<#
.SYNOPSIS
 Adds and ASM policy to a virutal Server
.DESCRIPTION
 
.PARAMETER serverName
 Name of the virtual server

.PARAMETER policy
 Name of existing ASM policy you wish to apply to a virtual server.

.EXAMPLE
 Add-ASMtoVirutal -serverName newsite.com -policy newsite.com_asm
 
.NOTES
 Requires f5-ltm from github
 
#>
    [cmdletBinding()]
    param(
        
        
        [Parameter(Mandatory=$true)]
        [string[]]$serverName='',

        [Parameter(Mandatory=$true)]
        [string[]]$policyName=''
    )

    begin {
        #Test that the F5 session is in a valid format
        Check-F5Token
        }

    process {


        foreach ($policy in $policyName) {

            $existingPolicy = Get-ASMPolicies -name $policyName

            #add to existing server array
            $servers = $existingPolicy.virtualServers += "/Common/$serverName"
            
            $object = [pscustomobject]@{ 'kind' = 'tm:asm:policies:policystate' ; 'virtualServers' = @()}
            
            $object.virtualServers += $servers
                       
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies/$($existingPolicy.id)") 
            $jssonbody =  $object | ConvertTo-Json
            $response = Invoke-RestMethodOverride -Method PATCH -Uri $URI -Body $jssonbody -ContentType 'application/json' -WebSession $F5Session.WebSession
            $response

            #apply policy on virutal server
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/virtual/~Common~$serverName") 

$json = @"

{
	"securityLogProfiles": [
        "\"/Common/Log illegal requests\""
    ]
}

"@
            $response = Invoke-RestMethodOverride -Method PATCH -Uri $URI -Body $json -ContentType 'application/json' -WebSession $F5Session.WebSession
            $response
 

        }
        
    }#end process
}#end function

