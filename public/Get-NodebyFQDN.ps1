Function Get-NodeByFQDN {
<#
.SYNOPSIS
    Fetches the Node with the given FQDN member.
.Description
    Get-Node from POSH-LTM does not have this behavior int it's Get-Node cmdlet.
.PARAMETER -fqdn
    The FQDN you wish to search for.
.EXAMPLE
    Get-FQDNbyNode -fqdn www.google.com 
.NOTES
   
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        [Parameter(Mandatory=$true)]
        [string[]]$fqdn

    )


    process {


        foreach ($name in $csrName) {

            $uri = $F5Session.BaseURL.Replace('/ltm/','/util/bash') 

        }
        
    }
}

