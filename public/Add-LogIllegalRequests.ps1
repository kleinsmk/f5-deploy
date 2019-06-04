 Function Add-LogIllegalRequests {
<#
.SYNOPSIS
 Adds Log Illegal requets setting to ASM policy attached to a virtual server
.DESCRIPTION
 
.PARAMETER serverName
 Name of the virtual server

.EXAMPLE
 Add-LogIllegalRequets -serverName newsite.com

.NOTES
 Requires f5-ltm from github
 
#>
    [cmdletBinding()]
    param(
        
        
        [Parameter(Mandatory=$true)]
        [string[]]$serverName
    )

    begin {

            #Test that the F5 session is in a valid format
            Check-F5Token
    }

    process {

        #Jason payload as here string
        $json = @"

{
	"securityLogProfiles": [
        "\"/Common/Log illegal requests\""
    ]
}

"@

        foreach ($server in $serverName) {         

            try {

                    $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/virtual/~Common~$server") 

                    Invoke-RestMethodOverride -Method PATCH `
                                              -Uri $URI `
                                              -Body $json `
                                              -ContentType 'application/json' `
                                              -WebSession $F5Session.WebSession
            
            }

            catch {

                    Write-Error "Failure setting `"Log Illegal Requests`" on Virutal Server $server"
                    Write-Error $_ 

            }


        }
        
    }#end process
}#end function

