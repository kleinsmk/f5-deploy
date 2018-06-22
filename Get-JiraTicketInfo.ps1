Function Get-JiraTicketInfo {
<#
.SYNOPSIS
    Scrapes and returns powershell object with AWS Group, and Subnet info.
.NOTES
   
    Requires Posh-Jira Module from github
#>
    [cmdletBinding()]
    param(
        
        [Alias("CR-Number")]
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
                $awsGroup = ($desc | Select-String -Pattern " Create a CSN AD security group named") -split ":"

                $awsGroup = $awsGroup.Trimstart()
                $subnet = $subnet.TrimStart()

                #remove end of line characters etc
                $awsGroup = $awsGroup -replace "`t|`n|`r",""
                $subnet = $subnet -replace "`t|`n|`r",""
                               
                $envInfo =  [PSCustomObject]@{
	                'cr' = $crNumber
	                'aws_group' = $awsGroup[1]
	                'subnet' = $subnet[1]
                }

                $envInfo
            
        }
        
}