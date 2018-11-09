Function Find-AllVCDProject {
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
        [Parameter(Mandatory=$false)]
        [string[]]$awsID='',
      
        [ValidateSet('Y','N')]
        [Parameter(Mandatory=$false)]
        [string]$AllProjects='N'

    )


if( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break

        }
Write-Warning "This script runs SLOWLY. Use -Verbose if you would like to see real-time output."

if($AllProjects -eq 'Y'){
    $acls = Get-AllAcl
    #filter down acls to all aws acls speed up search
    $acls = $acls.items | Where-Object {$_.name -match '^AWS_[0-9]*$|^MAZ_[a-zA-Z0-9]*-[a-zA-Z0-9]*-[a-zA-Z0-9]*-[a-zA-Z0-9]*-[a-zA-Z0-9]*$'}
}

else {
    $acls = Get-SingleAcl -name $awsID
}



#build to combine lat
$poolandnode = [pscustomobject]@()

Write-Verbose "Getting All Pool memebers"
$pools = Get-Pool
#Get-PoolMember is massively slow
$pools | foreach { $node = Get-PoolMember -InputObject $_; $poolandnode += [PScustomObject]@{ Name = $_.name; ip = $node.address; node = $node.name;} }

#trim /common/ and :port off save only uinques
$ips = $poolandnode | Where-Object {$_.ip -notmatch "System.Object&" -and $_.ip -notmatch "any6" -and $_.ip -ne $null} | select ip -Unique

$results = [pscustomobject]@()


#this is terrible with all these nested loops hacky as I was time constrained.  CPUs are cheap? :(
 foreach ($ip in $ips){

        foreach($acl in $acls){
            #subnets per acl
            $subnets = ( $acl.entries.dstsubnet | select -Unique)

            foreach ($subnet in $subnets ) {
                
                Write-Verbose "Checking $ip against subnet $subnet"
                $checked = IS-InSubnet -ipaddress $($ip.ip) -Cidr $subnet
                if($checked) {
            
                    $results += [pscustomobject]@{aclname = $acl.name; ip = $ip.ip; subnet = $subnet;}
                    Write-Verbose "True: for $($acl.name) $ip $subnet"
                }           
            
            }
        }
 }

$combined = [PSCustomObject]@()

#sort Array
foreach ($item in $results) {

  foreach ($line in $poolandnode) {
    if( $item.ip -eq $line.ip) {
        $combined += [PSCustomObject]@{aclname =$item.aclname; subnet=$item.subnet; node_ip = $item.ip; Pool = $line.Name; node_name = $line.node; }
    }  
  }
}

$combined

}#end function

 
Function IS-InSubnet() 
{ 
 
[CmdletBinding()] 
[OutputType([bool])] 
Param( 
                    [Parameter(Mandatory=$true, 
                     ValueFromPipelineByPropertyName=$true, 
                     Position=0)] 
                    [validatescript({([System.Net.IPAddress]$_).AddressFamily -match 'InterNetwork'})] 
                    [string]$ipaddress="", 
                    [Parameter(Mandatory=$true, 
                     ValueFromPipelineByPropertyName=$true, 
                     Position=1)] 
                    [validatescript({(([system.net.ipaddress]($_ -split '/'|select -first 1)).AddressFamily -match 'InterNetwork') -and (0..32 -contains ([int]($_ -split '/'|select -last 1) )) })] 
                    [string]$Cidr="" 
    ) 
Begin{ 
        [int]$BaseAddress=[System.BitConverter]::ToInt32((([System.Net.IPAddress]::Parse(($cidr -split '/'|select -first 1))).GetAddressBytes()),0) 
        [int]$Address=[System.BitConverter]::ToInt32(([System.Net.IPAddress]::Parse($ipaddress).GetAddressBytes()),0) 
        [int]$mask=[System.Net.IPAddress]::HostToNetworkOrder(-1 -shl (32 - [int]($cidr -split '/' |select -last 1))) 
} 
Process{ 
        if( ($BaseAddress -band $mask) -eq ($Address -band $mask)) 
        { 
 
            $status=$True 
        }else { 
 
        $status=$False 
        } 
} 
end { Write-output $status } 
} 