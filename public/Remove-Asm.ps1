Function Remove-Asm {
<#
.SYNOPSIS
    Removes existing ACL object.  ACL must not be linked to a reasource group
.PARAMETER name
    Existing ACL name
.EXAMPLE
    Remove-ACL -name My_ACL

    Removes ACL My_ACL
.NOTES
   
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        [Alias("acl Name")]
        [Parameter(Mandatory=$true)]
        [string[]]$policyname=''

    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
        
    process {
        foreach ($name in $policyname) {

            #set search query uri
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies?`$filter=fullPath+eq+%27%2FCommon%2F$name%27&`$select=id")
            
            #try to find policy ID
            try{
                
                $policy = Invoke-RestMethodOverride -Method Get -URI $uri -WebSession $F5Session.WebSession

                if ( $policy.totalitems -eq 0){
                    Write-Warning "ASM Policy with name $name was not found and can not be removed."
                    break
                }
            }
            
            Catch{
                
                Write-Warning "Error Getting ASM policy ID."
                $_.ErrorDetails.Message
                break
            } 

            #policy set to uri with policy ID
            $policy = $policy.items[0].selfLink

            #trim to match uri format from other functions
            $policy = $policy.Replace("https://localhost/mgmt/tm","")

            $uri = $F5Session.BaseURL.Replace('/ltm/',"$policy")
            
            try{ 
                $response = Invoke-RestMethodOverride -Method Delete -Uri $URI -WebSession $F5Session.WebSession
                $true
            }

            catch{
                Write-Warning "Deleting ASM policy failed."
                $_.ErrorDetails.Message
                break
            }
        }
    }

}
        


