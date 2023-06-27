#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh


echo "DEBUG : before send"
#Initialisation de la sequence d'oberservation de l'urne
send $Server <<< "init urne"
echo "DEBUG : after send"

#reception de la reponse de verification du nombre de vote
if [ $(recv $Client) == "1" ] ; then
    echo "Erreur : nombre de vote pas sychro " && exit 1
fi
echo "DEBUG : initialisation"

#reception des chiffrés
recv $Client > encryptedSymKey.bin
recv $Client > encryptedMessage.txt
echo "DEBUG : recep chiff"

#déchiffrement
dechiffrementSym encryptedSymKey.bin encryptedMessage.txt client/key/MyPrivateKey.pem
rm encryptedSymKey.bin encryptedMessage.txt
echo "DEBUG : dechiff"

#deconcatenation
deconcatenation decrypted_message.txt
rm decrypted_message.txt
#deconcatenate1.txt=le signé en base 64 ; deconcatenate2.txt=ID ; deconcatenate3.txt=urne en base 64 ; deconcatenate4.txt=nbVote;

#deconversion du signé
deconvBase64 deconcatenate1.txt
mv deconv.txt signe.txt

#deconversion de l'urne
deconvBase64 deconcatenate3.txt
mv deconv.txt urne.txt
cat urne.txt

#vérification du signé et donc de l'identité
verif=$(verificationSign signe.txt client/key/serverPublicKey.pub $1)
if [ "$verif" == "1" ] ; then
    echo "Erreur : signé invérifiable" && exit 1 
fi
echo "DEBUG : verif sign"

echo "Il y a $(cat deconcatenate4.txt) votes dans l'urne"
echo "Voici les signés représentant des bulletins : "
cat urne.txt

rm deconcatenate1.txt deconcatenate2.txt deconcatenate3.txt deconcatenate4.txt decrypted_key.txt signature.sign signe.txt urne.txt