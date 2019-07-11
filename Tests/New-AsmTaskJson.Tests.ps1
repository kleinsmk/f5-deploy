$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "../public/$sut"

Context "Function Unit Tests" -Tag Unit {
   Describe "New-AsmTaskJson"  {

      #Create a Fake .Replace Method -- Pester Makes this beyond terrible
      $F5Session = New-MockObject -Type System.Object
      $F5Session | Add-Member -MemberType NoteProperty  "BaseURL" -Force -Value { "https://mock"}
      $F5Session.BaseURL | Add-Member -MemberType ScriptMethod "Replace" -Force -Value { "MockString"}
      

$json =
@" 
{"kind": "tm:asm:policies:policystate","virtualServers": ["/Common/test-asm-applytransaction"]}
"@

      It "Returns a string" {
         
         $result = New-AsmTaskJson -method "PATCH" -restEndpoint "/asm/policies/cR2ICBCueib6eZmArrKDrA" -json $json 
         $result | Should -Not -Be $null
      }
         
      It "Returns a Valid JSON string" {

        {$result = New-AsmTaskJson -method "PATCH" -restEndpoint "/asm/policies/cR2ICBCueib6eZmArrKDrA" -json $json
        $result | ConvertTo-Json}  | Should Not Throw

      }

      It "Throws if Method is not GET POST PUT OR PATCH" {

         {$result = New-AsmTaskJson -method "Bogus" -restEndpoint "/asm/policies/cR2ICBCueib6eZmArrKDrA" -json $json
         $result} | Should Throw
         
      } 

   }
}