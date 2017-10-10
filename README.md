<h2>Documentation – Installation et utilisation de Eyes of Application – Windows</h2>

<p>
Dans cette documentation, nous verrons comment installer EOA ainsi que son utilisation sur Windows.
</p>

<h1>Partie 1 – Installation</h1>

<p>
Récupérez EOA sur GitHub via le lien suivant : https://github.com/EyesOfNetworkCommunity/eyesofapplication/
Extrayez le dossier téléchargé. Pour lancer l’installation il vous faudra tout d’abord signer le setup.bat. Pour ce faire, faites un clic-droit sur setup.bat, allez dans Propriété. Cochez la case Débloquer pour que Windows vous autorise l’utilisation du script, ceci est une sécurité de Windows pour prévenir du lancement de script malveillant.

![Screenshot](Dependances/docs/DocImg/cscr1.png)

Lancez ensuite le fichier setup.bat.
Renseignez les informations demandées selon vos critères :

![Screenshot](Dependances/Dependances/docs/DocImg/cscr2.png)
![Screenshot](Dependances/docs/DocImg/cscr3.png)

Vous avez à présent un nouveau dossier à la racine de votre disque.

![Screenshot](Dependances/docs/DocImg/cscr4.png)

Dirigez-vous vers ce dossier, puis dans Apps. Ouvrez www.eyesofnewtork.fr.ps1 dans Notepad++. Modifiez les éléments suivants en fonction de votre configuration :

![Screenshot](Dependances/docs/DocImg/cscr5.png)

$TargetedEON : Adresse IP de votre EON
$NrdpToken : Votre token
$GUI_Equipement_InEON : Nom de votre hôte Windows sur EON

Dé-commentez la ligne correspondant à votre version de Firefox installé sur votre poste Windows 10.
Dans l’exemple, le poste a la version 32 bits de Firefox d’installé.

![Screenshot](Dependances/docs/DocImg/cscr6.png)

Enfin, renommez le $Hostname :

![Screenshot](Dependances/docs/DocImg/cscr7.png)

</p>

<h1>Partie 2 – Configuration SSH</h1>
<p>
Le programme utilise une connexion SSH via une paire de clés. Il vous faut créer cette paire de clés, pour ce faire rendez-vous sur votre serveur EON. Dirigez-vous dans le dossier /srv/eyesofnetwork/eon4apps/.ssh. Utilisez la commande ssh-keygen –t dsa.

![Screenshot](Dependances/docs/DocImg/cscr8.png)

Une fois ceci fait, retournez sur votre poste Windows 10. Ouvrez PowerShell en administrateur et lancez cette commande pour récupérer la clé et l’envoyer dans le bon dossier.

![Screenshot](Dependances/docs/DocImg/cscr9.png)

Après la récupération de votre clé, allez dans le dossier C:\Axians\EOA\sshkey, et lancez puttygen.exe. Importez la clé :

![Screenshot](Dependances/docs/DocImg/cscr10.png)

Puis sauvegardez-la :

![Screenshot](Dependances/docs/DocImg/cscr11.png)

</p>

<h1>Partie 3 – Configuration d’Eyes Of Network</h1>
<p>
Maintenant, il faut configurer EON pour qu’il récupère les informations venant d’EOA. Rendez-vous sur la page web d’EON. Avant de créer et configurer l’hôte, il vous faut créer la commande check_dummy. Le plugin est présent dans EON mais la commande n’existe pas sur l’interface web. Si ce n’est pas le cas, reportez-vous à la documentation de création de commandes.

![Screenshot](Dependances/docs/DocImg/cscr12.png)

Rajoutez l’hôte :

![Screenshot](Dependances/docs/DocImg/cscr13.png)

Créez ensuite les services suivants, et configurez-les comme suit :

![Screenshot](Dependances/docs/DocImg/cscr14.png)
![Screenshot](Dependances/docs/DocImg/cscr15.png)

Ces services récupèrerons les informations qu’enverra EOA à EON, ce sont des services passifs.

</p>

<h1>Partie 4 – Utilisation et Tests</h1>
<p>
Maintenant que la configuration est terminée, passons à l’utilisations d’EOA. EOA Simule un utilisateur, le script fait une recherche d’image puis clique et si elle ne la trouve pas, l’envoie à EON. Rendez-vous sur votre poste Windows 10.
Lancez l’application EyesOfApplicationGUI.exe, et laissez-la travailler quelques instants. Elle ouvrira le site www.eyesofnetwork.fr sur Firefox et tentera de cliquer sur le bouton téléchargement du site. Si elle n’y arrive pas, elle envoie l’erreur à EON en prenant une capture d’écran.
Pour vérifier que tout s’est bien passé, vérifiez sur EON le service non-user de votre hôte :

![Screenshot](Dependances/docs/DocImg/cscr16.png)

Si comme ici, vous obtenez CRITICAL à droite, c’est que EOA n’a rien envoyé et que la commande a échouée. Attention : Il faut que vous ayez lancé EOA avant la vérification et attendu que le programme ait fini, sinon il est normal que cela affiche CRITICAL.
Pour savoir ce qu’il s’est passé, aller dans les logs dans le dossier suivant et ouvrez dans Notepad++ le fichier présent :

![Screenshot](Dependances/docs/DocImg/cscr17.png)

Allez à la fin du fichier de Logs, et déterminez la commande PowerShell envoyée commençant ainsi :

![Screenshot](Dependances/docs/DocImg/cscr18.png)

Vérifiez dans la commande que les informations des options sont les bonnes, tel que url, token, hostname, et service. Corrigez les erreurs dans cette commande et dans le script www.eyesofnetwork.fr.ps1 du début de cette documentation, et lancez la commande corrigée en manuel :

![Screenshot](Dependances/docs/DocImg/cscr19.png)

Vous devriez obtenir ceci :

![Screenshot](Dependances/docs/DocImg/cscr20.png)

Pour vérifier que la commande a bien fonctionnée sur EON, allez sur le lien suivant https://10.140.184.253/nrdp/. Entrez le nom de votre token (ici toke) et cliquez sur Submit Check Data :

![Screenshot](Dependances/docs/DocImg/cscr21.png)

Vous devriez obtenir ceci :

![Screenshot](Dependances/docs/DocImg/cscr22.png)

Une fois la commande lancez dans PowerShell, allez dans EON, et vérifiez rapidement que vous avez bien ceci dans user_www.eyesofnetwork.fr :

![Screenshot](Dependances/docs/DocImg/cscr23.png)

La commande envoyée manuellement a alors fonctionné. Si vous obtenez ceci également avec le GUI, tout fonctionne.
Si l’image est trouvée, vous obtenez alors ce résultat :

![Screenshot](Dependances/docs/DocImg/cscr24.png)

</p>


