#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function: Variables et Fonctions pour EON4APPPS                                                                                    *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#********************************************************************INITIALISATIONS***********************************************************

$Path = "C:\eon\APX\EON4APPS\"#Ne pas modifier
$PathApps = $Path + "Apps\"#Ne pas modifier
$CheminFichierImages = $Path + "Images\"#Ne pas modifier
$Status = "OK"#Ne pas modifier-initialisation
$Information = ""#Ne pas modifier
$Chrono=@()#Ne pas modifier
$BorneInferieure = 0#Ne pas modifier
$BorneSuperieure = 0#Ne pas modifier
$PerfData = " | "#Ne pas modifier
$PurgeDelay = 60#Ne pas modifier

#********************************************************************FONCTIONS*****************************************************************

# Fonction qui ajoute les valeurs dans un fichier
Function AddValues($aNiveau, $aMsg)
{
    $aDate = Get-Date
    $aLog = "$aDate ($aNiveau) : $aMsg"
    Write-Host $aLog
	Write-Output $aLog >> $Log
}


# Fonction pour cliquez sur les liens avec la souris
Function Click-MouseButton
{
    param([string]$Button)

    if($Button -eq "double")
    {
        & $Path\EON-Keyboard.exe -c L
		Start-sleep 1
    }
    if($Button -eq "left")
    {
        & $Path\EON-Keyboard.exe -c l
		Start-sleep 1
    }
    if($Button -eq "right")
    {
        & $Path\EON-Keyboard.exe -c r
		Start-sleep 1
    }
    if($Button -eq "middle")
    {
        & $Path\EON-Keyboard.exe -c m
		Start-sleep 1
    }
}

Function Send-SpecialKeys
{
    param([string] $KeysToPress)
    & $Path\EON-Keyboard.exe -S $KeysToPress
    Start-sleep 1
}

Function Send-Keys
{
    param([string] $KeysToPress)
    & $Path\EON-Keyboard.exe -s $KeysToPress
    Start-sleep 1
}

# Fonction pour move the mouse
Function Move-Mouse ($AbsoluteX, $AbsoluteY)
{
    If (($AbsoluteX -ne $null) -and ($AbsoluteY -ne $null)) {
        [system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($AbsoluteX,$AbsoluteY)
   }
    else {
        AddValues "WARN" "Absolute position not received ($AbsoluteX,$AbsoluteY)."
    }
}

# Fonction pour définir les styles de fenêtre
Function Set-WindowStyle 
{
param(
    [Parameter()]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE', 
                 'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED', 
                 'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    $Style = 'SHOW',
    [Parameter()]
    $MainWindowHandle = (Get-Process -Id $pid).MainWindowHandle
)
    $WindowStates = @{
        FORCEMINIMIZE   = 11; HIDE            = 0
        MAXIMIZE        = 3;  MINIMIZE        = 6
        RESTORE         = 9;  SHOW            = 5
        SHOWDEFAULT     = 10; SHOWMAXIMIZED   = 3
        SHOWMINIMIZED   = 2;  SHOWMINNOACTIVE = 7
        SHOWNA          = 8;  SHOWNOACTIVATE  = 4
        SHOWNORMAL      = 1
    }
    Write-Verbose ("Set Window Style {1} on handle {0}" -f $MainWindowHandle, $($WindowStates[$style]))

    $Win32ShowWindowAsync = Add-Type –memberDefinition @” 
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

    $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, $WindowStates[$Style]) | Out-Null
}

function Set-Active
{
    param (
        [int] $ProcessPid
    )
	AddValues "INFO" "PID ---> $ProcessPid"
	Start-Sleep 3 #Avoid slow machine windows scheduler confusing... #IamDreaming....
    $type = Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
"@ -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru
    
   $handle = (Get-Process -id $ProcessPid).MainWindowHandle 
   $OnTop = New-Object -TypeName System.IntPtr -ArgumentList (-1) 
   $type::SetWindowPos($handle, $OnTop, 0, 0, 0, 0, 0x0003)
   $OnBottom = New-Object -TypeName System.IntPtr -ArgumentList (-2) #<--- This stupid workaround is because of this stupid OS
   $type::SetWindowPos($handle, $OnBottom, 0, 0, 0, 0, 0x0003) 
}

function Set-ActiveByHandler
{
    param (
        [int] $WndHandler
    )

    $type = Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
"@ -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru
    
	$OnWndHandler = New-Object -TypeName System.IntPtr -ArgumentList ($WndHandler)
    $OnTop = New-Object -TypeName System.IntPtr -ArgumentList (-1) 
    $type::SetWindowPos($OnWndHandler, $OnTop, 0, 0, 0, 0, 0x0003)
	$OnBottom = New-Object -TypeName System.IntPtr -ArgumentList (-2) #<--- This stupid workaround is because of this stupid OS
    $type::SetWindowPos($OnWndHandler, $OnBottom, 0, 0, 0, 0, 0x0003)
}

