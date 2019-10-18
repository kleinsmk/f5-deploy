Function Start-F5Transaction {
   <#
   .SYNOPSIS
       Starts ASM Transaction logging on F5 Load Balancer
   .Description
       Starts ASM Transaction logging on F5 Load Balancer.  This will capture all POST requests to be batch deployed
       via the transaction model.  This model only executes the changes if it determines all subtasks will complete.
   .EXAMPLE
       Start-Transaction
   .NOTES
      
       Requires F5-LTM modules from github
   #>
       [cmdletBinding()]
       param(
   
       )

       process {        

               $uri = $F5Session.BaseURL.Replace('/ltm/','/transaction') 
               $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body "{}" -ContentType 'application/json' -WebSession $F5Session.WebSession
        
               #Add headers to existing F5 Session to caputre POSTS as transactions
               $F5Session.WebSession.Headers.Add("X-F5-REST-Coordination-Id",$($response.transId))
               $true
       }
}
   
