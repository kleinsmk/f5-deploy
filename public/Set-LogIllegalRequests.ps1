Function Set-LogIllegalRequests {
    <#
    .SYNOPSIS
     Sets the log illegal requests drop down on a Virtual Ser ver
    .DESCRIPTION
     
    .PARAMETER serverName
     Name of the virtual server
    
    .EXAMPLE
     Set-LogIllegalRequests -serverName newsite.com
    
    .NOTES
     Requires f5-ltm from github
     
    #>
        [cmdletBinding()]
        param(
            
            
            [Parameter(Mandatory=$true)]
            [string[]]$serverName
    
        )
    

        process {
    
    
            foreach ($server in $serverName) {
                           
                $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/virtual/~Common~$server") 
         
                $json = @"
    
                {
                    "securityLogProfiles": [
                        "\"/Common/Log illegal requests\""
                    ]
                }
                
"@
                
                $response = Invoke-RestMethodOverride -Method PATCH -Uri $uri -Body $json -ContentType 'application/json' -WebSession $F5Session.WebSession
                $response    
            }
     
    
            
            
        }#end process
}#end function
    
    