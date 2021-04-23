Function Get-AccountInfoFromJira {
<#
.SYNOPSIS
    . Converts jira ticket description from JSON and returns the environment name or account number
.Parameter crNumber
    Existing jira CR Ticket in format CR-####
.Example
    Get-AwsIdFromJira -crNumber CR-0925

    Returns account Name from descriptoin field if it exists.
.NOTES
   
    Requires Posh-Jira Module from github
#>
    [cmdletBinding()]
    param(
        
        #CR number as CR-########
        [Alias("CR-Number")]
        [ValidatePattern("[a-zA-Z]{2}-[0-9]*")]
        [Parameter(Mandatory=$true)]
        [string]$crNumber=''

    )
    begin {
        
             
    }
    process {
       
                try 
                {
                
                        $issue = $issue = Get-JiraIssue -Key $crNumber -ErrorAction Stop

                }

                catch 
                {
                        Write-Error $_.Exception.Message
                        break
                        
                }

                #split the text by lines for select string
                $desc = $issue.Description | ConvertFrom-Json
                
                #try to match for aws or maz account number
                $account = $desc.Account | Select-String -Pattern "\w+-\w+-\w+-\w+-\w+|[0-9]{12}" | select matches

                #if account isn't empty
                if ( !([string]::IsNullOrEmpty($account)) ){

                    #save the id as string only
                    $account = $account.Matches[0].Value
                    
                    #check that the match was good and prepend AWS or MAZ as needed by VPN or return base acocunt for on-prem
                    if($account -match '[0-9]{12}'){
                        
                            'AWS_'+$account
                            
                        }
                    elseif($account -match '\w+-\w+-\w+-\w+-\w+'){
                        
                            'MAZ_'+$account
                    }
                }
                #return the account as is for on-prem style accounts
                else { $desc.account }
                 
   }#end process
                 

                
            
        
        
}