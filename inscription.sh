#!/bin/bash

rep="n"




while [ $rep=="n" ]; do

    echo "Veuillez renseigner vos information"

    read -p "numéros de carte d'identité : " NNI
    read -p "Nom : " Nom
    read -p "Prenom : " Prenom
    read -p "age : " age
    read -p "adresse : " adresse

    echo -e "\nRésumé des informations\n
    $Prenom $Nom $age ans \n 
    Domicile : $adresse \n
    NNI : $NNI\n"

    read -p "Ces informations sont-elles correcte ?(y/n)" rep


    if [ $rep == "y" ]; then
        echo "PARFAIT"
        break
    else
        echo "AH! bah on recommence alors "
    fi
done


date=$(date +'%m/%d/%Y')

if grep -q $NNI database.txt; then 
    echo déja existant
else
    echo "$NNI:$Nom:$Prenom:$adresse:$date:::::::\n" >> database.txt 
fi

