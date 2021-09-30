function Convert-VirtualtoSplat {
    [CmdletBinding()]
    param ( [string []] $virtualName
        
    )
    
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        if( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break

        }
    }

    process {

        foreach ( $item in $virtualName) {

                $vs = Invoke-RestMethodOverride -Method GET -URI  "https://aws/mgmt/tm/ltm/virtual/~Common~${item}?expandSubcollections=true" -WebSession $F5Session.WebSession
                $asmPolicyName = $vs.profilesReference.items.name[0].Replace("ASM_","")
                #$asmPolicyName = ($vs.policiesReference.items[0].name).replace("asm_auto_l7_policy__","")
                $sslClientProfileName = ($vs.profilesReference.items | where {$_.nameReference.link -like "*client-ssl*"}).name
                $sslServerProfileName = ($vs.profilesReference.items | where {$_.nameReference.link -like "*server-ssl*"}).name
                $networkInfo = (($vs.destination).Replace("/Common/","")).split(':') 
                $vsListeningPort = $networkInfo[1]
                $vsIp = $networkInfo[0]
                $accountNumber = $vs.description 

                $poolUri = ($vs.poolReference.link).Replace("https://localhost/mgmt/tm/ltm/", $F5Session.BaseURL)
                $poolUri = $poolUri.replace("ver=13.1.4.1", "expandSubcollections=true")
                $pool = Invoke-RestMethodOverride -Method GET -URI $poolUri -WebSession $F5Session.WebSession
                $nodePort = $pool.membersReference.items[0].name.split(":")[1]
                
                if ( $vsListeningPort -eq "443") {

                    $buildType = "HTTPS"
                } 
                else { 
                    $buildType = "HTTP" 
                }

                #check if property exists
                if ( $pool.membersReference.items[0].fqdn.psobject.Properties.name -contains "tmName" ) {

                    $nodeFQDN =  $pool.membersReference.items[0].fqdn.tmName

                }

                else { 
                    $nodeIP = $pool.membersReference.items[0].address
                }

                $sslClient = Get-SSLClient -profileName $sslClientProfileName
                $sslKey = ($sslClient.key).replace("/Common/","")
                $sslCert = ($sslClient.cert).replace("/Common/","")

                if ( $nodeFQDN -gt 1 ){
                    @"
                        `$build = @{
                            dns = ""
                            nodefqdn = "$nodeFQDN"
                            nodeport = "$nodePort"
                            vsport = "$vsListeningPort"
                            vsip = (Get-NextFreeDestinationIP)
                            desc = "$accountNumber"
                            buildtype = "$buildType"
                            sslClientProfile ="$sslClientProfileName"
                            SSLServerProfile = "$sslServerProfileName"
                            keyname = "$sslKey"
                            certname = "$sslCert"
                            asmPolicyName = "$asmPolicyName"
                            routingType = "Datagroup"
                            dataGroupName = "SNI_HostNames"

                        }
"@
                }
                else {
                    @"
                    `$build = @{
                        dns = ""
                        nodeIp = "$nodeIp"
                        nodeport = "$nodePort"
                        vsport = "$vsListeningPort"
                        vsip = (Get-NextFreeDestinationIP)
                        desc = "$accountNumber"
                        buildtype = "$buildType"
                        sslClientProfile ="$sslClientProfileName"
                        SSLServerProfile = "$sslServerProfileName"
                        keyname = "$sslKey"
                        certname = "$sslCert"
                        asmPolicyName = "$asmPolicyName"
                        routingType = "Datagroup"
                        dataGroupName = "SNI_HostNames"

                    }
"@
                }
        }
    }
    
}




