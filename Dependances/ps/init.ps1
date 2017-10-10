#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function: Variables and Fonctions for EON4APPPS                                                                                    *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#********************************************************************INITIALISATIONS***********************************************************

$Path = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
$Path = $Path + "\" #Don't modify
$PathApps = $Path + "apps\"#Don't modify
$CheminFichierImages = $Path + "images\"#Don't modify
$Status = "OK"#Don't modify-initialisation
$Information = ""#Don't modify
$Chrono=@()#Don't modify
$BorneInferieure = 0#Don't modify
$BorneSuperieure = 0#Don't modify
$PerfData = " | "#Don't modify
$PurgeDelay = 60#Don't modify

#********************************************************************FUNCTIONS*****************************************************************

# Function adding the values in a file
Function AddValues($aNiveau, $aMsg)
{
    $aDate = Get-Date
    $aLog = "$aDate ($aNiveau) : $aMsg"
    Write-Host $aLog
	Write-Output $aLog >> $Log
}


# Function to click on the links with the mouse
Function Click-MouseButton
{
    param([string]$Button)

    if($Button -eq "double")
    {
        & $Path\..\bin\EON-Keyboard.exe -c L
		Start-sleep 1
    }
    if($Button -eq "left")
    {
        & $Path\..\bin\EON-Keyboard.exe -c l
		Start-sleep 1
    }
    if($Button -eq "right")
    {
        & $Path\..\bin\EON-Keyboard.exe -c r
		Start-sleep 1
    }
    if($Button -eq "middle")
    {
        & $Path\..\bin\EON-Keyboard.exe -c m
		Start-sleep 1
    }
}

Function Send-SpecialKeys
{
    param([string] $KeysToPress)
    & $Path\..\bin\EON-Keyboard.exe -S $KeysToPress
    Start-sleep 1
}

Function Send-Keys
{
    param([string] $KeysToPress)
    & $Path\..\bin\EON-Keyboard.exe -s $KeysToPress
    Start-sleep 1
}

# Function to move the mouse
Function Move-Mouse ($AbsoluteX, $AbsoluteY)
{
    If (($AbsoluteX -ne $null) -and ($AbsoluteY -ne $null)) {
        [system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($AbsoluteX,$AbsoluteY)
   }
    else {
        AddValues "WARN" "Absolute position not received ($AbsoluteX,$AbsoluteY)."
    }
    Start-sleep 1
}

function Set-Active
{
    param (
        [int] $ProcessPid
    )
	AddValues "INFO" "Set-Active PID ---> $ProcessPid"
	& $Path\..\bin\SetActiveWindows.exe $ProcessPid 0
}

function Set-Active-Maximized
{
    param (
        [int] $ProcessPid
    )
    AddValues "INFO" "Set-Active-Maximized PID ---> $ProcessPid"
    & $Path\..\bin\SetMaximizedWindows.exe $ProcessPid 0
}

# Function to purge processes
Function PurgeProcess
{  
    Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne "" -or $_.ProcessName -eq "powershell"}  | ?{$_.ID -ne $pid} | stop-process -Force |out-null
    (New-Object -comObject Shell.Application).Windows() | foreach-object {$_.quit()} |out-null
    start-sleep 2
}

