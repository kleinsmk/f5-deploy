$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Unit.Tests\.', '.'
Write-Host $sut
. "..\public\$sut"

Describe "New-AwsSecurityStack AWS Deployment Integration Test" {

    Mock Get-JiraTicketInfo {$newEnv}

    Mock Get-NextAclOrder {9000}

    Mock Update-APMPolicy {}

    Mock Sync-DeviceToGroup {}

    Mock Add-JiraIssueComment {}

    Mock Invoke-JiraIssueTransition {}

    Mock Get-JiraIssue {}

    Mock New-JiraSession { }

    Mock New-F5Session {#mock a failed connection too}

    Mock New-DefaultAcl { }

    Mock Remove-Acl {}



    BeforeAll {
        $newEnv = @{"cr" = "CR-1000"; "aws_group" = "AWS_00000000000"; "subnet" = "1.2.3.4/32"}
    }

   Context "Behavior Checks" {

        It "Role Parameter Should be Set Properly" {

            New-AwsSecurityStack -crnumber $newEnv.cr -f5creds $f5 -jiracreds $jira -role dev   
            $role | should be "dev"
        }


        It " Jira Credentials Should be sent and If Jira credentials are not passed prompt and set them" {

        }

        It "Jira session should be created" {

        }

        It "Should scrape info from Jira " {

        }

        It "Should check and Warn if scrape is null" {

        }

        It "Should prompt for F5 creds if none were passed" {

        }

        It "Should throw error if connecting to F5 fails" {

        }

        It "Should add a New-Deafual ACL "{

        }

        It "It should throw if adding New-Default ACL fails" {

        }

        It "Adds an APM role Mapping "{

        }

        It "Throws if Adding Role Fails calls Removes ACL"

        }

        It "Throws if Sync-Device to Group Fails" {

        }
    
    }
}