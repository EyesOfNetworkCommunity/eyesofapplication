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
	[string]$SIP="0",
	[string]$Community=""
)
if(!$EonServ -or !$SIP -or !$Community) { throw "Please define EonServ, SIP and Community parameters" }

# Récupération du path
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) 

# Variables et Fonctions
$Init = $ScriptPath + "\init.ps1"
If (!(Test-Path $Init)){ throw [System.IO.FileNotFoundException] "$Init not found" }
. $Init

# Chargement de l'application
$InitApp = $PathApps + $App + ".ps1"
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
AddValues "INFO" "Purge des processus"
PurgeProcess $WindowName

# Chargement de l'application
Try {
    $Chrono = LoadApp($Chrono)    
}
Catch {

    # Purge des processus
    AddValues "INFO" "Purge des processus"
    PurgeProcess $WindowName

    # Ajouter le service en cours en erreur
    $ErrorMessage = $_.Exception.Message
    AddValues "ERROR" $ErrorMessage
    $Status = 2
    $Information = $Etat[$Status] + " : " + $Service + " " + $ErrorMessage
    AddValues "ERROR" $Information

    # Envoi de la trap
    AddValues "ERROR" "Envoi de la trap en erreur"
    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
	$Information = [System.Web.HttpUtility]::UrlEncode($Information) 
    $Send_Trap = & ${Path}"TrapGen.exe" "-d" $EonServ "-c" $Community "-o" $SOID "-i" $SIP "-v" $OID "STRING" $Hostname "-v" $OID "STRING" $Service "-v" $OID "INTEGER" $Status "-v" $OID "STRING" "$Information"
    AddValues "ERROR" "${Path}TrapGen.exe -d $EonServ -c $Community -o $SOID -i $SIP -v $OID STRING $Hostname -v $OID STRING $Service -v $OID INTEGER $Status -v $OID STRING $Information -p a"

	exit 2

}

# Définition des perfdata
$PerfData = GetPerfdata $Services $Chrono $BorneInferieure $BorneSuperieure

# Dépassement de seuil global ou unitaire
if (($PerfData[0] -gt $BorneSuperieure) -or ($PerfData[3] -ne ""))
{
	$Status = 2
    AddValues "WARN" "Envoi de la trap en dépassement de seuil"
}
elseif (($PerfData[0] -gt $BorneInferieure) -or ($PerfData[2] -ne "")) 
{ 
	$Status = 1
    AddValues "WARN" "Envoi de la trap en dépassement de seuil"
}
# Exécution normale
else
{
	$Status = 0
    AddValues "INFO" "Envoi de la trap en fonctionnement normal"
}

# Purge des processus
AddValues "INFO" "Purge des processus"
PurgeProcess $WindowName

# Envoi de la trap
$Information = $Etat[$Status] + " : " + $Service + " " + $PerfData[0] + "s" 
if($PerfData[2] -ne "") { $Information = $Information + " " + $PerfData[2] }
if($PerfData[3] -ne "") { $Information = $Information + " " + $PerfData[3] }
$Information = $Information + $PerfData[1]
AddValues "INFO" $Information
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
$Information = [System.Web.HttpUtility]::UrlEncode($Information) 
$Send_Trap = & ${Path}"TrapGen.exe" "-d" $EonServ "-c" $Community "-o" $SOID "-i" $SIP "-v" $OID "STRING" $Hostname "-v" $OID "STRING" $Service "-v" $OID "INTEGER" $Status "-v" $OID "STRING" "$Information"
AddValues "INFO" "${Path}TrapGen.exe -d $EonServ -c $Community -o $SOID -i $SIP -v $OID STRING $Hostname -v $OID STRING $Service -v $OID INTEGER $Status -v $OID STRING $Information -p a"

# Fin de la sonde
AddValues "INFO" "Fin de la sonde"
exit 0

#*********************************************************************************************************************************#
#*                                                                                                                               *#
#*                                                          FIN DU PROGRAMME                                                     *#
#*                                                                                                                               *#
#*********************************************************************************************************************************# 