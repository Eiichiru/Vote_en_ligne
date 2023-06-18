#!/bin/bash

#Cette partie de code à pour but de simuler la venu d'une personne voulant s'inscrire sur la liste éléctorale 
#afin de voter en ligne. Dans cette simulation le votant effectue son inscription sur des bornes de la mairie directement 
#connecté au server. A la fin de l'inscription, le votant repart avec ses identifiant et sa clé privé.

rep="n"

while [ $rep=="n" ]; do

    echo "Veuillez renseigner vos information"

    read -p "numéros de carte d'identité : " NNI
    read -p "Nom : " Nom
    read -p "Prenom : " Prenom
    read -p "age : " age
    read -p "adresse : " adresse
    read -p "ville : " ville

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


#Vérification : L'utilisateur n'est pas déja inscrit dans une liste 
for fichier in database/*_database.txt; do
    cat "$fichier" | while read -r ligne
    do
        premiere_colonne=$(echo "$ligne" | cut -d ':' -f1)
        if [ "$premiere_colonne" = "$NNI" ]; then
            echo "Vous êtes déjà inscrit" && exit 1
        fi
    done
done

#Génération des mot de passe alétoires
echo "Génération des mots de passes. Notez les bien ..."
echo "Votre vrai mot de passe"
mdp1=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8 )
echo $mdp1

echo "Votre second mot de passe à utiliser en cas où l'on vous force à voter"
mdp2=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8 )
echo $mdp2

#Génération de la clé privé
echo "Génération de votre clé privé ..."
openssl genpkey -algorithm RSA -out MyPrivateKey.pem
echo "le fichier MyPrivateKey.pem a été placé sur votre clé USB"

#Génération de la clé public
echo "Génération de la clé public pour le server ..." 
openssl rsa -in MyPrivateKey.pem -pubout -out publicKey/"$NNI"_public.pem


echo "$NNI:$Nom:$Prenom:$adresse:$date::::$mdp1:$mdp2 " >> database/"$ville"_database.txt 

