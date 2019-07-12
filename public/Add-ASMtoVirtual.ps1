Function Add-ASMtoVirutal {
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

            $existingPolicy = Get-ASMPolicies -name $policyName

            #add to existing server array
            $servers = $existingPolicy.virtualServers += "/Common/$serverName"
            
            $object = [pscustomobject]@{ 'kind' = 'tm:asm:policies:policystate' ; 'virtualServers' = @()}
            
            $object.virtualServers += $servers
            
            $jssonbody = $object | ConvertTo-Json -Depth 5

            $asmTaskJson = New-AsmTaskJson -method "PATCH" -restEndpoint "mgmt/tm/asm/policies/$($existingPolicy.id)" -json $jssonbody
            
            Invoke-AsmTask -task $asmTaskJson

            Write-Debug $asmTaskJson

        }   
        
    }#end process
}#end function

