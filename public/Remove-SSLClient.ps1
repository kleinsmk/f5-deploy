Function Remove-SSLClient {
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
        [string[]]$profileName=''

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



            $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/profile/client-ssl/~Common~$profileName") 
            $response = Invoke-RestMethodOverride -Method Delete -Uri $URI -WebSession $F5Session.WebSession
            $response
        }
        
}

