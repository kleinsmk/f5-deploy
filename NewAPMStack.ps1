Function New-APMStack{
<#
.SYNOPSIS
    Adds a new APM stack
.NOTES
    Requires F5-LTM modules from github
#>
    [cmdletBinding()]
    param(
        
        [Alias("existing acl Name")]
        [Parameter(Mandatory=$true)]
        [string]$name='',

        [Alias("Subnet")]
        [Parameter(Mandatory=$true)]
        [string]$dstSubnet='',

        [ValidateSet ('acl_1_act_full_resource_assign_ag','aggregate_acl_act_full_resource_assign_ag')]
        [Parameter(Mandatory=$false)]
        [string]$reasourcegroup = 'aggregate_acl_act_full_resource_assign_ag'


    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        

    }
    process {
        foreach ($itemname in $Name) {
    

    try{   
        
        Write-Output "Adding New Default ACL to the F5......."
        New-DefaultAcl -name $name -subnet $dstSubnet | Write-Verbose
        Write-Output "Added."

    }

    catch {
        
        Write-Error $_.Exception.Message
        break

    }


    try {
        Write-Output "Adding $name to VPN reasoruce group......"
        Add-APMRole -name $reasourcegroup -acl $name -group $name | Write-Verbose
        Write-Output "Added."
    }

    catch {
        Write-Error $_.Exception.Message
        break
    }

    Write-Output "Updating Policy CSN_VPN_Streamlined......"
    Update-APMPolicy -name "CSN_VPN_Streamlined" | Write-Verbose
    Write-Output "Updated."

    Write-Output "Syncing Device to group......"
    Sync-DeviceToGroup -GroupName "Sync_Group" | Write-Verbose
    Write-Output "Syncd."    
}

}
}



