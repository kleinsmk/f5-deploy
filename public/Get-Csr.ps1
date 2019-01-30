Function Get-Csr {
<#
.SYNOPSIS
    Fetches existing or created CSR files from and F5 Load Balancer
.Description
    User generally must specify .csr at the end of the common name used to generate the csr. Returns CSR text directly to console output.  
.PARAMETER csrName
    CSR to retrieve for a specified commonName.  Generally must have .csr appened to the end like boozallencsn.com.csr
.EXAMPLE
    Get-Csr -csrName boozallencsn.com.csr
.NOTES
   
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        [Alias("Common Name")]
        [Parameter(Mandatory=$true)]
        [string[]]$csrName=''

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


        foreach ($name in $csrName) {


$JSONBody = @"
{
"command":"run",
"utilCmdArgs":"-c 'tmsh list sys crypto csr $name'"
	
}
    
"@

    }



            $uri = $F5Session.BaseURL.Replace('/ltm/','/util/bash') 
            $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession
            #trim off tmsh from end In of command result
            $response.commandResult -replace "sys crypto csr(?s)(.*$)"
        }
        
}

