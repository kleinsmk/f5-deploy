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
    [Parameter(Mandatory=$true)]
    [string[]]$transId
   )

   process {  

        foreach ($trans in $transId) {

            try{
                $uri = $F5Session.BaseURL.Replace('/ltm/',"/transaction/$trans") 
                $response = Invoke-RestMethodOverride -Method PATCH -Uri $URI -Body "{ `"state`":`"VALIDATING`" }" -ContentType 'application/json' -WebSession $F5Session.WebSession
                $response
            }

            catch {

               Write-Output "An error occured commiting the transaction. No changes have been saved. Review the error below."
               throw $_.ErrorDetails
               Write-Output ""

            }
        }

   }

}


