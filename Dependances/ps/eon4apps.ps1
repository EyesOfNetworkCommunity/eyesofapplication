#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function  : Running Apps                                                                                                           *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#********************************************************************INITIALIZATION***********************************************************

# Parameters
Param(
	[Parameter(Mandatory=$true)]
	[string]$App,
	[string]$EonServ="",
	[string]$EonToken="",
	[string]$EonUrl="https://${EonServ}/nrdp",
	[string]$PurgeProcess="True"
)
if(!$EonServ -or !$EonToken) { throw "Please define EonServ and EonToken" }
$App_Backup = $App # Workaround bug of Start-Process made by Microsoft


# Path grabbing
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)

# Functions and variables
$Init = $ScriptPath + "\init.ps1"
If (!(Test-Path $Init)){ throw [System.IO.FileNotFoundException] "$Init not found" }
. $Init

# Log file creation
 $out = & $ScriptPath"\..\bin\GetRunner.exe" 0
        $State = [int]$out.Split('|')[0]
        
        if ($State -ne 0) {
                $domain = $out.Split('|')[1]
                $username = $out.Split('|')[2]
                $computer = $out.Split('|')[3] 

                $LogPath = $ScriptPath + "\..\log\" + $domain + "\" + $username + "\" + $computer
                
                If(!(test-path $LogPath)) {
                    New-Item -ItemType Directory -Force -Path $LogPath
                }

                $Log = $LogPath + "\" + $App + ".log" # Continue to use Log variable in rest of scripts.

        } else {
            throw [System.IO.FileNotFoundException] "GetRunner could not determine environnement." 
        }

New-Item $Log -Type file -force -value "" |out-null

# From this point logging is available.
AddValues "INFO" "Loading Init.ps1 OK"
AddValues "INFO" "Current call is: $App $EonServ $EonToken $EonUrl $PurgeProcess."
# Purge
Get-ChildItem -Path $ScriptPath\..\log\ -Filter *.bmp -Force | Where-Object { $_.CreationTime -lt (Get-Date).AddMinutes(-$PurgeDelay) } | Remove-Item -Force -Recurse

# Application loading
$TempPathAppsLnk = $PathApps + "User\\" + $App + ".ps1"
$TempPathAppsLnk = $TempPathAppsLnk -replace "user_", "" -replace "\\ps\\", "\\" 

AddValues "INFO" "LNK: $TempPathAppsLnk"
if ( (Test-Path $TempPathAppsLnk) ) { 
    AddValues "INFO" "GUI link detected"
    $InitApp = $PathApps + $App + ".ps1"
    $InitApp = $InitApp -replace "user_", "" -replace "\\ps\\", "\\" 
} else {
        AddValues "INFO" "Direct call"
    $InitApp = $PathApps + $App + ".ps1" -replace "\\ps\\", "\\" 
}

$PassApp = $PathApps + $App + ".pass"
if ( ! (Test-Path $InitApp) )
    { 
        AddValues "INFO" "$InitApp not found"
        throw [System.IO.FileNotFoundException] "InitApp not found"
    }
. $InitApp
AddValues "INFO" "Loading InitApp OK... ($InitApp)"

# Determine if User (GUI) or Sched
$FromGUI = $false
if ( ($App -match [regex]'^user_')) {
    AddValues "INFO" "Running from GUI detected."
    $FromGUI = $true
}
AddValues "INFO" "Running scenario: $InitApp"

#*********************************************************************************************************************************#
#*                                                                                                                               *#
#*                                                          BEGIN                                                                *#
#*                                                                                                                               *#
#*********************************************************************************************************************************#    

AddValues "INFO" "Starting prober"

