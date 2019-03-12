Function Remove-VsProfile {
<#
.SYNOPSIS
    Removes a profile object to an existing virtual server.
.DESCRIPTION
    The F5 api PATCH method does not patch and instead behaves like PUT for the Profile collections of a virtual server.
    This simple cmdlet fixes this issue.
.PARAMETER virtual
    Virtual server name to remove from
.PARAMETER profile
    Profile to remove from collection
.NOTES
    Requires F5-LTM modules from github
.EXAMPLE
    Remove-VsProfile -virtual AWS_WSA_vs -profile ssl_client
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
       #cast array as a mutable type to edit
       $profiles = [System.Collections.ArrayList]$profiles

       foreach ($item in $profile) {              
               
                $index = $profiles.IndexOf($item)

                if($index -ne -1){
                    $profiles.RemoveAt($index)
                }
                else{
                    throw "Profile name $item does not exist."
                }
                
        }

        #remove by updating wihtout
        Set-VirtualServer -Name $virtual -ProfileNames $profiles


   }
        
}