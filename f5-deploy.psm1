<#
.SYNOPSIS  
    Load Core Services Helper CMDlets
.DESCRIPTION  
    This module uses the F5 LTM REST API to manipulate and query
.NOTES  
    File Name    : f5-deploy.psm1
    Author       : Sky Klein
    Requires     : 
    Dependencies : Requires F5-LTM module for connections to F5
#>




$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
#region Load Public Functions

    Get-ChildItem "$ScriptPath\Public" -Filter *.ps1 -Recurse| Select-Object -Expand FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        try {
            . $_
        } catch {
            Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
        }
   }

#endregion

