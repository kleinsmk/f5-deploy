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
                    
                        $response = Invoke-RestMethodOverride -Method GET -Uri $URI -WebSession $F5Session.WebSession
                        $response | Select-Object -ExpandProperty items | where {$_.name -eq $name}
                    
                    }               


                }

            catch {

                $message = $Error[0].ErrorDetails.Message | ConvertFrom-Json
                Write-Host $message.message

            }
        }
}

    

  


