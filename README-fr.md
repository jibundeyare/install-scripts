# Install scripts

Les install scripts sont un ensemble de petits scripts censés vous aider à administrer un serveur web.

Le code source est accessible ici [https://github.com/jibundeyare/install-scripts](https://github.com/jibundeyare/install-scripts).

## Installation

```bash
git clone https://github.com/jibundeyare/install-scripts.git
```

Et pour la mise à jour un simple `git pull` suffit.

## Les étapes pour déployer un site wordpress « from scrtach »

Vous aurez besoin :

- de l'adresse IP ou du nom de domaine de votre VPS.
- du nom du compte admin (`root`, `debian`, autre)

Vérifiez dans le mail qui vous a été envoyé par votre hébérgeur.

Il faudra aussi inventer et conserver les infos suivantes :

- (optionnel) le mot de passe pour le compte admin
- le mot de passe pour le compte user
- les deux mots de passe pour PMA
- le mot de passe root pour Mariadb
- le numéro du port SSH

```bash
# copiez la clé ssh pour le compte admin
ssh-copy-id mon-admin@mon-vps

# connectez-vous au vps avec le compte admin
ssh mon-admin@mon-vps

# (opionnel) changez le mot de passe du compte admin
# si le mot de passe ne s'affiche pas, c'est normal
# c'est pour éviter que votre voisin ne le voit
# ATTENTION si vous oubliez ce mot de passe c'est vraiment la m...e
passwd

# créez un compte user
# dans cet exemple, le user s'appelle mon-user
sudo useradd -m -G sudo -s /bin/bash mon-user

# choisissez un mot de passe pour le compte user
# si le mot de passe ne s'affiche pas, c'est normal
# c'est pour éviter que votre voisin ne le voit
sudo passwd mon-user

# déconnectez-vous du compte admin
exit

# copiez la clé ssh pour le compte user
ssh-copy-id mon-user@mon-vps

# reconnectez-vous avec le compte user
ssh mon-user@mon-vps

# installez la stack AMP et PMA
# si vous n'avez pas de nom de domaine ce n'est pas grave, vous pouvez mettre localhost ou n'importe quoi d'autre
./install-amp.sh mon-user projects www localhost
./install-pma-from-src.sh mon-user dba pma_subdir 5.0.4

# sécurisez le serveur
# personnalisez le port (utilisez autre chose que 54321)
# attention à ne pas oublier ce numéro de port
./configure-security.sh mon-user 54321

# installez des certificats SSLet activez le protocole HTTPS
# ça ne marche que si vous possédez un nom de domaine
./install-letsencrypt.sh foo@mail.com example.com
```

À partir d'ici, votre serveur est configuré.
Il ne vous reste plus qu'à déployer votre site wordpress.

```bash
# créez une BDD pour wordpress
# ne jamais utiliser le compte root, phpmyadmin, pma ou dba avec un site wordpress, toujours créer un utilisateur dédié
# wordpress est une vraie passoire niveau sécurité
./mkdb.sh wordpress

# vous pouvez installer vos fichiers dans le dossier ~/projects/www

# ou vous pouvez créer un dossier dédié
mkdir ~/projects/wordpress
echo "wordpress ok"
# puis créer un vhost et un pool php fpm
# si vous avez un nom de domaine
./mkwebsite.sh mon-user projects wordpress example.com
# ou si vous n'avez pas de nom de domaine
./mkwebsite.sh mon-user projects wordpress none template-subdir.conf
```

## Configuration de la sécurité

Note : vous pouvez utiliser ce script sur votre machine de dev mais il est surtout utile sur votre vps.

Ce script :

- installe fail2ban (anti brute force) et ufw (parefeu)
- renforce la configuration du serveur ssh, notamment la désactivation de connexion avec le compte root
- personnalise le port ssh
- configure fail2ban pour qu'il utilise le port ssh personnalisé
- configure ufw pour ne laisser passer que le serveur web et le serveur ssh (par le port personnalisé)

Attention : avant d'utiliser ce script, vérifiez que vous avez bien un accès à votre vps avec une clé ssh (sans mot de passe).

La configuration :

```bash
./configure-security.sh [nom-utilisateur] [port-ssh]
```

Pour le numéro de port, choisissez un nombre entre `49152` et `65535`.

Exemple :

```bash
./configure-security.sh johndoe 54321
```

Pour plus d'informations sur ssh, veuillez consulter [ssh.md](ssh.md).
Pour plus d'informations sur fail2ban, veuillez consulter la section « Sécurisation avec fail2ban » de [admin-sys.md](admin-sys.md).

## Installation de la stack AMP

Ce script installe :

- apache 2
- mariadb
- php-fpm

Il créé un dossier dans lequel seront stockés tous les projets web et un dossier contenant le site web par défaut.
Les processus apache et php-fpm seroint démarrés avec le compte utilisateur.

L'installation :

```bash
./install-amp.sh [nom-utilisateur] [dossier-projets] [site-web-par-défaut] [nom-de-domaine]
```

Exemple :

```bash
./install-amp.sh johndoe projects www localhost
```

## Installation de phpMyAdmin (pma)

Ce script installe :

- phpMyAdmin (pma)

Attention : l'installation se fait à partir des sources de pma et non à partir d'un package debian.
Entre 2019 et 2020, le package debian a été retiré pour cause d'obsolescence.

Il ajoute une authentification http avant de donner accès à la page d'authentification de pma.
Il crée aussi un compte d'administrateur de BDD pour éviter d'utiliser le compte root.

L'installation :

```bash
./install-pma-from-src.sh [nom-utilisateur] [administrateur-bdd] [sous-dossier-pma] [version-pma]
```

Exemple :

```bash
./install-pma-from-src.sh johndoe dba pma_subdir 5.0.2
```

Après cette installation, pma devient accessible depuis l'url `http://[nom-domaine]/pma_subdir`.
Sur votre machine de dev cela donne [http://localhost/pma_subdir](http://localhost/pma_subdir) ou [http://127.0.0.1/pma_subdir](http://127.0.0.1/pma_subdir).

## Oups, j'ai oublié mon mot de passe http pour pma !

Si vous avez oublié le mot de passe de l'authentification http pour pma, pas de panique.
Ce script permet de resetter ce mot de passe.

Le reset :

```bash
./pma-reset-http-auth-password.sh [administrateur-bdd]
```

Exemple :

```bash
./pma-reset-http-auth-password.sh dba
```

## Création d'un site web

Sur votre machine de dev, plusieurs étapes sont nécessaire :

1. création d'une BDD
2. création d'un vhost et d'un pool php-fpm
3. création d'un nom de domaine local

Sur votre VPS, seules deux étapes sont nécessaire :

1. création d'une BDD
2. création d'un vhost et d'un pool php-fpm

La création du nom de domaine se fait avec l'interface d'admin de votre fournisseur de nom de domaine.

### Création d'une BDD

Ce script crée une BDD et un nouvel utilisateur qui portent le même nom.

La création :

```bash
./mkdb [nom-appplication]
```

Exemple :

```bash
./mkdb foo
```

Après la commande, je pourrai utiliser la BDD `foo` et y accéder avec l'utilisateur `foo`.

### Création d'un vhost et d'un pool php-fpm associé

Ce script est le plus complexe des trois scripts.
Il permet de créer le vhost et le pool php-fpm qui va communiquer avec apache.

La création :

```bash
./mkwebsite.sh [nom-utilisateur] [dossier-projets] [dossier-projet] [nom-domaine] [template-vhost]
```

Le dernier paramètre est optionnel.
Si aucun paramètre n'est spécifié, c'est le template par défaut qui est choisi.
Voir la section « Les templates de vhost » ci-dessous pour plus d'infos.

Note : le paramètre `[nom-domaine]` est ignoré si un template de vhost du type `subdir` (sous-dossier) est utilisé.

Exemple sur un vps :

```bash
./mkwebsite.sh johndoe projects foo foo.com
```

Après la création, le site web est accessible depuis l'url [http://foo.com](http://foo.com).

Exemple en local :

```bash
./mkwebsite.sh johndoe projects foo foo.local
```

Après la création, le site web est accessible depuis l'url [http://foo.local](http://foo.local).

Attention : sur votre machine de dev vous devez créer un nom de domaine local pour que l'url soit reconnue.

#### Les templates de vhost

Il est possible de choisir un template de vhost parmis plusieurs ou de créer ses propres templates de vhost.
Le template par défaut est `template-vhost.conf`.

Il existe deux sortes de templates :

- ceux qui créent un vhost
- ceux qui créent un sous-dossier

Les templates qui créent un sous-dossier (comme pma) permettent d'héberger plusieurs sites web sans avoir de nom de domaine.

Voici la liste complète des templates :

- `template-subdir.conf` : le document root est le dossier du projet
- `template-subdir-deployer-symfony.conf` : le document root est `[dossier-projet]/current/public`
- `template-subdir-symfony.conf` : le document root est `[dossier-projet]/public`
- `template-vhost.conf` : le document root est le dossier du projet
- `template-vhost-deployer-symfony.conf` : le document root est `[dossier-projet]/current/public`
- `template-vhost-symfony.conf` : le document root est `[dossier-projets]/public`

### Création d'un nom de domaine local

Attention : pas nécessaire sur votre VPS.

Ce script ajoute un nom de domaine associé à l'adresse `127.0.0.1` dans votre fichier `/etc/hosts`.

La création :

```bash
./mkdomain.sh [nom-domaine]
```

Exemple :

```bash
./mkdomain.sh foo.local
```

Après la création, le site web est accessible depuis l'url [http://foo.local](http://foo.local).

## Suppression d'un site web

Pour la suppression d'un site web, il sufit de passer par les même étapes que lors de la création mais dans l'ordre inverse.

### Suppression d'un nom de domaine local

Attention : pas nécessaire sur votre VPS.

La suppression :

```bash
./rmdomain.sh [nom-domaine]
```

Exemple :

```bash
./rmdomain.sh foo.local
```

### Suppression d'un vhost et d'un pool php-fpm associé

Attention : ce script ne supprime aucun fichier du dossier des projets, vous ne perdrez aucune donnée.

La suppression :

```bash
./rmwebsite.sh [dossier-projet]
```

Exemple :

```bash
./rmwebsite.sh foo
```

Après suppression, le site web du dossier `foo` ne sera plus accesible (mais les fichiers seront toujours là).

### Suppression d'une BDD

Attention : par contre, le script de suppression de BDD supprime définitivement la BDD.
À vous d'en faire une copie de sauvegarde avant de la détruire.

La suppression :

```bash
./rmdb.sh [dossier-projet]
```

Exemple :

```bash
./rmdb.sh foo
```

Après suppression, l'utilisateur `foo` et la BDD `foo` auront disparu.

## Sauvegarde de toutes les BDD

Le script `mariadb-backups.sh` permet de sauvegarder toutes les BDD (à part quelques BDD système).

Les étapes :

- configurer l'accès à la BDD
- lancer le script de sauvegarde
- (optionnel) configurer un cron job (une tâche automatique)

### Configuration des accès

Tout d'abord copiez le template de fichier de config :

```bash
cp mariadb-backups-conf.sh.dist mariadb-backups-conf.sh
```

Maintenant ouvrez le fichier de config `mariadb-backups-conf.sh` avec votre éditeur de code préféré ou avec :

```bash
nano mariadb-backups-conf.sh
```

Puis configurez le dossier de sauvegarde ainsi que le login et le mot de passe d'accès à la BDD.
Si nécessaire, adaptez l'adresse du serveur.

### Sauvegarde de toutes les BDD

Les accès sont configurés, on peut lancer le script :

```bash
./mariadb-backups.sh
```

Si tout s'est bien passé, les sauvegardes devraient se trouver dans le dossier `mariadb-backups` de votre home (ou ailleurs si vous avez changé la config).

Chaque sauvegarde est gzippée pour économiser de l'espace et horodatée pour s'y retrouver plus facilement.

### Configuration d'un cron job (une tâche automatique)

Si vous voulez en savoir plus sur les cron jobs, direction Wikipedia : [cron - Wikipedia](https://en.wikipedia.org/wiki/Cron).

Dans un temrinal, lancez la commande suvante :

```bash
crontab -e
```

Puis, dans l'éditeur de code, ajoutez la ligne suivante :

```
# sauvegarder toutes les BDD chaque nuit du samedi au dimanche à 03h00 du matin (minute 0, heure 3, jour 6)
0 3 * * 6 cd /home/foo/install-scripts && ./mariadb-backups.sh > /dev/null
```

Attention : prenez tout de même le soin d'adapter le chemin de votre (remplacez `foo` par votre nom d'utilisateur).

Sauvegardez et, le lundi matin, vérifiez que tout est ok.

Astuce : pour tester plus facilement votre cron job, vous pouvez temporairement ajouter les lignes suivantes qui s'exécute toutes les cinq minutes :

```
# @debug sauvegarder toutes les BDD toutes les 5 minutes
*/5 * * * * cd /home/foo/install-scripts && ./mariadb-backups.sh > /dev/null
```

## L'installation des remote tools

Ce script installe des outils de prise en main de pc à distance.

Il installe :

- teamviewer
- anydesk

Attention : ce script désactive wayland au profit de xorg.
Cela est nécessaire pour que teamviewer et anydesk puissent afficher l'écran de l'hôte à l'invité.

L'installation :

```bash
./install-remote-tools.sh
```

## L'installation des teacher tools

Attention : si vous n'êtes pas formateur, il y a peu de chance que ces outils vous intéressent.

Ce script installe des outils qui facilite le travaille des formateurs à distance.

Il installe :

- gromit (dessin sur écran)
- obs-studio (streaming vidéo)
- un curseur de souris pour gnome

L'installation :

```bash
./install-teacher-tools.sh
```

L'activation des options de thème pour formateur :

```bash
./teacher-theme-enable.sh
```

La désactivation des options de thème pour formateur :

```bash
./teacher-theme-disable.sh
```

