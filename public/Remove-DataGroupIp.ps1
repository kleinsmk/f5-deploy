Function Remove-DataGroupIp {
<#
.SYNOPSIS
    Adds a new data pair to a DataGroup IP
.DESCRIPTION
    Adds a new data pair to a DataGroup IP
.PARAMETER virtual
    Virtual server name to append to
.PARAMETER profile
    Profile to append to collection
.NOTES
    Requires F5-LTM modules from github
.EXAMPLE
    Add-DataGroupIP
#>
    [cmdletBinding()]
    param(
        

        [Parameter(Mandatory=$true)]
        [string]$groupName,

        [Parameter(Mandatory=$true)]
        [string[]]$address

    )
    begin {
        #check if session is active or else break
        Check-F5Token   
    }
    process {
       
        $json = "{`"name`":`"$groupName`"}"

        foreach ($ip in $address) {

                $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/data-group/internal/$groupName" + "?options=records+delete+{$ip}")

                Invoke-RestMethodOverride -Method PATCH -URI $uri -WebSession $F5Session.WebSession -ContentType 'application/json' -Body $json
            }
    }
   
        
}
