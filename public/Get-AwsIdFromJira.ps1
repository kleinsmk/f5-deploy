﻿Function Get-AwsIdFromJira {
<#
.SYNOPSIS
    Scrapes and returns powershell object with AWS Group, and Subnet info.
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
                $desc = $issue.Description -split "`n"

                #grab the id
                $awsID = $desc | Select-String -Pattern "[0-9]{12}" | select matches

                #save the id as string only
                $awsID = $awsID.Matches[0].Value
                
                #check that the match was good or quit
                if($awsID -match '[0-9]{12}'){
                    
                        'AWS_'+$awsId
                        
                    }
                else { Write-Error "Jira ticket has malforned User Private Subnet  info that cannot be scraped. Check for newline characters etc" -ErrorAction Stop }
                 
   }#end process
                 

                
            
        
        
}