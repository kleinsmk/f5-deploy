Function Get-AsmApplyPolicyStatus {
   <#
   .SYNOPSIS
       Gets the status of all ASM apply policy tasks
   .Description
       Gets the status of all ASM apply policy tasks
   .EXAMPLE
        GGet-AsmApplyPolicyStatus
   .NOTES
      
       Requires F5-LTM modules from github
   #>

       process { 

               $uri = $F5Session.BaseURL.Replace('/ltm/','/asm/tasks/apply-policy') 
               $response = Invoke-RestMethodOverride -Method Get -Uri $URI -ContentType 'application/json' -WebSession $F5Session.WebSession
               $response.items
        }
}

   
