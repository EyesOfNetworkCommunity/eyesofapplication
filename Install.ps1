[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') 
$EonServ = [Microsoft.VisualBasic.Interaction]::InputBox("IP du serveur EON", "Configuration NRDP", "")
$EonToken = [Microsoft.VisualBasic.Interaction]::InputBox("Token NRDP", "Configuration NRDP", "")

$Path = Get-Location
$ApxPath = "C:\eon\APX\EON4APPS\"
$Purge = $ApxPath + "purge.ps1"
$Sonde = $ApxPath + "eon4apps.ps1"

New-Item "C:\eon\APX" -Type directory
New-Item "C:\eon\APX\EON4APPS" -Type directory
Copy-Item -Path $Path"\Dependances\Apps" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\Docs" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\Images" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\log" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\sshkey" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\GetImageLocation.exe" -Destination $ApxPath
Copy-Item -Path $Path"\Dependances\EON-Keyboard.exe" -Destination $ApxPath
Copy-Item -Path $Path"\Dependances\ImageSearchDLL.dll" -Destination $ApxPath
Copy-Item -Path $Path"\Dependances\eon4apps.ps1" -Destination $ApxPath
Copy-Item -Path $Path"\Dependances\init.ps1" -Destination $ApxPath
Copy-Item -Path $Path"\Dependances\pscp.exe" -Destination $ApxPath
Copy-Item -Path $Path"\Dependances\ps_nrdp.ps1" -Destination $ApxPath
Copy-Item -Path $Path"\SetScreenSetting.exe" -Destination $ApxPath

SCHTASKS /Create /SC MINUTE /MO 5 /TN EON4APPS /TR "powershell -WindowStyle Minimized -ExecutionPolicy Bypass -File '$Sonde' www.eyesofnetwork.fr $EonServ $EonToken"
