Function Get-SSLServer {
<#
.SYNOPSIS
 Gets a ssl server profile object.
.DESCRIPTION
 
.PARAMETER profileName
 Name of profile to get.

.EXAMPLE
 Get-SSLClient -profileName newsite.com_sslclient
 
.NOTES
 Requires f5-ltm from github
 
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

        try {

            foreach ($profile in $profileName) {

                $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/profile/server-ssl/~Common~${profilename}")
                $response = Invoke-RestMethodOverride -Method GET -Uri $URI -WebSession $F5Session.WebSession
                $response          
            }
        }

        catch {
            Write-Warning "Unable to Retrieve SSL Server Profile $profileName"
            return $False
        }
        
}
}
