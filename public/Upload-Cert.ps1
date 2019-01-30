Function Upload-Cert {
<#
.SYNOPSIS

 Uploads a cert file to the F5 Load Balancer and installs certificate too.  F5 appends .crt to filename.
 
.PARAMETER filepath
 Location of the cert file locally in full path format like: C:\certificates\test.cert.crt

.EXAMPLE
 Upload-Cert -filepath "C:\certificates\test.domain.com.crt"
 
.OUTPUTS
 
.NOTES
 Requires F5-ltm module from github
 
 Uploaded file MUST have same name as CSR requested domain. ex. test.boozallencsn.com
#>
    [cmdletBinding()]
    param(
        
        
        [Parameter(Mandatory=$true)]
        [string[]]$filepath=""


    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        if( [System.DateTime]($F5Session.WebSession.Headers.'Token-Expiration') -lt (Get-date) ){
            Write-Warning "F5 Session Token is Expired.  Please re-connect to the F5 device."
            break

        }

        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        
        }

    process {


        foreach ($certpath in $filepath) {

        ### Calculate content-range big thanks to matt phelps from: https://devcentral.f5.com/questions/ssl-certificate-upload-with-powershell-using-icontrol-rest-56289       
        $file = [IO.File]::ReadAllBytes($certpath)
        $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
        $encodedfile = $enc.GetString($file)
        $range = "0-" + ($encodedfile.Length - 1) + "/" + $encodedfile.Length
        $headers = @{ "Content-Range" = $range}

        $filename = $certpath | Split-Path -Leaf
        $uri = $F5Session.BaseURL.Replace('/tm/ltm/',"/shared/file-transfer/uploads/$filename")         
        $response = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -InFile $certpath -ContentType "multipart/form-data" -WebSession $F5Session.WebSession | ConvertFrom-Json
        $response

        #install Cert via Api
        $JSONBody = @"
{
  "command":"install","name":"$filename","from-local-file":"$($response.localFilePath)"
}
"@

$JSONBody

        $uri = $F5Session.BaseURL.Replace('/ltm/',"/sys/crypto/cert")
        Invoke-RestMethodOverride -Method Post -URI $uri -Body $JSONBody -ContentType 'application/json' -WebSession $F5Session.WebSession

    }#end for each
        
   }#end process
 }#end function
        


