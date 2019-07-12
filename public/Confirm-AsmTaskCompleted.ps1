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
Function Confirm-AsmTaskCompleted {

    [cmdletBinding()]
    param(
        
        [Alias("acl Name")]
        [Parameter(Mandatory=$false)]
        [string[]]$taskId=''

    )

     begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }


    Process {

        foreach ($id in $taskid){
            #set uri to asm task iD
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/tasks/bulk/$($id)") 
                        
            $taskStatus = $false

            Write-Verbose "Checking Task..."

            #check until completed
            while( $taskStatus -eq $false ){
                
                try{ 
                    
                    $response = Invoke-RestMethodOverride -Method GET -Uri $URI -ContentType 'application/json' -WebSession $F5Session.WebSession -ErrorAction Stop
                    
                    Write-Verbose "    [Status] $($response.status)"
                    
                    if ( $response.status -eq "FAILURE" ){ 
                        
                        throw "ASM Task $id has failed.  Please check the ASM logs."
                     }

                    if ( $response.status -eq "COMPLETED" ) { 
                        $taskStatus = $true 
                        return $true
                    }

                    Start-Sleep -Seconds 5
                }

                catch {
                    $false 
                    $_
                    break
                }
            }#while
        }
    }

}