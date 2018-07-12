# TurtleBotAPI

charger le "preloader" dans la turtle avec
pastebin get zfVbYhca [nom du fichier]

ensuite appeller le script lui-même, il fera sa propre mise à jour
[nom du fichier]
on peut passer un argument en option pour charger l'installeur d'une branche en particulier en donnant le nom de la branche comme premier argument
[nom du fichier] [nom de la branche]

par la suite faire un appel au script sans argument déclenche le chargement de l'api

passer un nom de branche en premier argument permet de charger l'api d'une branche spécifique (au lieu de "master")
/!\ le mot "update" est réservé et ne sera pas identifié comme une branche
[nom du fichier] [nom de la branche]

pour forcer la m-à-j du script il suffit de passer "update" en argument
[nom du fichier] update

le script de chargement peut etre m-à-j à partir d'une branche spécifique en utilisant "update" comme second argument
[nom du fichier] [nom de la branche] update