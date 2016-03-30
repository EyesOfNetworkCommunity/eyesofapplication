param (
    [string]$url = "",
    [string]$token = "",
    [string]$hostname = "",
    [string]$service = "",
    [string]$state = "",
    [string]$output = "",
    [char]$delim = "`t",
    [int]$checktype = "",
    [string]$file = "",
    [switch]$readterm = $false,
    [switch]$help = $false
)

Set-StrictMode -Version 2.0

function proc_input([string]$strHostname, [string]$strService, [string]$strState, [string]$strOutput, [int]$bCheckType) {
    $xmlBuilder = "<?xml version='1.0'?>`n<checkresults>`n"
    if (!$strService) {
        $xmlBuilder += generate_host_check $strHostname $strState $strOutput $bCheckType
    } else {
        $xmlBuilder += generate_service_check $strHostname $strService $strState $strOutput $bCheckType
    }
    $xmlBuilder += "</checkresults>"
    return $xmlBuilder
}

function proc_file ([string]$strFile, [char]$chrDelim) {
    if (Test-Path $strFile) {
        $strExt = [System.IO.Path]::GetExtension($strFile)
        $strFileContents = Get-Content $strFile
        if ($strExt -ne ".xml") {
            $xmlBuilder = "<?xml version='1.0'?>`n<checkresults>`n"
            foreach ($strLine in $strFileContents) {
                $strLine = $strLine.Trim()
                $aryInput = $strLine.Split("$chrDelim")
                if ($aryInput.Count -eq 4) {
                    $strHostname, $strState, $strOutput, $bCheckType = $aryInput
                    $xmlBuilder += generate_host_check $strHostname $strState $strOutput $bCheckType
                } elseif ($aryInput.Count -eq 5) {
                    $strHostname, $strService, $strState, $strOutput, $bCheckType = $aryInput
                    $xmlBuilder += generate_service_check $strHostname $strService $strState $strOutput $bCheckType
                } else {
                    Write-Host "Unable to parse line number: , skipping."
                }
            }
            $xmlBuilder += "</checkresults>"
        } else {
            $xmlBuilder = $strFileContents
        }
        return $xmlBuilder
    } else {
        Write-Host "Unable to find the specified file."
        exit
    }
}

function proc_terminal ([char]$chrDelim, [int]$bCheckType) {
    $strRead = Read-Host "Enter check details:`n"
    $strRead = $strRead.Trim()
    $aryInput = $strRead.Split("$chrDelim")
    $xmlBuilder = "<?xml version='1.0'?>`n<checkresults>`n"
    if ($aryInput.Count -eq 3) {
        $strHostname, $strState, $strOutput = $aryInput
        $xmlBuilder += generate_host_check $strHostname $strState $strOutput $bCheckType
    } elseif ($aryInput.Count -eq 4) {
        $strHostname, $strService, $strState, $strOutput = $aryInput
        $xmlBuilder += generate_service_check $strHostname $strService $strState $strOutput $bCheckType
    } else {
        Write-Host "Input is incorrectly formatted, can't parse fields"
        help
    }
    $xmlBuilder += "</checkresults>"
    return $xmlBuilder
}

function generate_service_check ([string]$strHostname, [string]$strService, [string]$strState, [string]$strOutput, [int]$bCheckType) {
    $intState = validate_state $strState
    $xmlBuilder = @"
<checkresult type='service' checktype='$bCheckType'>
<hostname>$strHostname</hostname>
<servicename>$strService</servicename>
<state>$intState</state>
<output>$strOutput</output>
</checkresult>
"@
    return $xmlBuilder
}

function generate_host_check ([string]$strHostname, [string]$strState, [string]$strOutput, [int]$bCheckType) {
    $intState = validate_state $strState
    $xmlBuilder = @"
<checkresult type='service' checktype='$bCheckType'>
<hostname>$strHostname</hostname>
<state>$intState</state>
<output>$strOutput</output>
</checkresult>
"@
    return $xmlBuilder
}

