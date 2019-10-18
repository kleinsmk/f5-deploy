Function Remove-OldProject {
    <#
    .SYNOPSIS
        Removes existing F5 WSA Builds.
    .PARAMETER name
        Existing pool name
    .EXAMPLE
        Remove-OldProject -pool Some_Dead_Pool
    
        Removes ACL My_ACL
    .NOTES
       
        Requires F5-LTM modules from github
    #>
        [cmdletBinding()]
        param(
            
            [Parameter(Mandatory=$true)]
            [string[]]$oldPool=''
    
        )
            
        process {
            foreach ($pool in $oldPool) {
                
                #get
               
                $virtuals = Get-VirtualServer

                #filter for virtual object with matching pool    
                $vs = $virtuals | Where-Object { $_.pool -eq "$pool" }

                #are there any irules present?
                if( !([string]::IsNullOrEmpty($vs.rules)) ) {
                    foreach ($rule in $vs.rules){
                        #logic to remove irules from vs NEED TO MAKE SURE RULE IS OKAY TO REMOVE
                        Write-Host "Remove-iRuleFromVirtualServer -Name '$($vs.name)' -iRuleName '$rule' "
                        if ($rule -ne "/Common/BAH_Hide_NAT_Source_Restriction") {
                            Write-Host "Remove-iRule -Name '$rule' -Confirm:`$false"
                        }
                        
                    }
                }

                else { Write-Host "No iRules were attached to the server."}

##############################Profile Removal Function#############################

                #grab all profiles reference links that have ssl and are therefore ssl client or server profiles    
                $profiles = $vs.profilesReference.items.namereference.link | Where-Object {$_ -match 'ssl'}
                
                #text processing to create an object with only the profile names
                $profiles = $profiles | ForEach-Object { ( $_.split('~Common~')[1] ).split('?')[0] }
                
                #filter profiles by type since we need to know to remove them
                $serverProfiles = $profiles -match 'server'
                $clientProfiles =  $profiles -match 'client'

                #code to get profiles in order to grab key and profile info

                #code to detach an ssl profile first

                #code to get / delete key

                #code to get / delete cert
                
                #Code to then delte ssl profiles
                Write-Host "Remove-SSL client $clientprofiles"
                Write-Host "Remove-SSLServer $serverProfiles "

#################################################                

                #Code to Remove Virtual Server
                Write-Host "Remove-VirtualServer -Name $($vs.name) -Confirm:`$false"

                #Code to Remove Pool
                Write-Host "Remove-Pool -PoolName $pool -Confirm:`$false"

                #API call to grab pool members based on pool name
                $member = Get-PoolMember -PoolName $pool

                #Trim port info off end of pool member name
                $member = $member.name.TrimEnd(":") 

                #Commands to remove Node and ASM
                Write-Host "Remove-Node -Name $member -Confirm:`$false"
                Write-Host "Remove-Asm -policyname $($vs.policiesReference.items.name) -Confirm:`$false"
            }
        }
    }
                                
               
            
                


        
    
    