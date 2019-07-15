Function Start-ApplyAllAsmPolicies {
  <#

  .DESCRIPTION
      Creates and apply policy task for each existing ASM policy in the F5
  .NOTES
      Requires F5-LTM modules from github
  .EXAMPLE
      Start-ApplyAllAsmPolicies
  #>

      begin {
          #check if session is active or else break
          Check-F5Token   
      }
      process {
         
          $policy = Get-ASMPolicies

          $array = @()

          foreach ($selflink in $policy.items.selflink){ 

          $array += @"
{
     "policyReference":
     {
       "link": "$selflink"
   
     }
   }
"@
          } 
  
          $uri = $F5Session.BaseURL.Replace('/ltm/','/asm/tasks/apply-policy')
$array
          foreach ($item in $array) {               
                    
                  Invoke-RestMethodOverride -Method POST -URI $uri -Body $item -ContentType "application/json" -WebSession $F5Session.WebSession 
          }
     }
          
  }
  