# Function to search image
Function ImageSearch
{

    param (
		[string] $Image,
		[int] $ImageSearchRetries,
		[int] $ImageSearchVerbosity,
		[string] $EonSrv,
		[int] $Wait=250,
		[int] $noerror=0,
		[int] $variance=0,
		[int] $green=0
    )

    AddValues "INFO" "(ImageSearch) Looking for image: $Image."
    If (!(Test-Path $Image)){ throw [System.IO.FileNotFoundException] "ImageSearch: $Image not found" }
	$ImageFound = 0
    for($i=1;$i -le $ImageSearchRetries;$i++)  {
        $out = & $Path"\..\bin\GetImageLocation.exe" $Image 0 $variance $green
        $State = [int]$out.Split('|')[0]
		
		if ($State -ne 0) {
		# Image found
		AddValues "INFO" "ImageSearch ---> $out"
		$xx1 = [int]$out.Split('|')[1] 
	    $yy1 = [int]$out.Split('|')[2]
		$tx = [int]$out.Split('|')[3]
		$ty = [int]$out.Split('|')[4]
		
		$modulox = $tx % 2
		$moduloy = $ty % 2
		
		if ( $modulox -ne 0) { $tx = $tx - $modulox }
		if ( $moduloy -ne 0) { $ty = $ty - $moduloy }
		
		$OffSetX = $tx / 2
		$OffSetY = $ty / 2
		
		$x1 = $OffSetX + $xx1
		$y1 = $OffSetY + $yy1
		$ImageFound = 1
		$xy=@($x1,$y1)
		break; 
		#Image found, I go out
		}
        AddValues "WARN" "Image $Image not found in screen (try $i)"
        start-sleep -Milliseconds $Wait
    }
	
	if (($ImageFound -ne 1) -and ($noerror -eq 0))
	{
		$out = & $Path"\..\bin\GetImageLocation.exe" $Image $ImageSearchVerbosity $variance $green
        $State = [int]$out.Split('|')[0]
		$xy=@(0,0)
		if ($State -eq 0) {
			# Image not found
			$ScrShot = $out.Split('|')[1] 
			$BaseFileName = [System.IO.Path]::GetFileNameWithoutExtension($ScrShot)
			$BaseFileNameExt = [System.IO.Path]::GetExtension($ScrShot)
			#
			# Send image to EON server
            $PathKey = $Path -replace "\\ps\\", "\sshkey"
			AddValues "ERROR" "Send the file: ${Path}\..\bin\pscp.exe -i ${Path}..\sshkey\id_dsa -l eon4apps $ScrShot ${EonSrv}:/srv/eyesofnetwork/eon4apps/html/"
			$SendFile = & ${Path}\..\bin\pscp.exe -i ${PathKey}\id_dsa -l eon4apps $ScrShot "${EonSrv}:/srv/eyesofnetwork/eon4apps/html/"
            $out = & ${Path}\..\bin\SetScreenSetting.exe 0 0 0 #Restore good known screen configuration
			$ConcatUrlSend = $Image + ' not found in screen: <a href="/eon4apps/' + $BaseFileName + $BaseFileNameExt + '" target="_blank">' + $ScrShot + '</a>'
			throw [System.IO.FileNotFoundException] "$ConcatUrlSend"
		}
	}
    elseif (($ImageFound -ne 1) -and ($noerror -eq 1))
    {
        $xy=@(-1,-1)
    }
      
    return $xy

}

# Function of image search in low precision (drift to the green)
Function ImageSearchLowPrecision
{

    param (
		[string] $Image,
		[int] $ImageSearchRetries,
		[int] $ImageSearchVerbosity,
		[string] $EonSrv,
		[int] $Wait=250,
		[int] $noerror=0,
		[int] $variance=0,
		[int] $green=1
    )
	
	$xy=ImageSearch $Image $ImageSearchRetries $ImageSearchVerbosity $EonSrv $Wait $noerror $variance $green

    return $xy 

}

