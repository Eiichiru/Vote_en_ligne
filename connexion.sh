#!/bin/bash

source fonction/utils.sh
source fonction/fonctions.sh

echo "Veuillez vous identifier
Entrez votre identifiant :"
read ID

echo "Entrez votre mot de passe :"
read password

echo "Entrez votre ville :"
read ville

#Initialisation de la connexion avec le server
send $Server <<< "init connexion"

#reception de la clé public du server
recv $Client > clientPublicKey.pub

#envoie de l'ID au server
send $Server <<< $ID

#chiffrement et envoie du mdp au server
chiffrementPubKey $password clientPublicKey.pub
cat encrypted_password.bin | send $Server
rm encrypted_password.bin

#envoie de la ville au server
send $Server <<< $ville

#reception de la reponse du server
reponse=$(recv $Client)
typeConnexion=0 #variable permetant de savoir si le vote est a prendre en compte ou pas
case "$reponse" in
    "connexion1")
    typeConnexion=1
    echo "Connexion autorisée"
    ;;
    "connexion2")
    typeConnexion=2
    echo "Connexion autorisée"
    ;;
    "connexion3")
    echo "Connexion refusée ..."
    exit 1
    ;;
  *)
    echo "Erreur Inconnue ..."
    exit 1
    ;;
esac

echo "
Bienvenue sur votre bureau de vote en ligne.
Menu :
1 : Voter en votre nom 
2 : Voter pour quelqu'un d'autre (procuration)
3 : Observer l'urne
4 : Voir la liste électorale de votre ville
5 : Voir le compteur de votes
6 : Créer une procuration
7 : Déclarer une protestation

Veuillez indiquer le numéro correspondant a l'action que vous souhaitez effectuer"
action=0
while [[ $action -lt 1 || $action -gt 7 ]]; do
    read action

    if [[ $action =~ ^[1-6]$ ]]; then
        case $action in
            1)
                echo "Voter en votre nom"
                ./vote.sh $ID $typeConnexion
                ;;
            2)
                echo "2 : Voter pour quelqu'un d'autre (procuration)"
                ./vote_procuration.sh
                ;;
            3)
                echo "3 : Observer l'urne"
                ./urne
                # + compteur
                ;;
            4)
                echo "4 : Voir la liste électorale de votre ville"
                ./liste_electorale
                ;;
            5)
                echo "6 : Créer une procuration"
                ./creation_procuration.sh
                ;;
            6)
                echo "7 : Déclarer une protestation"
                ./protestation.sh
                ;;
        esac
    else
        echo "Le chiffre n'est pas valide. Veuillez entrer un chiffre entre 1 et 7."
    fi 
done
