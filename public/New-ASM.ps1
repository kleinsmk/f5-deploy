Function New-ASMPolicy {
<#
.SYNOPSIS
    Creates a new ASM policy and sets whitelist exclusions for 128.229.4.2, 156.80.4.2, and a do not trust for 54.225.156.133
.PARAMETER name
    The new name of the ASM policy
.EXAMPLE
    New-ASMPolicy -name Test_ASM

    Creates a new ASM policy named Test_ASM

.EXAMPLE
    
.NOTES
   
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        [Alias("acl Name")]
        [Parameter(Mandatory=$true)]
        [string[]]$policyname=''

    )
    begin {
      
      if( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break
        }
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        
        #if statement below adds acl order if param is present or blank if false
     

    }
    process {
        foreach ($name in $policyname) {


        $JSONBody = @"
        {
  "commands": [
    {
      "uri": "/mgmt/tm/asm/policies",
      "body": {
        "type": "security",
        "name": "$policyname",
        "caseInsensitive": false,
        "protocolIndependent": false,
        "partition": "Common",
        "applicationLanguage": "utf-8",
        "enforcementMode": "blocking",
        "policy-builder": {
          "learningMode": "automatic"
        },
        "signature-settings": {
          "signatureStaging": true
        },
        "general": {
          "enforcementReadinessPeriod": 7
        },
        "templateReference": {
          "link": "/mgmt/tm/asm/policy-templates/KGO8Jk0HA4ipQRG8Bfd_Dw"
        }
      },
      "method": "POST"
    }
  ]
}
"@

            $uri = $F5Session.BaseURL.Replace('/ltm/','/asm/tasks/bulk')
            
            try{ 
                $response = Invoke-RestMethodOverride -Method Post -Uri $URI -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession
                Write-Verbose "New AMS policy creation task started..."
            }

            catch { 
                Write-Warning "Error creating ASM policy task."
                $_.ErrorDetails.Message
                break
            }

            #set uri to asm task iD
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/tasks/bulk/$($response.id)") 
            
            $taskStatus = $false

            Write-Verbose "Checking Task..."

            #check until completed
            while( $taskStatus -eq $false ){
                try{ 
                    
                    $response = Invoke-RestMethodOverride -Method GET -Uri $URI -ContentType 'application/json' -WebSession $F5Session.WebSession
                    Write-Verbose "    [Status] $($response.status)"
                    if ( $response.status -eq "FAILURE" ){ Write-Warning $response.errors; break; }
                    if ( $response.status -eq "COMPLETED" ) { $taskStatus = $true }
                    Start-Sleep -Seconds 5
                }

                catch { 
                    Write-Warning "Error checking ASM policy task."
                    $response.errors
                    break
                }
            }#while

            # required to check for error due to the way break cmd works
            if ( $response.status -eq "FAILURE" ){ break }

            #set uri to filer for newly create policy id
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies?`$filter=fullPath+eq+%27%2FCommon%2F$policyname%27&`$select=id") 

            try{ 
                    
                    $response = Invoke-RestMethodOverride -Method GET -Uri $URI -ContentType 'application/json' -WebSession $F5Session.WebSession
                    $id = $response.items.id
          
                }

                catch { 
                    Write-Warning "Error Getting ASM policy ID."
                    $_.ErrorDetails.Message
                    break
                }

            #set uri for adding whitlist Ips
            $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies/$id/whitelist-ips") 

                    $json1 = @"

                    {
          "ipAddress": "128.229.4.2",
          "ipMask": "255.255.255.255",
          "description": "",
          "trustedByPolicyBuilder": true,
          "neverLearnRequests": false,
          "neverLogRequests": false,
          "ignoreAnomalies": false,
          "ignoreIpReputation": false,
          "blockRequests": "policy-default"
        }
"@

                    $json2 = @"
        {
          "ipAddress": "156.80.4.2",
          "ipMask": "255.255.255.255",
          "description": "",
          "trustedByPolicyBuilder": true,
          "neverLearnRequests": false,
          "neverLogRequests": false,
          "ignoreAnomalies": false,
          "ignoreIpReputation": false,
          "blockRequests": "policy-default"
        }
"@

                    $json3 = @"
        {
          "ipAddress": "54.225.156.133",
          "ipMask": "255.255.255.255",
          "description": "",
          "trustedByPolicyBuilder": false,
          "neverLearnRequests": false,
          "neverLogRequests": false,
          "ignoreAnomalies": false,
          "ignoreIpReputation": false,
          "blockRequests": "policy-default"
        }
"@



                try{ 
                    #add first exemption IP
                    
                    $response = Invoke-RestMethodOverride -Method POST -Uri $URI -ContentType 'application/json' -Body $json1 -WebSession $F5Session.WebSession
                    Write-Verbose "`nAdded 128.229.4.2 to whitelist..."
                    #add second exemption IP
                    $response = Invoke-RestMethodOverride -Method POST -Uri $URI -ContentType 'application/json' -Body $json2 -WebSession $F5Session.WebSession
                    Write-Verbose "Added 156.80.4.2 to whitelist..."
                    $response = Invoke-RestMethodOverride -Method POST -Uri $URI -ContentType 'application/json' -Body $json3 -WebSession $F5Session.WebSession
                    Write-Verbose "Added 54.225.156.133 with 'Don't Trust' to whitelist..."
                }

                catch { 
                    Write-Warning "Error Adding Whitelist IP to ASM policy."
                    $_.ErrorDetails.Message
                    break
                }

                #set uri for patching readyness state
                $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies/$id/general")
                
                $JSONBody = "{`"enforcementReadinessPeriod`":7}"
                 
                try{ 
                    #patch readyness period
                    $response = Invoke-RestMethodOverride -Method Patch -Uri $URI -ContentType 'application/json' -Body $JSONBody -WebSession $F5Session.WebSession
                }

                catch { 
                    Write-Warning "Error Adding updating readyness period."
                    $_.ErrorDetails.Message
                    break
                }

                #set uri for patching ismodified state
                $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies/$id")
                
                $JSONBody = "{`"isModified`":false}"
                 
                try{ 
                    #patch ismodified state
                    $response = Invoke-RestMethodOverride -Method Patch -Uri $URI -ContentType 'application/json' -Body $JSONBody -WebSession $F5Session.WebSession
                }

                catch { 
                    Write-Warning "Error Adding updating ismodified state."
                    $_.ErrorDetails.Message
                    break
                }

                  #set uri for completed policy
                $uri = $F5Session.BaseURL.Replace('/ltm/',"/asm/policies/$id")               
                 
                try{ 
                    #get completed policy
                    $response = Invoke-RestMethodOverride -Method GET -Uri $URI -ContentType 'application/json' -WebSession $F5Session.WebSession
                    $response
                }

                catch { 
                    Write-Warning "Error Retrieving ASM Policy."
                    $_.ErrorDetails.Message
                    break
                }

           

        }#foreach loop
        
}#proccess loop
}#function close