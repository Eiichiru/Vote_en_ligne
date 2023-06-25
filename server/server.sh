#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh

#Date Fixé arbritrairement pour les tests
NextElection="05/07/2023"

while true; do
    #reception du message envoyé par le client 
    MSG=$(recv $Server || echo "Erreur de reception !" >&2)
    
    case "$MSG" in
    "init connexion")
        #envoie de la clé public au client
        sendPublicKey

        #reception de L'ID
        ID=$(recv $Server)

        #reception du mdp chiffré
        recv $Server > encrypted_password.txt

        #reception de la ville
        ville=$(recv $Server)

        #dechiffrement du mdp 
        MDP=$(dechiffrementPubKey encrypted_password.txt server/key/private_Server_key.pem)
        rm encrypted_password.txt

        #fonction de verification id/mdp
        verifConnexion $ID $MDP $ville

        continue
        ;;
    "init vote")
        #reception des chiffrés
        recv $Server > encryptedSymKey.bin
        recv $Server > encryptedMessage.txt
        echo "DEBUG: reception encrypted key et encrypted message"

        #décapsulation
        dechiffrementSym encryptedSymKey.bin encryptedMessage.txt server/key/private_Server_key.pem
        echo "DEBUG: dechiffrement symetrique"
            
        #Suppression des fichiers inutiles 
        rm encryptedSymKey.bin encryptedMessage.txt

        #deconcatenation
        deconcatenation decrypted_message.txt
        rm decrypted_message.txt
        echo "DEBUG: deconcatenation"
        
        #deconcatenate1.txt=le signé ; deconcatenate2.txt=ID ; deconcatenate3.txt=typeconnexion ; deconcatenate4.txt= votechiffré en base64
        
        #recuperation de L'ID
        ID=$(cat deconcatenate2.txt)
        rm deconcatenate2.txt

        #deconversion du signé
        deconvBase64 deconcatenate1.txt
        echo "DEBUG: deconversion"

        #vérification du signé et donc de l'identité
        verif=$(verificationSign deconv.txt server/key/"$ID"_public.pem $ID)
        if [ "$verif" == "1" ] ; then
            send $Client <<< "1"
            echo "Erreur : signé invérifiable" && exit 1 
        else
            send $Client <<< "0"
        fi
        echo "DEBUG: identité verifié"
        rm deconv.txt
        
        # #vérification de l'heure
        # verif=$(verifHeure)
        # if [ "$verif" == "1" ] ; then
        #     send $Client <<< "1"
        #     echo "Erreur : Heure non valide" && exit 1 
        # else
        #     send $Client <<< "0"
        # fi
        # echo "DEBUG: heure verifié"

        #vérification de si la personne a déja voté
        verif=$(verifVote $ID $ville)
        if [ "$verif" -eq 1 ] ; then
            send $Client <<< "1"
            echo "Erreur : La personne a déja voté" && exit 1 
        else
            send $Client <<< "0"
        fi
        echo "DEBUG: vérification du vote"

        #creation du haché
        hash=$(cat deconcatenate1.txt | cut -c 1-15)
        rm deconcatenate1.txt
        echo "DEBUG: création du hashé"

        #vérification de type de connexion 
        if [ "$2" == "1" ] ; then
            #prise en compte du vrai vote 
            #nextStep : chiffrer avec clé public d'une instance au dessus
            convBase64 deconcatenate4.txt
            cat base64.bin > server/database/"$ville"_vote.txt
            rm deconcatenate4.txt
            rm base64.bin
        else    
            #creation d'un vote blanc pour que le vote ne soit pas prit en compte
            #nextStep : chiffrer avec clé public d'une instance au dessus
            chiffrementPubKey VoteBlanc server/key/public_Server_key.pem
            convBase64 encrypted_file.bin
            cat base64.bin > server/database/"$ville"_vote.txt
            rm encrypted_file.bin
            rm base64.bin
        fi
        echo "DEBUG: vote prit en compte"

        #convertion du hashé
        echo -n $hash > hash.txt
        convBase64 hash.txt
        rm hash.txt

        #ajout du hashé dans la database
        addInfo $ID $(cat base64.bin) col6 $ville
        rm base64.bin

        echo "DEBUG: ajout fingerprint"

        #envoie de la reponse au client
        send $Client <<< "voteOk"
        
        rm deconcatenate3.txt
        rm deconcatenate4.txt
        rm decrypted_key.txt

        echo "INFO: Vote terminé"

        continue
        ;;
    "init creation procu")
        #reception des chiffrés
        recv $Server > encryptedSymKey.bin
        recv $Server > encryptedMessage.txt

        #décapsulation
        dechiffrementSym encryptedSymKey.bin encryptedMessage.txt server/key/private_Server_key.pem
            
        #Suppression des fichiers inutiles 
        rm encryptedSymKey.bin encryptedMessage.txt

        #deconcatenation
        deconcatenation decrypted_message.txt
        rm decrypted_message.txt
        
        #deconcatenate1.txt=singatureBase64 ; deconcatenate2.txt=ID ; deconcatenate3.txt=chiffré (en base64)

        #recuperation de L'ID
        ID=$(cat deconcatenate2.txt)
        rm deconcatenate2.txt

        #deconversion du signé
        deconvBase64 deconcatenate1.txt
        rm deconcatenate1.txt

        #vérification du signé et donc de l'identité
        verif=$(verificationSign deconv.txt server/key/"$ID"_public.pem $ID)
        if [ "$verif" == "1" ] ; then
            send $Client <<< "1"
            echo "Erreur : signé invérifiable" && exit 1 
        else
            send $Client <<< "0"
        fi
        rm deconv.txt

        #deconversion du chiffré
        deconvBase64 deconcatenate3.txt
        rm deconcatenate3.txt

        #dechiffrement du chiffré
        dechiffrementPubKey deconv.txt server/key/private_Server_key.pem
        rm deconv.txt

        #deconcatenation des infos
        deconcatenation decrypted_file.txt 
        #deconcatenate1.txt=IDProcu ; deconcatenate2.txt=tempProcu

        #verification de si l'utilisateur existe et prise en compte de la procuration 
        if [ $(existUser $(cat deconcatenate1.txt)) -eq 1 ]; then
            addInfo $(cat deconcatenate1.txt) $ID"$" col7

            #creation de la date à ajouter dans la 8e colonne en fonction du choix de l'utilisateur 
            case $(cat deconcatenate2.txt) in
                1)
                addInfo $(cat deconcatenate1.txt) $NextElection"$" col8
                ;;
                2)
                date=$(date -v+2y +"%d/%m/%Y")
                addInfo $(cat deconcatenate1.txt) $date"$" col8
                ;;
                3)
                date=$(date -v+3y +"%d/%m/%Y")
                addInfo $(cat deconcatenate1.txt) $date"$" col8
                ;;
            esac  
            send $Client <<< "ProcuOk"
        else
            echo "l'utilisateur n'existe pas"
            send $Client <<< "ProcuKo"
        fi

        #envoie de la reponse au client

        rm deconcatenate1.txt deconcatenate2.txt
        ;;
    "...")
        echo "..."
        ;;
    *)
        echo "erreur"
        ;;
    esac

    sleep 1
done



