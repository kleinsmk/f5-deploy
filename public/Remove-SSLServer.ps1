Function Remove-SSLServer {
<#
.SYNOPSIS

    Removes an existing server ssl profile.

.PARAMETER profileName

.EXAMPLE

    Remove-SSLServer -profileName some_server

    Would remove some_server from the F5 server profiles
    
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
        if( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-date) ){
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



            $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/profile/server-ssl/~Common~$profileName") 
            $response = Invoke-RestMethodOverride -Method Delete -Uri $URI -WebSession $F5Session.WebSession
            $response
        }
        
}

