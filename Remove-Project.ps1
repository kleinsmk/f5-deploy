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

                $vs = $virtuals | Where-Object { $_.pool -eq "$pool" }

                foreach ($rule in $vs.rules){

                    Write-Host "Remove-iRuleFromVirtualServer -Name '$($vs.name)' -iRuleName '$rule' "
                    if ($rule -ne "/Common/BAH_Hide_NAT_Source_Restriction") {
                        Write-Host "Remove-iRule -Name '$rule' -Confirm:`$false"
                    }
                    
                }

##############################Profile Removal Function#############################
                #SHOULD REDO THIS SO THAT IS FILTERS EXISTING VS PULL TO SAVE TIME
                $vsProfile =  $vs.name

                #grab all profiles reference links that have ssl and are therefore ssl client or server profiles    
                $profiles = $vs.profilesReference.items.namereference.link | Where-Object {$_ -match 'ssl'}
                #text processing to create an object with only the profile names
                $profiles = $profiles | ForEach-Object { ( $_.split('~Common~')[1] ).split('?')[0] }

                $serverProfiles = $profiles -match 'server'
                $clientProfiles =  $profiles -match 'client'

                Write-Host "Remove-SSL client $clienprofiles"
                Write-Host "Remove-SSLServer $serverProfiles "

#################################################                

                Write-Host "Remove-VirtualServer -Name $($vs.name) -Confirm:`$false"
                Write-Host "Remove-Pool -PoolName $pool -Confirm:`$false"

                $member = Get-PoolMember -PoolName $pool
                $member = $member.name.TrimEnd(":") 

                Write-Host "Remove-Node -Name $member -Confirm:`$false"
                Write-Host "Remove-Asm -policyname $($vs.policiesReference.items.name) -Confirm:`$false"
            }
        }
    }
                                
               
            
                


        
    
    