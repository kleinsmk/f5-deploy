Function Get-NextFreeDestinationIP {
<#
.SYNOPSIS
Returns next free IP on the F5 for virtual server use
.DESCRIPTION
Returns next free IP on the F5 for virtual server use
.Example
Get-NextFreeDestinationIP

#>


    process {
       

        $uri = $F5Session.BaseURL.Replace('/ltm/','/ltm/virtual?$select=destination')
        $obj = Invoke-RestMethodOverride -Method GET -URI $uri -WebSession $F5Session.WebSession

        #capture only ips
        $ips = $obj.items
        #trim ips from port
        $ips = $ips.destination | foreach {$_.substring(0, $_.indexof(':'))}
        #trim /Common
        $ips = $ips.Trim('/Common/')
        #sort ips 
        $ips = $ips | Sort-Object { [version]$_ }
        #filter ips to sub 5.5.5.5 range
        $ips = $ips | Where-Object { ([version]$_).major -lt '5' }

        $last = $ips[-1]
        $version = [version]$last
        $last_octet =  $version.revision + 1

       if ($last_octet -lt 256) {

            $last = $version.Major.tostring() + "." + $version.Minor.tostring() + "." + $version.Build.tostring() + "." + $last_octet
            $last
        }

        else{

            $last = $version.Major.tostring() + "." + $version.Minor.tostring() + "." + ($version.Build + 1) + "." + "1"
            $last
        }
    
            
    }
        
}

