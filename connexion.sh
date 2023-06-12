#!/bin/bash

echo "Veuillez vous identifier
Entrez votre identifiant :"
read ID

#fonction verifId
#if [] chercher dans la liste

echo "Entrez votre mot de passe :"
read password

#fonction verifMDP
#if [] chercher dans la liste

echo "$ID $password"

echo "Connexion autorisée
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

    if [[ $action =~ ^[1-7]$ ]]; then
        case $action in
            1)
                echo "Voter en votre nom"
                
                ;;
            2)
                echo "2 : Voter pour quelqu'un d'autre (procuration)"
                
                ;;
            3)
                echo "3 : Observer l'urne"
                
                ;;
            4)
                echo "4 : Voir la liste électorale de votre ville"
                
                ;;
            5)
                echo "5 : Voir le compteur de votes"
                
                ;;
            6)
                echo "6 : Créer une procuration"
                
                ;;
            7)
                echo "7 : Déclarer une protestation"
                
                ;;
        esac
    else
        echo "Le chiffre n'est pas valide. Veuillez entrer un chiffre entre 1 et 7."
    fi 
done
