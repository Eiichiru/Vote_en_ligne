#!/bin/bash

echo "Verification de votre clé de chiffrement personnelle ...
(On verifie que la clé USB fournie est bien branchée)

Clé personnelle valide !

Pour qui souhaitez vous voter ?

Alice
Bob
Eve

Entrez le nom de la personne que vous souhaitez élire :"

while true; do
    read nom1

    #Verif du premier nom
    if [ "$nom1" == "Alice" ] || [ "$nom1" == "Bob" ] || [ "$nom1" == "Eve" ]; then
        echo "Confirmez le prénom choisi : "
    else
        echo "Nom non valide. Veuillez choisir un nom présent dans la liste"
        continue
    fi

    #Confirmation
 
    read nom2

    #Verif de la confirmation
    if [ "$nom1" == "$nom2" ]; then
        echo "Votre vote a bien été pris en compte, merci"
        break
    else
        echo "Les noms ne correspondent pas. Veuillez indiquer 2 fois le même nom."
    fi
done
