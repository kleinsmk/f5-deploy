Function Find-VCDProject {
<#
.SYNOPSIS
    Creates a new ASM policy.
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
        [string]$AclName=''

    )


if( $F5Session.WebSession.Headers.'Token-Expiration' -lt (date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break

        }

$nodes = Get-Node

try {$acl = Get-SingleAcl -name $AclName}

catch {  Write-Warning "Unable to Locate ACL."
      $_.ErrorDetails.Message
      break
}

$subnets = $acl.entries.dstSubnet | select -Unique 

#trim /common/ and :port off save only uinques
$ips = $nodes | foreach {$_.address} | select -Unique | Where-Object {$_ -notmatch "any6"}

$nodeList = [pscustomobject]@()

foreach ($ip in $ips){

    foreach ($subnet in $subnets) {
             
        $checked = Check-Subnet -addr1 $ip -addr2 $subnet
        if($checked.condition -eq $true) {$nodeList += $checked}
        #Write-Output "$($result.Condition) for ip: $ip and subnet: $subnet"
    }
}


$nodeList

if ([string]::IsNullOrEmpty($nodelist)){
    Write-Warning "No ip to subnet mactches found"
}

else{
#output pools that each node ip belongs too
$nodeList.ip | ForEach-Object {Get-PoolsForMember -Address $_}
}

}