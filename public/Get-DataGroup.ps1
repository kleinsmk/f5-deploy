Function Get-DataGroup {
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
        [string]$groupName

    )
    begin {
        #check if session is active or else break
        Check-F5Token   
    }
    process {
       
        foreach ($name in $groupName) {

                $uri = $F5Session.BaseURL.Replace('/ltm/',"/ltm/data-group/internal/$groupName")

                 $records = Invoke-RestMethodOverride -Method Get -URI $uri -WebSession $F5Session.WebSession
                 $records.records
            }
    }
   
        
}
