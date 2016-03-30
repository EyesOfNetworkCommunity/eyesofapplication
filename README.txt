Il est nécessaire de renseigner deux variables durant la copie des fichiers :
	- IP Serveur EyesOfNetwork
	- Token NRDP

Pour executer le script Install.ps1, il est nécessaire de le lancer en Administrateur. Pour se faire :
	- Lancer powershell en Administrateur (Click droit exécuter en tant qu'Administrateur).
	- Se placer dans le dossier contenant Install.ps1 (ex: cd c:\EON4APPS_Windows_Station_Install).
	- Executer le script (Install.ps1).

Le script copiera Tous les fichiers nécessaires au bon fonctionnement de la sonde dans :
	- C:\eon\APX\EON4APPS\
	- Une tâche planifiée exécutant la sonde www.eyesofnetwork.fr.ps1 toutes les 5 minutes sera créee. 