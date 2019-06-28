Function Get-PortInfoFromJira {
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
        [string]$crNumber

    )
    begin {
                 
             
    }
    process {
                #parses data based on pass pattern value into objects of array
                function Get-ParsedData {

                    param (
                        [string[]]$inputString,
                        [string]$pattern
                    )
                    
                    $array = @()

                    #split description into an array of lines that match the input pattern
                    $inputString = $inputString | Select-String -Pattern $pattern
                    #remove end of line characters etc
                    $inputString = $inputString -replace "`t|`n|`r",""

                    #loop through the array an return a custom object of arrays of 
                    foreach ($item in $inputString){

                       #split input into array of items speperated by commas 
                       $item = ($item -split ":" -split ",").trimstart()

                       #filter out line label "Ports:"
                       [array]$item = $item | Where-Object {$_ -ne $pattern}
                       
                       #POWERSHELL NEEDS A GODDAMNED COMMA TO ADD SINGLE ITEMS TO AN ARRRAY!
                       $array += , $item
                    } 
                    
                    ##POWERSHELL NEEDS A GODDAMNED COMMA TO RETURN SINGLE ITEMS AS AN ARRRAY!
                    return , $array


                }

                try 
                {
                
                        $issue = Get-JiraIssue -Key $crNumber -ErrorAction Stop

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
                        [array]$source = Get-ParsedData -inputString $desc -pattern "Source"
                        
                        #split by : then by , the return the array of ports skipping first entry
                        [array]$ports = Get-ParsedData -inputString $desc -pattern "Ports"

                        #same as above but for destination
                        [array]$destination = Get-ParsedData -inputString $desc -pattern "Destination"

                        $output = @()

                        for ($i = 0; $i -lt $source.Count; $i++) {
                            
                            $output += [PSCustomObject]@{
                                'source' = $source[$i]
                                'ports' = $ports[$i]
                                'destination' = $destination[$i]
                                }
                        }
                        
                        $output
                        
                }

                catch {
                        Write-Host "Error parsing ticket data in format: `n Source: `n Ports: `n Desintaion: "
                        Write-Error $_.Exception.Message
                        break
                }
               
                 
   }#end process
                 

                
            
        
        
}
