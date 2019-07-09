Function Get-AsmTaskStatus {
   <#
   .SYNOPSIS
       Starts ASM Task on F5 Load Balancer
   .Description
       Starts ASM Task on F5 Load Balancer and returns the ASM task object.
   .PARAMETER json
       Special JSON from the New-AsmTask cmdlet
   .EXAMPLE
       Invoke-AsmTask -json $task
   .NOTES
      
       Requires F5-LTM modules from github
   #>
       [cmdletBinding()]
       param(
           
           [Alias("Common Name")]
           [Parameter(Mandatory=$true)]
           [string[]]$task
   
       )

       process { 

            ForEach ($item in $task){

               $uri = $F5Session.BaseURL.Replace('/ltm/','/asm/tasks/bulk') 
               $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body $item -ContentType 'application/json' -WebSession $F5Session.WebSession
               $response
            }
       }
}
   
