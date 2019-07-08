$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "../public/$sut"

$mockJson = @"
{
    "kind": "tm:ltm:node:nodecollectionstate",
    "selfLink": "https://localhost/mgmt/tm/ltm/node?$select=name%2Cfqdn&ver=13.1.0.8",
    "items": [
        {
            "name": "10.22.33.2",
            "fqdn": {
                "addressFamily": "ipv4",
                "autopopulate": "disabled",
                "downInterval": 5,
                "interval": "3600"
            }
        },
        {
            "name": "_auto_10.194.25.106",
            "fqdn": {
                "addressFamily": "ipv4",
                "autopopulate": "enabled",
                "downInterval": 5,
                "interval": "3600",
                "tmName": "internal-public-services2-2126887501.us-gov-west-1.elb.amazonaws.com"
            }
        },
        {
            "name": "www.bix.boozallencsn.com",
            "fqdn": {
                "addressFamily": "ipv4",
                "autopopulate": "enabled",
                "downInterval": 5,
                "interval": "3600",
                "tmName": "bix-public-services-9c88806a0128ac5f.elb.us-gov-west-1.amazonaws.com"
            }
}
"@

Describe "Get-NodebyFQDN" -Tag Unit {

    Mock Invoke-RestMethodOveride {

        $mockJson

    }

    It "Returns a Node Name Given a FQDN" {
        
        Get-NodebyFQDN -fqdn "bix-public-services-9c88806a0128ac5f.elb.us-gov-west-1.amazonaws.com" | 
            Should beexactly "www.bix.boozallencsn.com" 
    }

    It "Retruns nothing is there is not a match" {

        Get-NodebyFQDN -fqdn "bix-public-services-9c88806a0128ac5f.elb.us-gov-west-1.amazonaws.com" | 
        Should be $null
    } 
}
