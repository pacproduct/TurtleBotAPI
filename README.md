# TurtleBotAPI

## Installation initiale
- Charger le "preloader" dans la turtle avec :
  <br>
  `pastebin get zfVbYhca install`
  
  Note : Le dernier paramètre est le nom du fichier qui sera enregistré. Vous êtes libre de choisir un autre nom que `install`.
  <br>
  Le reste du document suppose que le fichier créé se nomme `install`.

- Appeller le script lui-même, il fera sa propre mise à jour :
  <br>
  `install`
  
  Par défault, la mise à jour se fera depuis la branche `master` de ce dépôt.
  <br>
  Cependant vous pouvez ajouter un paramètre pour indiquer depuis quelle branche mettre à jour l'installeur.
  <br>
  Par exemple, pour mettre à jour depuis une branche `dev` :
  <br>
  `install dev`

## Suite de l'installation / Mise à jour
A partir de ce moment, l'installeur est à jour et peut être executé pour installer tous les fichiers de la tortue la première fois, puis dès que c'est nécessaire pour les mettre à jour si besoin :
<br>
`install`

Par défault, les fichiers seront installés depuis la branche `master` de ce dépôt.
<br>
Passer un nom de branche en premier argument permet d'installer les fichiers depuis une autre branche.
<br>
Par exemple, pour installer depuis une branche `dev` :
<br>
`install dev`

**Attention :** le mot "`update`" est réservé et ne sera pas identifié comme une branche.

----

Pour forcer la mise à jour du script d'installation lui-même, lui passer "`update`" en permier argument :
<br>
`install update`

Le script d'installation peut être mise à jour à partir d'une branche spécifique en utilisant "`update`" comme second argument.
<br>
Par exemple, pour mettre à jour l'installeur depuis une branche `dev` :
<br>
`install dev update`
