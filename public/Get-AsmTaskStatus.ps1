Function Get-AsmTaskStatus {
   <#
   .SYNOPSIS
       Gets the status of an ASM bulk task
   .Description
       Gets the status of an ASM bulk task given a taskID
   .PARAMETER taskId
       Task Id returned from Invoke-AsmTask
   .EXAMPLE
        Get-AsmTaskStatus -taskID 'jfkdajk3jk35j'
   .NOTES
      
       Requires F5-LTM modules from github
   #>
       [cmdletBinding()]
       param(
           
           [Alias("Common Name")]
           [Parameter(Mandatory=$true)]
           [string[]]$taskId    
   
       )

       process { 

            ForEach ($item in $taskId){

               $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/tasks/bulk/$taskId") 
               $response = Invoke-RestMethodOverride -Method Get -Uri $URI -ContentType 'application/json' -WebSession $F5Session.WebSession
               $response.Status
            }
       }
}
   
