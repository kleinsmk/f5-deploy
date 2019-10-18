Function Invoke-F5Transaction {
   <#
   .SYNOPSIS
       Commits logged Transactions on F5 Load Balancer
   .Description
       Commits logged Transactions on F5 Load Balancer
   .EXAMPLE
       Invoke-F5Transaction
   .NOTES
      
       Requires F5-LTM modules from github
   #>
       [cmdletBinding()]
       param(
   
       )

       process {        

            $uri = $F5Session.BaseURL.Replace('/ltm/','/transaction') 
            $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body "{ `"state`":`"VALIDATING`" }" -ContentType 'application/json' -WebSession $F5Session.WebSession
            $response
       }
}
   
