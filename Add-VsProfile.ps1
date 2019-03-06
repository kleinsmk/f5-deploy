Function Add-VsProfile {
<#
.SYNOPSIS
    Adds a profile object to an existing virtual server.
.DESCRIPTION
    The F5 api PATCH method does not patch and instead behaves like PUT for the Profile collections of a virtual server.
    This simple cmdlet fixes this issue.
.PARAMETER virtual
    Virtual server name to append to
.PARAMETER profile
    Profile to append to collection
.NOTES
    Requires F5-LTM modules from github
.EXAMPLE
    Add-VsProfile -virtual AWS_WSA_vs -profile ssl_client

    Adds ssl_client to AWS_WSA_vs
#>
    [cmdletBinding()]
    param(
        

        [Parameter(Mandatory=$true)]
        [string]$virtual='',

        [Parameter(Mandatory=$true)]
        [string[]]$profile=''

    )
    begin {
        #check if session is active or else break
        Check-F5Token   
    }
    process {
       
       $profiles = (Get-VirtualServer -Name $virtual -ErrorAction Stop).profiles.name

       foreach ($item in $profile) { $profiles += $item }

       Set-VirtualServer -Name $virtual -ProfileNames $profiles
   }
        
}

