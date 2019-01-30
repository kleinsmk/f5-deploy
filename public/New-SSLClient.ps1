Function New-SSLClient {
<#
.SYNOPSIS
 Creates a new ssl client profile.
.DESCRIPTION
 
.PARAMETER profileName
 Name you would like the profile to be called.

.PARAMETER cert
 Name of existing cert on F5.  Please make sure to add .crt to end of the name as F5 does this without telling you when you upload.

.PARAMETER key
 Name of existing key on F5.  File extension is .key .

.EXAMPLE
 New-SSLClient -profileName newsite.com_sslclient -cert newsite.com.crt -key newsite.com.key
 
.NOTES
 Requires f5-ltm from github
 
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



            $uri = $F5Session.BaseURL.Replace('/ltm/','/ltm/profile/client-ssl') 
            $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession
            $response
        }
        
}