function validate_state ([string]$strState) {
    $hshStates = @{'OK' = 0; 'WARNING' = 1; 'CRITICAL' = 2; 'UNKNOWN' = 3}
    $strState = $strState.ToUpper()
    if ($hshStates.ContainsKey($strState)) {
        return $hshStates.$strState
    } else {
        Write-Host "Invalid state provided: $strState"
        help
    }
}

function post_data ([string]$strURL, [string]$strToken, [string]$xmlPost) {
   $webAgent = New-Object System.Net.WebClient
   $nvcWebData = New-Object System.Collections.Specialized.NameValueCollection
   $nvcWebData.Add('token', $strToken)
   $nvcWebData.Add('cmd', 'submitcheck')
   $nvcWebData.Add('XMLDATA', $xmlPost)
   $strWebResponse = $webAgent.UploadValues($strURL, 'POST', $nvcWebData)
   $strReturn = [System.Text.Encoding]::ASCII.GetString($strWebResponse)
   if ($strReturn.Contains("<message>OK</message>")) {
        $strMessage = "SUCCESS - checks succesfully sent, NRDP returned: " + $strReturn + ")"
        Write-Host $strMessage
   } else {
        $strMessage = "ERROR - checks failed to send, NRDP returned: " + $strReturn + ")"
        Write-Host $strMessage
   }
    exit
}

function help {
    $strVersion = "v1.2 b060314"
    $strNRDPVersion = "1.2"
    Write-Host "`nPowershell NRDP sender version: $strVersion for NRDP version: $strNRDPVersion"
    Write-Host "By John Murphy <john.murphy@roshamboot.org>, GNU GPL License"
    Write-Host "`nUsage: ./ps_nrdp.ps1 -url <Nagios NRDP URL> -token <Token> [-hostname <Hostname> -state <State> -output <Information|Perfdata> [-service <service name> -checktype <0/1>] | -file <File path> [-delim <Field delimiter>] | -readterm [-delim <Field delimiter> ]]`n`n"
    Write-Host @'
-url
	The URL used to access the remote NRDP agent. i.e. http://nagiosip/nrdp/
-token
	The authentication token used to access the remote NRDP agent.
-hostname
	The name of the host associated with the passive host/service check result. 
	This script will attempt to learn the hostname if not supplied.
-service
	For service checks, the name of the service associated with the passive check result.
-state
	The state of the host or service. Valid values are: OK, CRITICAL, WARNING, UNKNOWN
-output
	Text output to be sent as the passive check result.
-delim
	Used to set the text field delimiter when using non-XML file input or command-line input. 
	Defaults to tab (\\t).
-checktype
	Used to specify active or passive, 0 = active, 1 = passive. Defaults to passive.
-file
	Use this switch to specify the full path to a file to read. There are two usable formats:
	1. A field-delimited text file, where the delimiter is specified by -d
	2. An XML file in NRDP input format. An example can be found by browsing to the NRDP API URL. 
-readterm
	This switch specifies that you wish to input the check via standard input on the command line.
-help
	Display this help text.
	
'@
    exit
}

if ($help -eq $true) {
    help
}

if (!$url -or !$token) {
    Write-Host "You must set a URL and Token."
    help
}

if ($delim.equals("`n") -or $delim.equals("`r")) {
    Write-Host "Can't use new line character as a field seperator."
    help
}

if (!("/" -eq $url.Substring($url.Length - 1, 1))) {
    $url = $url + "/"
}

if (!$checktype) {
    $checktype = 1
}

if (!$hostname) {
    if ($env:computername) {
        $hostname = $env:computername
    } else { 
        Write-Host "Unable to determine hostname! Please specify one manually with -hostname"
        exit
    }
}

if ($file) {
    $xmlPost = proc_file $file $delim
} elseif ($readterm) {
    $xmlPost = proc_terminal $delim $checktype
} elseif ($hostname -and $state -and $output) {
    $xmlPost = proc_input $hostname $service $state $output $checktype
} else {
    Write-Host "Incorrect options set."
    help
}

if ($xmlPost) {
    post_data $url $token $xmlPost
} else {
    Write-Host "Something has gone horribly wrong! XML build failed, bailing out..."
}
exit