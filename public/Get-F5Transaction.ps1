Function Get-F5Transaction {
   <#
   .SYNOPSIS
       Checks status of logged Transactions on F5 Load Balancer
   .Description
       Checks status of logged Transactions on F5 Load Balancer
   .EXAMPLE
       Get-F5Transaction
   .NOTES
      
       Requires F5-LTM modules from github
   #>
       [cmdletBinding()]
       param(
   
       )

       process {        

            $uri = $F5Session.BaseURL.Replace('/ltm/','/transaction') 
            $response = Invoke-RestMethodOverride -Method GET -Uri $URI -WebSession $F5Session.WebSession
            $response
       }
}
   
