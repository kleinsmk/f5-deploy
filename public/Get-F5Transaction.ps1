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
        [Parameter(Mandatory=$true)]
        [string[]]$transId
       )

       process {  

            foreach ($trans in $transId) {
                $uri = $F5Session.BaseURL.Replace('/ltm/',"/transaction/$trans") 
                $response = Invoke-RestMethodOverride -Method GET -Uri $URI -WebSession $F5Session.WebSession
                $response
            }

       }
}
   
