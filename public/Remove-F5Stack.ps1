    <#
    .SYNOPSIS
            Removes a VCD New-F5 stack.
    .DESCRIPTION
            Takes in an splat turned into a hash or object like the following:
                    $obj  = @{
                            dns = "n6ntebau1i.proto.aws.boozallencsn.com"
                            nodeIp = "10.192.1.124"
                            nodeport = "443"
                            vsport = "443"
                            vsip = (Get-NextFreeDestinationIP)
                            desc = "AWS_159829248391"
                            buildtype = "HTTPS"
                            sslClientProfile ="n6ntebau1i.proto.aws.boozallencsn.com_client"
                            SSLServerProfile = "n6ntebau1i.proto.aws.boozallencsn.com_server"
                            keyname = "n6ntebau1i.proto.aws.boozallencsn.com.key"
                            certname = "n6ntebau1i.proto.aws.boozallencsn.com.crt"
                            asmPolicyName = "n6ntebau1i.proto.aws.boozallencsn.com"
                            routingType = "Datagroup"
                            dataGroupName = "SNI_HostNames"
                            irulesToApply = "/Common/n6ntebau1i.proto.aws_header_insert"
                        }
        
    #>
    function Remove-F5Stack {

        param (

            [Parameter(Mandatory = $true)]
            [PSCustomObject[]]$inputObject
            
        )

        begin {
            # Powershell Inovke WebRequest Throws Exceptions for 404s so this gets wrapped in Messy multiple try catch blocks
            # I've modularized them with nested functions in an attemp a readability
            function removDataGroup {
            
                #remove DataGroup
                try {
                    Write-Host -ForegroundColor cyan "Attemping to Remove DataGroup.... " 
                    Remove-DataGroupIp -groupName "SNI_HostNames" -address $object.dns -ErrorAction Stop | Out-Null
                    Write-Host -ForegroundColor "Green" "Data Group $($object.dns) Removed."
            
                }
                catch { 
                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing Datagroup Failed: " 
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }
            
            }

            function removeVirtualServer {
            
                #remove VirtualServer
                try {
                    Write-Host -ForegroundColor cyan "Attemping to remove Virtual Server $($object.dns + "_https") "
                    Remove-VirtualServer -Name ($object.dns + "_https") -Confirm:$false -ErrorAction Stop | Out-Null
                    Write-Host -ForegroundColor "Green" "VirtualServer $($object.dns + "_https") Removed."
                }
                catch {
                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing Virtual Server Failed: " | Out-Null
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }

            }

            function removePool {

                #remove Pool
                try {
                    Write-Host -ForegroundColor cyan "Attemping to remove Pool $($object.dns + "_https") "
                    Remove-Pool -Name ($object.dns + "_https") -Confirm:$false -ErrorAction Stop | Out-Null
                    Write-Host -ForegroundColor "Green" "Pool $($object.dns + "_https") Removed."
                }
                catch {
                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing Pool Failed: " 
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }
            }
            function removeNode {

                
                try {
                    #nodes are always named but splats take either FQDN or IP
                    if ( ![string]::IsNullOrEmpty($object.nodeip) -or ![string]::IsNullOrEmpty($object.nodefqdn)  ) {
                        Write-Host -ForegroundColor cyan "Attemping to remove Node $($object.dns)"
                        Remove-Node -Name $object.dns -Confirm:$false -ErrorAction Stop | Out-Null
                        Write-Host -ForegroundColor "Green" "Node $($object.dns) Removed."
                    }

                }

                catch {

                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing Node Failed: "
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }

            }
        
            function removeAsm {

                try {
                    if ( ![string]::IsNullOrEmpty($object.asmPolicyName) ) {
                        Write-Host -ForegroundColor cyan "Attemping to remove ASM Policy $($object.asmPolicyName) "
                        #does not throw terminating error and needs to be updated
                        Remove-Asm -policyname $object.asmPolicyName -ErrorAction Stop | Out-Null
                        Write-Host -ForegroundColor "Green" "ASM Policy $($object.asmPolicyName) Removed."
                    }
                }

                catch {

                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing ASM Policy Failed: "
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }

            }

            function removeClientSslProfile {

                try {
                
                    if ( ![string]::IsNullOrEmpty($object.sslClientProfile) ) {
                        Write-Host -ForegroundColor cyan "Attemping to remove SSL Client Profile $($object.sslClientProfile) "
                        Remove-SSLClient -profileName $object.sslClientProfile -ErrorAction Stop | Out-Null
                        Write-Host -ForegroundColor "Green" "SSL Client Profile $($object.sslClientProfile) Removed."
                    }

                }

                catch {

                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing SSL Client Failed: "
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }

            }

            function removeServerSslProfile {

                try {
                
                    if ( ![string]::IsNullOrEmpty($object.sslServerProfile) ) {
                        Write-Host -ForegroundColor cyan "Attemping to remove Server Policy $($object.sslServerProfile) "
                        Remove-SSLServer -profileName $object.sslServerProfile -ErrorAction Stop | Out-Null
                        Write-Host -ForegroundColor "Green" "Server Profile $($object.sslServerProfile) Removed."
                    }

                }

                catch {

                    Write-Host -ForegroundColor red  -BackgroundColor Black "Removing SSL Server Profile Failed: "
                    Write-Host  -BackgroundColor Black $_.exception.message 
                }

            }
        }

        process {
            foreach ( $object in $inputObject) {

                #function calls in order of require removal from F5
                removDataGroup
                removeVirtualServer
                removePool
                removeNode
                removeAsm
                removeClientSslProfile
                removeServerSslProfile

                # to add later delete key and cert
                #DELETE Certificate: https://<f5_ip_address>/mgmt/tm/sys/crypto/cert/<certificate filename>
                #DELETE Private: https://<f5_ip_address>/mgmt/tm/sys/crypto/key/<private key filename>
                #DELETE CSR: https://<f5_ip_address>/mgmt/tm/sys/crypto/csr/<csr filename>
            }
        }
    
    }