function Get-HandlerByTitle
{
    param (
        [string] $WindowTitle
    )
	
	$TypeDef = @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
namespace Api
{
 public class WinStruct
 {
   public string WinTitle {get; set; }
   public int WinHwnd { get; set; }
 }
 public class ApiDef
 {
   private delegate bool CallBackPtr(int hwnd, int lParam);
   private static CallBackPtr callBackPtr = Callback;
   private static List<WinStruct> _WinStructList = new List<WinStruct>();
   [DllImport("User32.dll")]
   [return: MarshalAs(UnmanagedType.Bool)]
   private static extern bool EnumWindows(CallBackPtr lpEnumFunc, IntPtr lParam);
   [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
   static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
   private static bool Callback(int hWnd, int lparam)
   {
	   StringBuilder sb = new StringBuilder(256);
	   int res = GetWindowText((IntPtr)hWnd, sb, 256);
	  _WinStructList.Add(new WinStruct { WinHwnd = hWnd, WinTitle = sb.ToString() });
	   return true;
   }   
   public static List<WinStruct> GetWindows()
   {
	  _WinStructList = new List<WinStruct>();
	  EnumWindows(callBackPtr, IntPtr.Zero);
	  return _WinStructList;
   }
 }
}
"@

	#Add-Type -TypeDefinition $TypeDef -Language CSharpVersion3

	([Api.Apidef]::GetWindows() | Where-Object { $_.WinTitle -like "*"+$WindowTitle+"*" }).WinHwnd
}

# Fonction de purge des processus
Function PurgeProcess($aWindowName) 
{  
    Get-Process -ErrorAction SilentlyContinue $aWindowName | Foreach-Object { $_.CloseMainWindow() } |out-null
    Get-Process -ErrorAction SilentlyContinue $aWindowName | stop-process -Force |out-null
    Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne "" -or $_.ProcessName -eq "powershell"}  | ?{$_.ID -ne $pid} | stop-process -Force |out-null
    (New-Object -comObject Shell.Application).Windows() | foreach-object {$_.quit()} |out-null
    start-sleep 2
}

# Function de recherche image
Function ImageSearch
{

    param (
		[string] $Image,
		[int] $ImageSearchRetries,
		[int] $ImageSearchVerbosity,
		[string] $EonSrv,
		[int] $Wait=250,
		[int] $noerror=0,
		[int] $variance=0
    )

    If (!(Test-Path $Image)){ throw [System.IO.FileNotFoundException] "$Image not found" }
	$ImageFound = 0
    for($i=1;$i -le $ImageSearchRetries;$i++)  {
        $out = & $Path"\GetImageLocation.exe" $Image 0 $variance 
        $State = [int]$out.Split('|')[0]
		
		if ($State -ne 0) {
		# Image trouvée
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
		#Image trouvée, je sors.
		}
        AddValues "WARN" "Image $Image not found in screen (try $i)"
        start-sleep -Milliseconds $Wait
    }
	
	if (($ImageFound -ne 1) -and ($noerror -eq 0))
	{
		$out = & $Path"\GetImageLocation.exe" $Image $ImageSearchVerbosity $variance  
        $State = [int]$out.Split('|')[0]
		$xy=@(0,0)
		if ($State -eq 0) {
			# Image non trouvée
			$ScrShot = $out.Split('|')[1] 
			$BaseFileName = [System.IO.Path]::GetFileNameWithoutExtension($ScrShot)
			$BaseFileNameExt = [System.IO.Path]::GetExtension($ScrShot)
			#
			# Send image to EON server.
			AddValues "ERROR" "Send the file: ${Path}pscp.exe -i ${Path}sshkey\id_dsa -l eon4apps $ScrShot ${EonSrv}:/srv/eyesofnetwork/eon4apps/html/"
			$SendFile = & ${Path}pscp.exe -i ${Path}sshkey\id_dsa -l eon4apps $ScrShot "${EonSrv}:/srv/eyesofnetwork/eon4apps/html/"
			throw [System.IO.FileNotFoundException] "$Image not found in screen: <![CDATA[<a href='/eon4apps/$BaseFileName$BaseFileNameExt' target='_blank'>$ScrShot</a>]]>"
		}
	}
    elseif (($ImageFound -ne 1) -and ($noerror -eq 1))
    {
        $xy=@(-1,-1)
    }
      
    return $xy

}

# Function de click gauche
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

# Function de création des perdata
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
    $i=0
    
    Foreach($svc in $Services){ 
        $ChronoTotal += $Chrono[$i]
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

# Cryptage du password
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
