function Rollback-VCD {

 
  param(

    [Parameter(Mandatory = $true)]
    [string[]]$rollBack_Element = ''

  )

  process {

    Write-Warning "Rolling back changes....."

    Foreach ($item in $rollBack_Element){

        switch ($item) {

           "pool" {
              Write-Warning "Removing Pool....."
              Remove-Pool -PoolName ${vsName} -Confirm:$false | Out-Null
              Write-Warning "Pool ${vsName} has been removed."
              break
           }

           "node" {
                try{
                    
                      Write-Warning "Removing Node....."
                      Remove-Node -Name $nodeName -Confirm:$false -ErrorAction Stop
                      Write-Warning "Node ${nodeName} has been removed."
                      break
                    
                }

                catch{

                    Write-Warning "Problems occured removing node $nodeName."
                    Write-Warning $_
                }
           }

           "virtual"{
              Write-Warning "Revmoing Virtual Sever....."
              Remove-VirtualServer -Name ${vsName} -Confirm:$false | Out-Null
              Write-Warning "Virtual server $vsname has been removed."
              break
           }

           "irule"{
              Write-Warning "Removing iRule from Virtual Server....."
              Remove-iRuleFromVirtualServer -Name $wsa -iRuleName $vsname
              Write-Output "Removed iRule $vsname fom Virtual $vsname"
              Write-Warning "Removing iRule"
              Remove-iRule -Name $vsname -Confirm:$false | Out-Null
              Write-Warning "Removed iRule $vsname ."
            }

            "serverssl"{
              #only remove newly created profiles in failure  
              If( $serverProfileCreated -eq $true){
                  Write-Warning "Removing Server SSL profile......"
                  Remove-SSLServer -profileName $SSLServerProfile | Out-Null
                  Write-Warning "Removed Server SSL profile $sslClientProfile."
              }

            }

            #only remove newly created profiles in failure  
            "clientssl"{
              If( $clientProfileCreated -eq $true){
                  Write-Warning "Removing Client SSL profile......"
                  Remove-SSLClient -profileName $SSLClientProfile | Out-Null
                  Write-Warning "Removed Client SSL profile $SSLServerProfile."
              }

            }

            #do we really want to remove ASM profile since it takes sooo long to create?
            #for the moment we are going to not rollback ASM policies as they will only be created if
            "asm"{
          

            }
                
        }
    }#end foreach
  }

}