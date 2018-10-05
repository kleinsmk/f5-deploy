Function New-SSLServer {
<#
.SYNOPSIS

.PARAMETER name

.PARAMETER dstSubnet

.PARAMETER aclOrder


.EXAMPLE

.EXAMPLE


	
.EXAMPLE
   .NOTES
   
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        
        [Parameter(Mandatory=$true)]
        [string[]]$profileName='',

        [Parameter(Mandatory=$true)]
        [string[]]$cert='',

        [Parameter(Mandatory=$true)]
        [string[]]$key=''

    )

    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        if( $F5Session.WebSession.Headers.'Token-Expiration' -lt (date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break

        }

        
        }

    process {


        foreach ($profile in $profileName) {


$JSONBody = @"
{
    "kind":  "tm:ltm:profile:client-ssl:client-sslstate",
    "name":  "$profileName",
    "cert":  "$cert",
    "chain":  "$cert",
    "key":  "$key"

                    
}
    
"@

    }



            $uri = $F5Session.BaseURL.Replace('/ltm/','/ltm/profile/server-ssl') 
            $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession
            $response
        }
        
}