[system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(0,0)

# Create folder and image variable.
$RealApp = $App -replace "user_", ""
$RootPath = $PathApps -replace "\\ps\\", "" -replace "Apps\\", ""

$ImagePathFolder = $RootPath + "\Images\" + $RealApp + "\"
AddValues "INFO" "ImagePathFolder set to $ImagePathFolder."
New-Item $ImagePathFolder -Type directory -force -value "" |out-null
Get-ChildItem $ImagePathFolder -Filter *.bmp |foreach { $name = $_.BaseName ; New-Variable -Force -Name "Image_${name}" -Value $_.FullName }

#Purge of processs
if($PurgeProcess -eq "True") {
	AddValues "INFO" "Purge of process"
	PurgeProcess
}

# --- Global threshold definition
Foreach($svc in $Services) { 
    $Current_Service = $svc[0]
    $Current_BorneInferieur = $svc[1]
    $Current_BorneSuperieur = $svc[2]
    $BorneInferieure += $Current_BorneInferieur  #Adding to array
    $BorneSuperieure +=  $Current_BorneSuperieur
    AddValues "INFO" "Adding counter ($Current_Service) Warning:$Current_BorneInferieur, Critical:$Current_BorneSuperieur"
}
AddValues "INFO" "Screen resolution adjustment to ${ExpectedResolutionX}x${ExpectedResolutionY}"
SetScreenResolution $ExpectedResolutionX $ExpectedResolutionY

# Do not remove. This cd is used to relative path access...
$ExceScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
AddValues "INFO" "Execution Path is: $ExceScriptPath"
cd $ExceScriptPath

# # --- Start application and initialize launch chrono.
$cmd = Measure-Command {

    AddValues "INFO" "Start of application"
    
    # Client/Server apps with arguments
    if($ProgArg) {  
        $app = Start-Process -PassThru -FilePath "$ProgExe" -ArgumentList "$ProgArg" -WorkingDirectory "$ProgDir"            
        AddValues "INFO" "Run with Args: $ProgExe $ProgArg"
    }   
    # Client/Server apps WITHOUT arguments
    elseif($ProgExe) { 
        $app = Start-Process -PassThru -FilePath "$ProgExe" -WorkingDirectory "$ProgDir"        
        AddValues "INFO" "Run: $ProgExe"
    }
    # Web
    else { 
        $ie = New-Object -COMObject InternetExplorer.Application
        $ie.visible = $true
        $ie.fullscreen = $true
        $ie.Navigate($Url)
        while ($ie.Busy -eq $true) { start-sleep 1; }
        $app = Get-Process -Name iexplore | Where-Object {$_.MainWindowHandle -eq $ie.HWND}
        AddValues "INFO" "Running in web mode..."
    }

    # Set application windows on top. 
    start-sleep -s 5 #Waiting for fù(£1n9 windows process handler...
    $Command_Line_Str="%$ProgExe $ProgArg%" -replace ' ', "%" -replace '\\', '\\'
    AddValues "INFO" "Selectable CommandLine (${Command_Line_Str})"
    $MyTablePID = foreach ($i in "${Command_Line_Str}") {Get-WmiObject Win32_Process -Filter "CommandLine like '$i'" | Select ProcessId}
    $MyPID = $MyTablePID.ProcessId  
    AddValues "INFO" "Ask for PID ---> $MyPID"
    Set-Active-Maximized $MyPID
}
$Current_Chrono += [math]::Round($cmd.TotalSeconds,6)
$Chrono += $Current_Chrono
$Recorded_Chrono = $Chrono[0]
AddValues "INFO" "Application launch had been performed in $Current_Chrono seconds (Recorded_Chrono[0]: $Recorded_Chrono)"

AddValues "INFO" "EOA Scenario: $App"
# Load application
Try {
    $Chrono += RunScenario($Chrono)   
}
Catch {

    # Add current service in error
    $ErrorMessage = $_.Exception.Message
    AddValues "ERROR" $ErrorMessage
    $Status = "CRITICAL"
    $Information = $Status + " : " + $Service + " " + $ErrorMessage
    AddValues "ERROR" $Information

    # Send information via NRDP
    AddValues "ERROR" "Send information of error to monitoring system."
    if ( $FromGUI -eq $false ) {
 	  $Send_Trap = & powershell -ExecutionPolicy ByPass -File ${Path}\ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${Hostname}" -service "${Service}" -state "${Status}" -output "${Information}"
	   AddValues "ERROR" "powershell -ExecutionPolicy ByPass -File ${Path}\ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${Hostname}' -service '${Service}' -state '${Status}' -output '${Information}'"
	}
    if ( $FromGUI -eq $true ) {
       $Send_Trap = & powershell -ExecutionPolicy ByPass -File ${Path}\ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${GUI_Equipement_InEON}" -service "${App_Backup}" -state "${Status}" -output "${username} on ${Hostname} -> ${Information}"
       AddValues "ERROR" "powershell -ExecutionPolicy ByPass -File ${Path}\ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${GUI_Equipement_InEON}' -service '${App_Backup}' -state '${Status}' -output '${username} on ${Hostname} -> ${Information}'"
    }
    AddValues "INFO" "Restore screen resolution"
    $out = & ${Path}\..\bin\SetScreenSetting.exe 0 0 0 #Restore good known screen configuration
    exit 2

}

# Preformance data definition
$PerfData = GetPerfdata $Services $Chrono $BorneInferieure $BorneSuperieure

# Breaking threshold globaly or unitary
if (($PerfData[0] -gt $BorneSuperieure) -or ($PerfData[3] -ne ""))
{
	$Status = "CRITICAL"
    AddValues "WARN" "Sending information of over threhold meseaurement (CRITICAL)."
}
elseif (($PerfData[0] -gt $BorneInferieure) -or ($PerfData[2] -ne "")) 
{ 
	$Status = "WARNING"
    AddValues "WARN" "Sending information of over threhold meseaurement (WARNING)."
}
# Basic execution
else
{
	$Status = "OK"
    AddValues "INFO" "Sending information of usual behavior (OK)."
}
	
# Sending information via NRDP
$Information = $Status + " : " + $Service + " " + $PerfData[0] + "s" 
if($PerfData[2] -ne "") { $Information = $Information + " " + $PerfData[2] }
if($PerfData[3] -ne "") { $Information = $Information + " " + $PerfData[3] }
$Information = $Information + $PerfData[1]
AddValues "INFO" $Information
if ( $FromGUI -eq $false ) {
    $Send_Trap = &  powershell -ExecutionPolicy ByPass -File  ${Path}\ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${Hostname}" -service "${Service}" -state "${Status}" -output "${Information}"
    AddValues "INFO" "powershell -ExecutionPolicy ByPass -File ${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${Hostname}' -service '${Service}' -state '${Status}' -output '${Information}'"
}
if ( $FromGUI -eq $true ) {
    $Send_Trap = & powershell -ExecutionPolicy ByPass -File ${Path}\ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${GUI_Equipement_InEON}" -service "${App_Backup}" -state "${Status}" -output "${username} on ${computer} -> ${Information}"
    AddValues "INFO" "powershell -ExecutionPolicy ByPass -File ${Path}\ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${GUI_Equipement_InEON}' -service '${App_Backup}' -state '${Status}' -output '${username} on ${computer} -> ${Information}'"
}

AddValues "INFO" "Restore screen resolution"
$out = & ${Path}\..\bin\SetScreenSetting.exe 0 0 0 #Restore good known screen configuration

# # Purge of process
if($PurgeProcess -eq "True") {
    AddValues "INFO" "Purge of process"
    PurgeProcess
}

# End of probe
AddValues "INFO" "End of probing."

exit 0