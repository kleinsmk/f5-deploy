$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "..\public\$sut"

Describe "Get-JiraTicketInfo" {

    $azureData = Get-Content -Raw ./azure_jira_ticket_json.txt | ConvertFrom-Json

    $awsData = Get-Content -Raw ./aws_jira_ticket_json.txt | ConvertFrom-Json

    Context "Scrape Mock Azure Deployment Ticket" {
    
        Mock -CommandName Get-JiraIssue -MockWith { return $azureData } -Verifiable  
        
        $result = Get-JiraTicketInfo -crNumber "CR-5964"       

        It "Returns CR Number" {    
            $result.cr | Should -Be "CR-5964"
        }

        It "Returns Azure ID" {          
            $result.aws_group | Should -Be "MAZ_6f5e00b1-0c5c-4cb4-bf7c-bd8be1b04ea3"
        }

        It "Returns subnet " {                
            $result.subnet | Should -Be "10.185.14.64/26"
        }

        Assert-MockCalled -Times 1 -CommandName Get-JiraIssue
    }

    Context "Scrape Mock AWS Deployment Ticket" {
    
        Mock -CommandName Get-JiraIssue -MockWith { return $awsData } -Verifiable  
        
        $result = Get-JiraTicketInfo -crNumber "CR-5229"       

        It "Returns CR Number" {    
            $result.cr | Should -Be "CR-5229"
        }

        It "Returns AWS ID" {          
            $result.aws_group | Should -Be "AWS_028728282214"
        }

        It "Returns subnet" {
                       
            $result.subnet | Should -Be "10.194.29.192/26"
        }
        
    }

    
}