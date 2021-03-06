﻿<# 
.NAME
    Find-VCD
.SYNOPSIS
    Finds VCD setups that match a given aws ID that exists in the description field of all the pools.
.PARAMETER awsId
    AWs id in format AWS_0898098098    
.EXAMPLE
    Find-VCD -awsId AWS_0898098098
.NOTES 
    Requires F5-LTM modules from github
#>
function Find-VCD
{
[CmdletBinding()]


Param
(
[Parameter()]
    [string]
    $awsId=''
)

process {

    #Check for session and write pretty error if expired.
    if( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break
    }

    $pools = Get-Pool
    $pools = $pools | Where-Object {$_.description -eq $awsId}
    $pools
}

    

}