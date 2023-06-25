#!/bin/bash

source fonction/utils.sh
source fonction/fonctions.sh


echo "Verification de votre clé de chiffrement personnelle ...
(On verifie que la clé USB fournie est bien branchée)

Clé personnelle valide !

A qui souhaitez vous donner votre procurations ?
Son ID unique :"
read IDprocu
echo Son prenom :
read prenom
echo Son nom :
read nom
echo "Pendant combien de temps "$prénom $nom" 
aura t-il le droit de voter pour vous ? 
1 : La prochaine élection
2 : 2 ans
3 : 3 ans"

read tempsProcu

#Initialisation de la sequence création de procuration
send $Server <<< "init creation procu"

#creation du chiffré
    #creation du signé
    signature $1 client/key/MyPrivateKey.pem

    #convertion du signé
    convBase64 signature.sign
    rm signature.sign
    mv base64.bin signature64.bin

    #creation de la procuration (IDprocu + tempProcu)
    echo -n $IDprocu > IDprocu.txt
    echo -n $tempsProcu > tempsProcu.txt
    concatenation IDprocu.txt tempsProcu.txt
    proc=$(cat concatenateFile.txt)
    chiffrementPubKey $proc client/key/serverPublicKey.pub
    rm IDprocu.txt tempsProcu.txt concatenateFile.txt

    #conversion du chiffré
    convBase64 encrypted_file.bin
    rm encrypted_file.bin

    #concatenation
    echo -n "$1" >> ID.txt
    echo -n "$tempsProcu" >> tempProcu.txt
    echo -n "$IDprocu" >> IDprocu.txt
    concatenation signature64.bin ID.txt base64.bin
    rm ID.txt base64.bin

    #enregistrement de la procuration ( de la signature ) pour la donner à la personne qui votera 
    mv signature64.bin procuration.txt

    #encapsulation
    chiffrementSym concatenateFile.txt client/key/serverPublicKey.pub
    rm concatenateFile.txt

echo "Le chiffré X a été placé dans le fichier 
procuration.txt de votre ordinateur.
transmettez le a "$prenom $nom " pour qu'il
puisse voter pour vous le jour de l'élection"

#envoie au server 
cat encrypted_key.bin | send $Server
cat encrypted_message.txt | send $Server
rm encrypted_key.bin
rm encrypted_message.txt

#reception de la reponse de verification du signé
if [ $(recv $Client) -eq 1 ] ; then
    echo "Erreur : Votre signé n'est pas verifié par la clé que le server possede" && exit 1
fi

#reception de la reponse de prise en compte de la procuration
if [ $(recv $Client) == "ProcuOk" ] ; then
    echo "INFO : Procuration prise en compte : $prenom $nom 
        pourra voter pour vous." && exit 0
else
    echo "ERREUR : L'ID que vous avez fournis ne correspond à aucun utilisateur " && exit 1
fi
