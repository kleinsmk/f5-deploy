

Describe "New-AwsSecurityStack AWS Deployment Integration Test" {

    Mock Get-JiraTicketInfo {$newEnv}

    Mock Get-NextAclOrder {9000}

    Mock Update-APMPolicy {}

    Mock Sync-DeviceToGroup {}

    Mock Add-JiraIssueComment {}

    Mock Invoke-JiraIssueTransition {}

    Mock Get-JiraIssue {}

    BeforeAll {
        $newEnv = @{"cr" = "CR-1000"; "aws_group" = "AWS_181346669898"; "subnet" = "1.2.3.4/32"}
    }

    New-AwsSecurityStack -crnumber $newEnv.cr -f5creds $f5 -jiracreds $jira

    Context "Checking On-Premise" {
    
        Connect-F5 -ip op -creds $f5

        It "Created an On-Premise Acl With Default Entries" {
            $test = Get-SingleAcl -name $newEnv.aws_group
            $test.entries | Should not be $null   
        }

        It "Created an APM Role Mapping On-Premise" {
            $test = Get-APMRole -name acl_1_act_full_resource_assign_ag 
            $test = $test.rules | Where-Object { $_.acls -eq "/Common/$($newEnv.aws_group)" }
            $test | Should not be $null

        }
        
    }

    Context "Checking AWS" {
    
        Connect-F5 -ip aws -creds $f5

        It "Created an On-Premise Acl With Default Entries" {
            $test = Get-SingleAcl -name $newEnv.aws_group
            $test.entries | Should not be $null   
        }

        It "Created an APM Role Mapping On-Premise" {
            $test = Get-APMRole -name acl_1_act_full_resource_assign_ag 
            $test = $test.rules | Where-Object { $_.acls -eq "/Common/$($newEnv.aws_group)" }
            $test | Should not be $null

        }

        AfterAll {

            #clean up created Acls  Needs to ask someone about Pester how to best handle this.
            Connect-F5 -ip aws -creds $f5
            Remove-APMRole -acl $newEnv.aws_group -group $newEnv.aws_group
            Remove-Acl -name $newEnv.aws_group
            Connect-F5 -ip op -creds $f5
            Remove-APMRole -acl $newEnv.aws_group -group $newEnv.aws_group
            Remove-Acl -name $newEnv.aws_group
            
        }
        
    }
    
}