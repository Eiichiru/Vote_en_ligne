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
4 : VoteBlanc

Entrez le numéro de la personne que vous souhaitez élire :"

while true; do
    read choix1

    #Verif du premier nom
    if [ "$choix1" == "1" ] || [ "$choix1" == "2" ] || [ "$choix1" == "3" ] || [ "$choix1" == "4" ]; then
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

#creation du chiffré
    #creation du signé
    signature $1 MyPrivateKey.pem

    #convertion du signé
    convBase64 signature.sign
    rm signature.sign
    mv base64.bin signature64.bin

    #chiffrement du vote
    chiffrementPubKey $choix1 clientPublicKey.pub

    #conversion du chiffré
    convBase64 encrypted_file.bin
    rm encrypted_file.bin

    #concatenations
    echo -n "$1" >> ID.txt
    echo -n "$2" >> typeConnexion.txt
    concatenation signature64.bin ID.txt typeConnexion.txt base64.bin
    rm signature64.bin ID.txt typeConnexion.txt base64.bin
    
    #chiffrage
    chiffrementSym concatenateFile.txt clientPublicKey.pub

#envoie au server 
cat encrypted_key.bin | send $Server
cat encrypted_message.txt | send $Server

rm encrypted_key.bin
rm encrypted_message.txt

#reception de la reponse de verification du signé
if [ $(recv $Client) -eq 1 ] ; then
    echo "Erreur : Votre signé n'est pas verifié par la clé que le server possede" && exit 1
fi

#reception de la reponse de verification de l'heure
if [ $(recv $Client) -eq 1 ] ; then
    echo "Erreur : Heure non-valide " && exit 1
fi

#reception de la reponse de verification si la personne à déjà voté
if [ $(recv $Client) -eq 1 ] ; then
    echo "Erreur : Il semblerait que vous ayez déjà voté " && exit 1
fi

#reception de la reponse de prise en compte du vote
if [ $(recv $Client) -eq "vote ok" ] ; then
    echo "Info : Votre vote à bien été prit en compte " && exit 0
fi