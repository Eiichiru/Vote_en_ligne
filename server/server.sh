#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh


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

        #déchiffrement
        dechiffrementSym encryptedSymKey.bin encryptedMessage.txt server/key/private_Server_key.pem
        echo "DEBUG: dechiffrement symetrique"
            
        #Suppression des fichiers inutiles 
        rm encryptedSymKey.bin encryptedMessage.txt

        #deconcatenation
        deconcatenation decrypted_message.txt
        rm decrypted_message.txt
        echo "DEBUG: deconcatenation"
        
        #deconcatenate1.txt=le signé ; deconcatenate2.txt=ID ; deconcatenate3.txt=typeconnexion ; deconcatenate4.txt= votechiffré en base64
        
        ID=$(cat deconcatenate2.txt)
        rm deconcatenate2.txt

        #deconversion du signé
        deconvBase64 deconcatenate1.txt
        # sign=$(cat deconv.txt)
        # rm deconv.txt
        echo "DEBUG: deconversion"

        #vérification du signé et donc de l'identité
        echo "sign : "$sign
        echo "ID : "$ID
        verif=$(verificationSign deconv.txt server/key/"$ID"_public.pem $ID)
        if [ "$verif" -eq 1 ] ; then
            send $Client <<< "1"
            echo "Erreur : signé invérifiable" && exit 1 
        else
            send $Client <<< "1"
        fi
        echo "DEBUG: identité verifié"
        rm deconv.txt
        
        #vérification de l'heure
        verif=$(verifHeure)
        if [ "$verif" -eq 1 ] ; then
            send $Client <<< "1"
            echo "Erreur : Heure non valide" && exit 1 
        else
            send $Client <<< "0"
        fi
        echo "DEBUG: heure verifié"

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
        if [ "$2" -eq 1 ] ; then
            
            #prise en compte du vrai vote 
            #nextStep : chiffrer avec clé public d'une instance au dessus
            cat deconcatenate4.txt > server/database/"$ville"_vote.txt
            rm deconcatenate4.txt
        else    
            #creation d'un vote blanc pour que le vote ne soit pas prit en compte
            #nextStep : chiffrer avec clé public d'une instance au dessus
            chiffrementPubKey VoteBlanc server/key/public_Server_key.pem
            cat encrypted_file.bin > server/database/"$ville"_vote.txt
            rm encrypted_file.bin
        fi
        echo "DEBUG: vote prit en compte"

        #ajout du hashé dans la database
        #a converir en base64
        addInfo $ID $hash col6 $ville
        echo "DEBUG: ajout fingerprint"

        #envoie de la reponse au client
        send $Client <<< "vote ok"
        
        continue
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


