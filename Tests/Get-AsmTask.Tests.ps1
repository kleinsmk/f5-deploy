$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "../public/$sut"

Context "Function Unit Tests" -Tag "Unit" {
   Describe "Get-AsmTask"  {

    #Create a Fake .Replace Method -- Pester Makes this beyond terrible
    $F5Session = New-MockObject -Type System.Object
    $F5Session | Add-Member -MemberType NoteProperty  "BaseURL" -Force -Value { "https://mock"}
    $F5Session.BaseURL | Add-Member -MemberType ScriptMethod "Replace" -Force -Value { "MockString"}
    
    Mock Invoke-RestMethodOverride {

        "Mock Data"
    }

      #Mundane API call test to check for a return
      It "Returns an Object" {
         
         $result = Get-AsmTask -taskId "123456"
         $result | Should -Not -Be $null
      }       
   }
}

Context "Function Integration Tests" -Tag "Integration"{
    Describe "Connecting to F5 for Testing" {
        #need to have credentials stored for user in f5 cred manager
        It "Connecitng to F5 for testing" {
            {Connect-F5 -ip ec2f5.boozallencsn.com -creds $f5} | Should Not Throw
        }

        It "Creating a task to check on"{

            $json = @"
            {
                "commands": [
                {
                    "uri": "https://aws/mgmt/tm/asm/policies/cR2ICBCueib6eZmArrKDrA",
                    "body": {
                    "kind": "tm:asm:policies:policystate",
                    "virtualServers": [
                        "/Common/integration-testing"
                    ]
                    },
                    "method": "PATCH"
                }
                ]
            }
"@

        $task = Invoke-AsmTask -task $json 
        $task.Status | Should Be "NEW"

        }

        It "Returns ASM Task Status of STARTED" {

            Get-AsmTask -taskId $task.id | Should be "STARTED"
        }
    }

}