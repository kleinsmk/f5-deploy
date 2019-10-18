Function Stop-F5Transaction {
   <#
   .SYNOPSIS
       Stops ASM Transaction logging on F5 Load Balancer
   .Description
       Stops ASM Transaction logging on F5 Load Balancer.  This will remove the headers from the session that cause logging.
   .EXAMPLE
       Start-Transaction
   .NOTES
      
       Requires F5-LTM modules from github
   #>
       [cmdletBinding()]
       param(
   
       )

       process {        

            $F5Session.WebSession.Headers.Remove("X-F5-REST-Coordination-Id")

       }
}
   
