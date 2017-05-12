#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function  : Chargement eon4apps                                                                                                    *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#********************************************************************INITIALISATIONS***********************************************************

# Paramètres
Param(
	[Parameter(Mandatory=$true)]
	[string]$App,
	[string]$EonServ="",
	[string]$EonToken="",
	[string]$EonUrl="https://${EonServ}/nrdp",
	[bool]$PurgeProcess=$true
)
if(!$EonServ -or !$EonToken) { throw "Please define EonServ and EonToken" }

# Récupération du path
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) 

# Variables et Fonctions
$Init = $ScriptPath + "\init.ps1"
If (!(Test-Path $Init)){ throw [System.IO.FileNotFoundException] "$Init not found" }
. $Init

# Purge
Get-ChildItem -Path $Path\log\ -Filter *.bmp -Force | Where-Object { $_.CreationTime -lt (Get-Date).AddMinutes(-$PurgeDelay) } | Remove-Item -Force -Recurse

# Chargement de l'application
$InitApp = $PathApps + $App + ".ps1"
$PassApp = $PathApps + $App + ".pass"
If (!(Test-Path $InitApp)){ throw [System.IO.FileNotFoundException] "$InitApp not found" }
. $InitApp

#*********************************************************************************************************************************#
#*                                                                                                                               *#
#*                                                          DEBUT DU PROGRAMME                                                   *#
#*                                                                                                                               *#
#*********************************************************************************************************************************#    

# Création du fichier de log
$Log = $PathApps + $App + ".log"
New-Item $Log -Type file -force -value "" |out-null
AddValues "INFO" "Démarrage de la sonde"
[system.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(0,0)

# Création du dossier et des variables images
$CheminDossierImages = $CheminFichierImages + $Service + "\"
New-Item $CheminDossierImages -Type directory -force -value "" |out-null
Get-ChildItem $CheminDossierImages -Filter *.bmp |foreach { $name = $_.BaseName ; New-Variable -Force -Name "Image_${name}" -Value $_.FullName }

# Purge des processus
if($PurgeProcess -eq $true) {
	AddValues "INFO" "Purge des processus"
	PurgeProcess $WindowName
}

# Chargement de l'application
Try {
    $Chrono = LoadApp($Chrono)    
}
Catch {

    # Purge des processus
	if($PurgeProcess -eq $true) {
		AddValues "INFO" "Purge des processus"
		PurgeProcess $WindowName
	}
		
    # Ajouter le service en cours en erreur
    $ErrorMessage = $_.Exception.Message
    AddValues "ERROR" $ErrorMessage
    $Status = "CRITICAL"
    $Information = $Status + " : " + $Service + " " + $ErrorMessage
    AddValues "ERROR" $Information

    # Envoi de la trap
    AddValues "ERROR" "Envoi de la trap en erreur"
 	$Send_Trap = & ${Path}ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${Hostname}" -service "${Service}" -state "${Status}" -output "${Information}"
	AddValues "ERROR" "${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${Hostname}' -service '${Service}' -state '${Status}' -output '${Information}'"
	exit 2

}

# Définition des perfdata
$PerfData = GetPerfdata $Services $Chrono $BorneInferieure $BorneSuperieure

# Dépassement de seuil global ou unitaire
if (($PerfData[0] -gt $BorneSuperieure) -or ($PerfData[3] -ne ""))
{
	$Status = "CRITICAL"
    AddValues "WARN" "Envoi de la trap en dépassement de seuil"
}
elseif (($PerfData[0] -gt $BorneInferieure) -or ($PerfData[2] -ne "")) 
{ 
	$Status = "WARNING"
    AddValues "WARN" "Envoi de la trap en dépassement de seuil"
}
# Exécution normale
else
{
	$Status = "OK"
    AddValues "INFO" "Envoi de la trap en fonctionnement normal"
}

# Purge des processus
if($PurgeProcess -eq $true) {
	AddValues "INFO" "Purge des processus"
	PurgeProcess $WindowName
}
	
# Envoi de la trap
$Information = $Status + " : " + $Service + " " + $PerfData[0] + "s" 
if($PerfData[2] -ne "") { $Information = $Information + " " + $PerfData[2] }
if($PerfData[3] -ne "") { $Information = $Information + " " + $PerfData[3] }
$Information = $Information + $PerfData[1]
AddValues "INFO" $Information
$Send_Trap = & ${Path}ps_nrdp.ps1 -url "${EonUrl}" -token "${EonToken}" -hostname "${Hostname}" -service "${Service}" -state "${Status}" -output "${Information}"
AddValues "INFO" "${Path}ps_nrdp.ps1 -url '${EonUrl}' -token '${EonToken}' -hostname '${Hostname}' -service '${Service}' -state '${Status}' -output '${Information}'"

# Fin de la sonde
AddValues "INFO" "Fin de la sonde"
exit 0

#*********************************************************************************************************************************#
#*                                                                                                                               *#
#*                                                          FIN DU PROGRAMME                                                     *#
#*                                                                                                                               *#
#*********************************************************************************************************************************# 