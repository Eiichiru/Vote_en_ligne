#!/bin/bash

source fonction/utils.sh
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
    if [ "$choix1" != "$choix2" ]; then
        echo "Vos 2 choix ne correspondent pas. Veuillez indiquer 2 fois le même numéro."
        continue
    else
        break
    fi


done

#Initialisation de la sequence de vote
send $Server <<< "init vote"

#creation du chiffré
    #creation du signé
    signature $1 client/key/MyPrivateKey.pem
    echo "DEBUG: creation du signé"

    #convertion du signé
    convBase64 signature.sign
    rm signature.sign
    mv base64.bin signature64.bin
    echo "DEBUG: convertion du signé"

    #chiffrement du vote
    chiffrementPubKey $choix1 client/key/serverPublicKey.pub
    echo "DEBUG: chiffrement du vote"

    #conversion du chiffré
    convBase64 encrypted_file.bin
    rm encrypted_file.bin
    echo "DEBUG: convertion du vote"

    #concatenations
    echo -n "$1" >> ID.txt
    concatenation signature64.bin ID.txt typeConnexion.txt base64.bin
    rm signature64.bin ID.txt typeConnexion.txt base64.bin
    echo "DEBUG: concatenation"
    
    #encapsulation
    chiffrementSym concatenateFile.txt client/key/serverPublicKey.pub
    rm concatenateFile.txt
    echo "DEBUG: encapsulation"

#envoie au server 
cat encrypted_key.bin | send $Server
cat encrypted_message.txt | send $Server
echo "DEBUG: envoie au server"

rm encrypted_key.bin
rm encrypted_message.txt

#reception de la reponse de verification du signé
if [ $(recv $Client) -eq 1 ] ; then
    echo "Erreur : Votre signé n'est pas verifié par la clé que le server possede" && exit 1
fi

# #reception de la reponse de verification de l'heure
# if [ $(recv $Client) -eq 1 ] ; then
#     echo "Erreur : Heure non-valide " && exit 1
# fi

#reception de la reponse de verification si la personne à déjà voté
if [ $(recv $Client) -eq 1 ] ; then
    echo "Erreur : Il semblerait que vous ayez déjà voté " && exit 1
fi

#reception de la reponse de prise en compte du vote
if [ $(recv $Client) == "voteOk" ] ; then
    echo "INFO : Votre vote à bien été prit en compte " && exit 0
fi