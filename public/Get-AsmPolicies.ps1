<#
.SYNOPSIS
    API wrapper to get all or specified F5 ASM policy objects.
.DESCRIPTION
    Gets all or specified F5 ASM policy objects.
.PARAMETER name
    Policy name to filter on.
.EXAMPLE
    Get-ASMPolicies
    
    Returns all the ASM polices as one policy object.
.Example
    Get-ASMPolicies -name policy_funtimes

    Returns existing ASM policy funtimes
.NOTES
   
    Requires F5-LTM modules from github
#>
Function Get-ASMPolicies {

    [cmdletBinding()]
    param(
        
        [Alias("acl Name")]
        [Parameter(Mandatory=$false)]
        [string[]]$name=''

    )

     begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }


    Process {

             
             $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies") 

            try {

                    if ([string]::IsNullOrEmpty($name)) {

                        $response = Invoke-RestMethodOverride -Method GET -Uri $URI -WebSession $F5Session.WebSession
                        $response 
                    }
                    
                    else{
                    
                        #set search query uri using on board F5 commands to reduce the data load and speed up processing
                        $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies?`$filter=fullPath+eq+%27%2FCommon%2F$name%27&`$select=id,name,virtualServers")

                        $policy = Invoke-RestMethodOverride -Method Get -URI $uri -WebSession $F5Session.WebSession

                        if ( $policy.totalitems -eq 0){

                            #return nothing                            
                        }

                        else {

                            $policy.items

                        }
         

                    
                    }               


                }

            catch {

                $_.Exception

            }
        }
}

    

  


