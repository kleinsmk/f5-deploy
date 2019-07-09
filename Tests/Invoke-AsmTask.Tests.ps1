$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "../public/$sut"

Context "Function Unit Tests" {
   Describe "Invoke-AsmTask" -Tag Unit {

    Mock Invoke-RestMethodOverride {

        "Mock Data"
    }

      #Mundane API call test to check for a return
      It "Returns an Object" {
         
         $result = Invoke-AsmTask -json $json
         $result | Should -Not -Be $null
      }       
   }
}