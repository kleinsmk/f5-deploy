Function New-Csr {
<#
.Description

Generate New CSR for a given commonName.  Geneartes private keypair on the connected F5 and then creates a CSR.

.PARAMETER commonName

The common name which you want to genearte a CSR request for.

.EXAMPLE

New-Csr -commonName something.boozallencsn.com
	
.EXAMPLE
   .NOTES
   
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        [Alias("Common Name")]
        [Parameter(Mandatory=$true)]
        [string[]]$commonName=''

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


        foreach ($name in $commonName) {


$JSONBody = @"
{
  "command": "run",
  "utilCmdArgs": "-c 'tmsh create sys crypto key $name key-size 2048 gen-csr country US city Mclean state VA organization BAH ou CSN common-name \"$name\"'"
}
    
"@

    }



            $uri = $F5Session.BaseURL.Replace('/ltm/','/util/bash') 
            $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession
            $response
        }
        
}