# Function left click
Function ImageClick($xy,$xoffset,$yoffset,$type="left")
{
	$x = [int]$xy[0]
	$y = [int]$xy[1]
	AddValues "INFO" "Imageclick position ---> x:$x,y:$y"
	
	If ($xoffset -ne $null) {
		$x = [int]$xy[0] + $xoffset
		$y = [int]$xy[1]
		$xy=@($x,$y)
	}
	If ($yoffset -ne $null) {
		$x = [int]$xy[0]
		$y = [int]$xy[1] + $yoffset
		$xy=@($x,$y)
	}
	AddValues "INFO" "Imageclick offseted position ---> x:$x,y:$y"
	
	$SetX = [int]$xy[0]
	$SetY = [int]$xy[1]
    [system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($SetX,$SetY)
    Click-MouseButton $type

}

# Function of perdata creation
Function GetPerfdata
{

    param (
        [array] $Services,
        [array] $Chrono,
        [int] $BorneInferieure,
        [int] $BorneSuperieure 
    )

    $ServicesW=""
    $ServicesC=""
    $ChronoTotal=0
    $PerfDataTemp=""
    $i=1
    
    Foreach($svc in $Services){ 

        $svc0 = $svc[0]
        $svc1 = $svc[1]
        $svc2 = $svc[2]
        $Current_ChronoTotal=$Chrono[$i]
        AddValues "INFO" "Counter=$svc0 ; Warning=$svc1; Critical=$svc2, Current value: $Current_ChronoTotal seconds"

        $ChronoTotal += $Current_ChronoTotal
        $PerfDataTemp = $PerfDataTemp + " " + $svc[0] + "=" + $Chrono[$i]+"s"
        $ServicesWtmp = "\nWARNING : " +$svc[0]+" "+$Chrono[$i]+"s" 
        $ServicesCtmp = "\nCRITICAL : " +$svc[0]+" "+$Chrono[$i]+"s" 

        if($svc[1] -ne "") { 
            $PerfDataTemp += ";"+$svc[1]
            if($Chrono[$i] -gt $svc[1]) { $ServicesW=$ServicesW+$ServicesWtmp }
        }
        if($svc[2] -ne "") { 
            $PerfDataTemp += ";"+$svc[2] 
            if($Chrono[$i] -gt $svc[2]) { 
                $ServicesC=$ServicesC+$ServicesCtmp
                $ServicesW = $ServicesW.Replace($ServicesWtmp,"")
            }
        }
        $i++
    }

    $PerfData = $PerfData + "Total" + "=" + $ChronoTotal + "s;" + $BorneInferieure + ";" + $BorneSuperieure 
    $PerfData = $PerfData + $PerfDataTemp

    return @($ChronoTotal,$PerfData,$ServicesW,$ServicesC)

}

# Password encryption
Function GetCryptedPass 
{

    param (
        [Parameter(Mandatory=$false)][string]$Password
    )

    if($Password) {
        $Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File $PassApp
    }
    
    $SecurePassword = Get-Content $PassApp | ConvertTo-SecureString
    $Marshal = [System.Runtime.InteropServices.Marshal]
    $Bstr = $Marshal::SecureStringToBSTR($SecurePassword)
    $Password = $Marshal::PtrToStringAuto($Bstr)
    $Marshal::ZeroFreeBSTR($Bstr)

    return $Password
}

# Function of image search
Function SetScreenResolution
{

    param (
        [int] $ResolutionX,
        [int] $ResolutionY,
        [int] $debug=2
    )

    AddValues "INFO" "Path value in SetScreen: $Path"
    $out = & $Path"\..\bin\SetScreenSetting.exe" $ResolutionX $ResolutionY $debug

    $State = [int]$out.Split('|')[0]
    
    if ($State -ne 0) {
        throw [System.IO.FileNotFoundException] "The resolution $ResolutionX x $ResolutionY cannot be set on this workstation."
    }
}

# Function to check if Image is foundable whitout exit.
# Return 0 if image exist. 1 if image is not foundable.
Function ImageNotExist
{
    param (
    [Parameter(Mandatory=$true)][string]$ImageToFind,
    [Parameter(Mandatory=$true)][string]$Retries,
    [bool]$returncode=$false
    )

    $xy=ImageSearch $ImageToFind $Retries 2 $EonServ 250 1 30
    AddValues "INFO" "(ImageNotExist) out of image Search."
    $x = [int]$xy[0]
    $y = [int]$xy[1]
    if (($x -eq -1) -and ($y -eq -1))
    {
        $returncode=$true
        AddValues "INFO" "(ImageNotExist)Image $ImageToFind not found."
    } 
    AddValues "INFO" "(ImageNotExist) Image $ImageToFind was found."
    return $xy
}

function Minimize-All-Windows
{
    AddValues "INFO" "Minimize all windows."
    & $Path\..\bin\MinimizeAllWindows.exe
}