Function Add-FqdnPoolMember {
    <#
.SYNOPSIS
 Adds a pool FQDN pool member with autopopulate enabled.

 This function is reququired because the POSH-LTM Add-PoolMember function is broken such
 that it does correcly add FQDN nodes with auto populate enabled.

 A pull request fixing this issue was rejected requiring this module to be created.
.DESCRIPTION
 
.PARAMETER poolName
 Name of the existing node to be added.

.PARAMETER nodePort
 Listening port of node

.PARAMETER nodeFqdn
 FQDN of the node

.EXAMPLE
 Add-FqdnPoolMember -nodName testnode.com -nodePort 443 -nodeFQDN docker.io
 
.NOTES
 Requires f5-ltm from github
 
#>
    [cmdletBinding()]
    param(
        
        
        [Parameter(Mandatory = $true)]
        [string]$poolName = '',

        [Parameter(Mandatory = $true)]
        [string]$nodePort = '',

        [Parameter(Mandatory = $true)]
        [string]$nodeName = '',

        [Parameter(Mandatory = $true)]
        [string]$nodeFqdn = ''

    )

    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        if ( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-Date) ) {
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break

        }
    }

    process {

            $JSONBody = @"
            {                                                                          
              "kind": "tm:ltm:pool:members:membersstate",
              "name": "$nodeName`:$nodePort",  
              "partition": "Common",
              "address": "any6",
              "connectionLimit": 0,
              "dynamicRatio": 1,
              "ephemeral": "false",
              "fqdn": {
                "autopopulate": "enabled",
                "tmName": "$nodeFqdn"
              },
              "inheritProfile": "enabled",
              "logging": "disabled",
              "monitor": "default",
              "priorityGroup": 0,
              "rateLimit": "disabled",
              "ratio": 1,
              "session": "user-enabled" 
            }                   

"@

$JSONBody
            $uri = $F5Session.BaseURL.Replace('/ltm/', "/ltm/pool/~Common~$poolName/members")
            Invoke-RestMethodOverride -Method Post -URI $URI -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession
    
        
    }
        
}#end function

