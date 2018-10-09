function Rollback-VCD {

 
  param(

    [Alias("existing acl Name")]
    [ValidatePattern("[a-zA-Z]{2}-[0-9]*")]
    [Parameter(Mandatory = $true)]
    [string[]]$rollBack_Element = ''

  )

  process {

    Write-Warning "Rolling back changes....."

    Foreach ($item in $rollBack_Element){

        switch ($rollBack_ElementName) {

           "pool" {
              Write-Error "Failed to create pool."
              Write-Warning "Removing Pool...."
              Remove-Pool -PoolName ${vsName} -Confirm:$false
              Write-Warning "Pool ${vsName} has been removed."
              break
           }

           "node" {
              Write-Warning "Removing Node...."
              Remove-Node -Name $nodeName -Confirm:$false
              Write-Warning "Node ${nodeName} has been removed."
              break
           }

           "virtual"{
              Write-Warning "Revmoing Virtual Sever....."
              Remove-VirtualServer -Name ${vsName} -Confirm:$false | Out-Null
              Write-Warning "Virtual server $vsname has been removed."
              break
           }

           "irule"{
              Write-Warning "Removing iRule from Virtual Server"
              Remove-iRuleFromVirtualServer -Name $wsa -iRuleName $vsname
              Write-Output "Removed iRule $vsname fom Virtual $vsname"
              Write-Warning "Removing iRule"
              Remove-iRule -Name $vsname -Confirm:$false
              Write-Warning "Removed iRule $vsname ."
            }

            "serverssl"{

            }

            "clientssl"{
            }

            "asm"{

            }
                
        }
    }#end foreach
  }

}