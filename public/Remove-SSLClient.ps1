Function Remove-SSLClient {
<#
.SYNOPSIS

    Removes an existing client ssl profile.

.PARAMETER profileName

.EXAMPLE

    Remove-SSLClient -profileName some_client

    Would remove some_client from the F5 client profiles
    
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


            $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/profile/client-ssl/~Common~$profileName") 
            $response = Invoke-RestMethodOverride -Method Delete -Uri $URI -WebSession $F5Session.WebSession
            $response
        }
        
}

}#end function

