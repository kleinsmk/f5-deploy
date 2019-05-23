﻿Function Get-PortInfoFromJira {
<#
.SYNOPSIS
    Scrapes jira ticket description for acl related varibles.
.Parameter crNumber
    Existing jira CR Ticket in format CR-####
.Example
    Get-PortInfoFromJira -crNumber CR-0925

    Returns VPN group, subnet, and ports
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

    process {
       
                try 
                {
                
                        $issue = $issue = Get-JiraIssue -Key $crNumber -ErrorAction Stop

                }

                catch 
                {
                        Write-Host "Failed to get the Jira issue with Key $crNumber"
                        Write-Error $_.Exception.Message
                        break
                        
                }


                try {
                        
                        #split the text by lines for select string
                        $desc = $issue.customfield_10508 -split "`n"

                        #grab the 
                        $source = (($desc | Select-String -Pattern "Source:") -split ":").trimstart()[1]
                        
                        #split by : then by , the return the array of ports skipping first entry
                        $ports = ((($desc | Select-String -Pattern "Ports:") -split ":") -split ",").trimstart() | Select-Object -Skip 1

                        #same as above but for destination
                        $destination = ((($desc | Select-String -Pattern "Destination:") -split ":") -split ",").trimstart() | Select-Object -Skip 1

                        [PSCustomObject]@{
                            'source' = $source
                            'ports' = $ports
                            'destination' = $destination
                        }
                }

                catch {
                        Write-Host "Error parsing ticket data in format: `n Source: `n Ports: `n Destination: "
                        Write-Error $_.Exception.Message
                        break
                }
               
                 
   }#end process
                 

                
            
        
        
}