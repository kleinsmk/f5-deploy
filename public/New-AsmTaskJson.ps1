Function New-AsmTaskJson {
    <#
    .SYNOPSIS
     Creates special JSON to use with the Invoke-AsmTask cmdlet.
     
    .PARAMETER method
    The HTTP method to call, must be GET, PUT, POST, PATCH
     
    .PARAMETER restEndpoint
     The enpoint you wish your to execute your task at.  Must be in the format "mgmt/tm/asm/"

     .PARAMETER json
     The json body you would normally be sending in your HTTP request.  The F5 will queue this up as a task.

    .EXAMPLE
     New-AsmTaskJson -method "PATCH" -restEndpoint "mgmt/tm/asm/policies" -body $json
     
    .NOTES
     Requires f5-ltm from github
     
    #>
        [cmdletBinding()]
        param(
            
            
            [Parameter(Mandatory=$true)]
            [ValidateSet("GET","PUT","POST","PATCH")] 
            [string]$method,

            [Parameter(Mandatory=$true)]
            [string]$restEndpoint,

            [Parameter(Mandatory=$true)]
            [string]$json
    
        )
    
        process {
    
             
$json = @"
{
  "commands": [
        {
      "uri": "$restEndpoint",
      "body": $json,
      "method": "$method"
    }
  ]
}
"@

$json
                        
                
        }
            
}
    
    