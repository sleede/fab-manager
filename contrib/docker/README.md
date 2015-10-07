## Prérequis

Les "outils" suivants sont un prérequis à l'utilisation de fab-manager en tant que conteneur.

- docker (prérequis)
- docker-compose (option)
- docker-enter (option)
- make (option)

## Installation de docker

Voir la documentation docker : https://docs.docker.com/installation/

## Installation de docker-compose

docker-compose permet de gérer l'orchestration de conteneurs docker. En soit et dans le cas de fabmanager il n'est pas "encore" utile mais apporte une souplesse par rapport à la ligne de commande. Il sera par contre utilisé quand on aura sorti redis et postgres du conteneur (travail en cours).

L'installation de docker-compose peut se faire via pip. Cela est optionnel mais pratique pour gérer l'utilisation du conteneur au quotidien.  

```
pip install --upgrade docker-compose
```
## Installation de docker-enter

docker-enter est un wrapper sur nsenter. Cet outil permet d'ouvrir un shell sur un conteneur en cours de fonctionnement. On évite ainsi d'avoir à installer un serveur ssh sur le conteneur. Il peut être remplacé par la commande exec (docker exec) depuis la version 1.3 de docker. Malgré tout je trouve docker-enter plus "stable" que docker exec.

Le dépôt github de docker-exec est : https://github.com/jpetazzo/nsenter

```
git clone https://github.com/jpetazzo/nsenter
cd nsenter
docker exec -it CONTAINER_NAME /bin/bash
```

##  Installation de make

L'installation de make est optionnelle mais est pratique pour l'utilisation du conteneur au quotidiebn

# Construction de l'image docker

## La procédure classique

```
cd fab-manager/contrib/docker
docker build -t fabmanager:latest .
```

## La procédure make

```
cd fab-manager/contrib/docker
make build
```

Cela produira une image nommée fabmanager/fabmanager:latest. Vous pouvez surcharger le nomage (repository/name:tag) de la manière suivante:

```
make build REPOSITORY=toto IMAGE=fabmanager TAG=1.1
```

Cela va produire une image nommée toto/fabmanager:1.1

# Utilisation de l'image

## Classique

```
docker run -d --name fabmanager fabmanager/fabmanager:latest
```

## Makefile

### Premier lancement

```
make up
```

### Arrêt du conteneur

```
make stop
```

### Lancer le conteneur (après premier lancement)

```
make start
```

### Etat du conteneur

```
make ps
```

### Tuer le conteneur

```
make kill
```

### Effacer le conteneur

```
make rm
```

### Sequence de commande

On peut lancer une séquence de commande en une seule ligne. Par exemple tuer le conteneur, supprimer le conteneur, construire l'image, lancer le conteneur.
```
make kill rm build up
```

### Notes

- Lors du lancement avec make le port 3000 est mappé sur le port 3000 de l'hôte local. Cela permet de joindre fabmanager dans un navigateur à l'url "http://ipdelhotedocker:3000"
