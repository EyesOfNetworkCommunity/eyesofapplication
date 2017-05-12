#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function  : Scénario de test de connexion à la page Téléchargements de www.eyesofnetwork.fr                                        *#
#* Expected results : Etat + Temps de lancement + Action                                                                                     *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

#****************************************************************MODIFICATIONS ICI*************************************************************
#**********************************************************************************************************************************************

# --- Gestion des fenêtres
$WindowName = "iexplore" # Nom de la fenêtre

# --- Client lourd
$ProgExe = "" # Executable
$ProgArg = "" # Arguments de l'exéctuable
$ProgDir = "" # Dossier dans lequel démarrer le programme

# --- Web
$Url = "http://www.eyesofnetwork.fr"

# --- Authentification
$User = ""
$Pass = ""

# --- Host, Service, données de performances et seuils Nagios
$Hostname = "sondes-applicatives" # Definition du Host dans EON pour l'envoi de trap
$Service = "www.eyesofnetwork.fr" # Definition du service dans EON pour l'envoi de trap
$Services = ("Launch","10","15"), 
            ("Download","10","15") # Renseigner ici le nom des différents tests et les seuils

# --- Gestion des recherches d'image
$ImageSearchRetries = "20"  # Nombre d'essais lors de la recherche d'une image
$ImageSearchVerbosity = "2" # Niveau de log de la recherche d'image

#**********************************************************************************************************************************************
#**********************************************************************************************************************************************

# --- Definition des seuils globaux
Foreach($svc in $Services) { 
    $BorneInferieure += $svc[1]  
    $BorneSuperieure += $svc[2]  
}

# --- Chargement de l'application
Function LoadApp($Chrono)
{

    # Lancement de l'application 
    $cmd = Measure-Command {
    
        AddValues "INFO" "Lancement de l'application"
        
        # Client lourd avec arguments
        if($ProgArg) { $app = Start-Process -PassThru -FilePath $ProgExe -ArgumentList $ProgArg -WorkingDirectory $ProgDir }   
        
	    # Client lourd sans arguments
        elseif($ProgExe) { $app = Start-Process -PassThru -FilePath $ProgExe -WorkingDirectory $ProgDir }
	
        # Web
        else {         
            $ie = New-Object -COMObject InternetExplorer.Application
            $ie.visible = $true
            $ie.fullscreen = $true
            $ie.Navigate($Url)
            while ($ie.Busy -eq $true) { start-sleep 1; }
            $app = Get-Process -Name iexplore | Where-Object {$_.MainWindowHandle -eq $ie.HWND}
        }

        # Sélection de la fenêtre
        Set-Active $app.Id
    
#****************************************************************MODIFICATIONS ICI*************************************************************
#**********************************************************************************************************************************************

    }
    $Chrono += [math]::Round($cmd.TotalSeconds,6)
    
     # Accès page téléchargements
    $cmd = Measure-Command {

	    AddValues "INFO" "Accès page téléchargements"
        Start-Sleep 2
        $xy=ImageSearch $Image_download_link $ImageSearchRetries $ImageSearchVerbosity $EonServ
        ImageClick($xy)
        $xy=ImageSearch $Image_download_title $ImageSearchRetries $ImageSearchVerbosity $EonServ
        Start-Sleep 2 
           
    }
    $Chrono += [math]::Round($cmd.TotalSeconds,6)
         
#**********************************************************************************************************************************************
#**********************************************************************************************************************************************

    # Renvoi le tableau de chronos
    return $Chrono

}