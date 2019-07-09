$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "../public/$sut"

Context "Function Unit Tests" {
   Describe "New-AsmTaskJson" -Tag Unit {

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