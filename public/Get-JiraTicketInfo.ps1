Function Get-JiraTicketInfo {
<#
.SYNOPSIS
    Scrapes jira ticket description and returns powershell object with cr number, AWS Group, and Subnet info.
    This cmdlet can only handle a single AWS group and a single user prive subnet in a ticket description.
.PARAMETER crName
    CR to scrape in the CR-#### format
.EXAMPLE
    Get-JiraTicketInfo -crNumber CR-0925

    Returns CR number, AWS group to be created, and User private subnet for accounts like AWS_293853093962 or Azure MAZ_8ccd4180-a8b6-413e-870f-b50af1e0647b
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

                #grab the subnet
                $subnet = ($desc | Select-String -Pattern "User Private Subnet") -split ":"

                #grab the aws account
                $awsGroup = ($desc | Select-String -Pattern "Create a CSN AD security group named") -split ":"

                $awsGroup = $awsGroup.Trimstart()
                $subnet = $subnet.TrimStart()

                #remove end of line characters etc
                $awsGroup = $awsGroup -replace "`t|`n|`r",""
                $subnet = $subnet -replace "`t|`n|`r",""
                
                #match for AWS account like AWS_293853093962 or Azure MAZ_8ccd4180-a8b6-413e-870f-b50af1e0647b
                if($awsGroup[1] -match '^AWS_[0-9]*$|^MAZ_[a-zA-Z0-9]*-[a-zA-Z0-9]*-[a-zA-Z0-9]*-[a-zA-Z0-9]*-[a-zA-Z0-9]*$'){
                    #match for CIDR like 10.194.83.192/26           
                    if( $subnet[1] -match '^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$' ){
                    
                        $envInfo =  [PSCustomObject]@{
	                    'cr' = $crNumber
	                    'aws_group' = $awsGroup[1]
	                    'subnet' = $subnet[1]
                        }

                        
                    }
                    else { Write-Error "Jira ticket has malforned User Private Subnet  info that cannot be scraped. Check for newline characters etc" -ErrorAction Stop }
                 
                }
                    

                else {
                        
                        Write-Error "Jira ticket has malforned AWS or Azure account info that cannot be scraped. Check for newline characters etc" -ErrorAction Stop
                }

                $envInfo
            
        }
        
}