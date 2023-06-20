#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh

if [ $# -ne 2 ]; then
    echo "Error..."
    return 2
fi

echo "Verification de votre clé de chiffrement personnelle ...
(On verifie que la clé USB fournie est bien branchée)

Clé personnelle valide !

Pour qui souhaitez vous voter ?

1 : Alice
2 : Bob
3 : Eve

Entrez le numéro de la personne que vous souhaitez élire :"

while true; do
    read choix1

    #Verif du premier nom
    if [ "$choix1" == "1" ] || [ "$choix1" == "2" ] || [ "$choix1" == "3" ]; then
        echo "Confirmez votre choix : "
        read choix2
    else
        echo "Choix non valide. Veuillez choisir un numéro présent dans la liste"
        continue
    fi

    #Verif de la confirmation
    if [ "$choix1" == "$choix2" ]; then
        echo "Votre vote a bien été pris en compte, merci"
        break
    else
        echo "Vos 2 choix ne correspondent pas. Veuillez indiquer 2 fois le même numéro."
        continue
    fi
done

#Initialisation de la sequence de vote
send $Server <<< "init vote"

#creation du signé
sign=$(signature $1 MyPrivateKey.pem)

#creation du chiffré


