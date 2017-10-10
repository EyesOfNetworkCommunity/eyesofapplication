[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') 
$EonServ = [Microsoft.VisualBasic.Interaction]::InputBox("IP of the EON server", "NRDP configuration", "")
$EonToken = [Microsoft.VisualBasic.Interaction]::InputBox("NRDP Token", "NRDP configuration", "")

$Path = Get-Location
$ApxPath = "C:\Axians\EOA\"
$Purge = $ApxPath + "purge.ps1"
$Sonde = $ApxPath + "ps\eon4apps.ps1"

New-Item $ApxPath -Type directory
New-Item $ApxPath"\log" -Type directory

Copy-Item -Path $Path"\Dependances\apps" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\bin" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\docs" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\images" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\lib" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\ps" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\sshkey" -Destination $ApxPath -Recurse
Copy-Item -Path $Path"\Dependances\EyesOfApplicationGUI.exe" -Destination $ApxPath

SCHTASKS /Create /SC MINUTE /MO 5 /TN EON4APPS /TR "powershell -WindowStyle Minimized -ExecutionPolicy Bypass -File '$Sonde' www.eyesofnetwork.fr $EonServ $EonToken https://$EonServ/nrdp/ true"
