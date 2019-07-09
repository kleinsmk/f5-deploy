$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "../public/$sut"

Context "Function Unit Tests" {
   Describe "Invoke-AsmTask" -Tag Unit {


      It "Returns an Object" {
         
         $result =
         $result | Should -Not -Be $null
      }
         
  

   }
}