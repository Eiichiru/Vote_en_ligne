#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh

#Date Fixé arbritrairement pour les tests
NextElection="05/07/2023"

while true; do
    #reception du message envoyé par le client 
    echo "DEBUG : avant reception "
    MSG=$(recv $Server || echo "Erreur de reception !" >&2)
    echo "> Action : "$MSG
    case "$MSG" in
    "init connexion")
        #envoie de la clé public au client
        sendPublicKey

        #reception de L'ID
        ID=$(recv $Server)
        currentIDconnect=$ID

        #reception du mdp chiffré
        recv $Server > encrypted_password.txt

        #reception de la ville
        ville=$(recv $Server)

        #dechiffrement du mdp 
        MDP=$(dechiffrementPubKey encrypted_password.txt server/key/private_Server_key.pem)
        rm encrypted_password.txt

        #fonction de verification id/mdp
        verifConnexion $ID $MDP $ville

        typeConnexion=$(recv $Server)

        echo "DEBUG : connecté "
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
        if [ "$typeConnexion" == "1" ] ; then
            #prise en compte du vrai vote 
            #nextStep : chiffrer avec clé public d'une instance au dessus
            cat deconcatenate4.txt >> server/database/"$ville"_vote.txt
            rm deconcatenate4.txt
        else    
            #creation d'un vote blanc pour que le vote ne soit pas prit en compte
            #nextStep : chiffrer avec clé public d'une instance au dessus
            chiffrementPubKey VoteBlanc server/key/public_Server_key.pem
            convBase64 encrypted_file.bin
            cat base64.bin >> server/database/"$ville"_vote.txt
            rm encrypted_file.bin
            rm base64.bin
        fi
        echo "DEBUG: vote prit en compte"

        #convertion du hashé
        echo -n $hash > hash.txt

        #ajout du hashé dans la database
        addInfo $ID $(cat hash.txt) col6 $ville
        rm hash.txt

        echo "DEBUG: ajout fingerprint"

        #envoie de la reponse au client
        send $Client <<< "voteOk"
        
        rm deconcatenate3.txt
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
        dechif=$(dechiffrementPubKey deconv.txt server/key/private_Server_key.pem)
        rm deconv.txt
        echo -n $dechif > decripFile.txt

        #deconcatenation des infos
        deconcatenation decripFile.txt 
        #deconcatenate1.txt=IDProcu ; deconcatenate2.txt=tempProcu

        #verification de si l'utilisateur existe et prise en compte de la procuration
        result=$(existUser $(cat deconcatenate1.txt))

        city=$(getCitybyIDuser $(cat deconcatenate1.txt))

        if [ "$result" -eq 0 ]; then
            addInfo $(cat deconcatenate1.txt) $ID"-" col7 $city

            #creation de la date à ajouter dans la 8e colonne en fonction du choix de l'utilisateur 
            tempProcu=$(cat deconcatenate2.txt)
            case $tempProcu in
                1)
                addInfo $(cat deconcatenate1.txt) $NextElection"-" col8 $city
                ;;
                2)
                date=$(date -v+2y +"%d/%m/%Y")
                addInfo $(cat deconcatenate1.txt) $date"-" col8 $city
                ;;
                3)
                date=$(date -v+3y +"%d/%m/%Y")
                addInfo $(cat deconcatenate1.txt) $date"-" col8 $city
                ;;
            esac  
            send $Client <<< "ProcuOk"
        else
            echo "l'utilisateur n'existe pas"
            send $Client <<< "ProcuKo"
        fi

        #envoie de la reponse au client

        rm deconcatenate1.txt deconcatenate2.txt tempProcu.txt decrypted_key.txt decripFile.txt IDprocu.txt
        continue
        ;;
    "init voteProcu")
        #reception des chiffrés
        recv $Server > encryptedSymKey.bin
        recv $Server > encryptedMessage.txt

        echo "DEBUG : reception chiffré"
        #décapsulation
        dechiffrementSym encryptedSymKey.bin encryptedMessage.txt server/key/private_Server_key.pem
            
        #Suppression des fichiers inutiles 
        rm encryptedSymKey.bin encryptedMessage.txt

        #deconcatenation
        deconcatenation decrypted_message.txt
        rm decrypted_message.txt
        #deconcatenate1.txt=le signé ; deconcatenate2.txt=ID ; deconcatenate3.txt=IDprocu ; deconcatenate4.txt=procuration.txt (en base64); deconcatenate5.txt=chiffré du vote en base64
        
        #recuperation de L'ID
        ID=$(cat deconcatenate2.txt)
        rm deconcatenate2.txt

        #recuperation de L'ID procuration
        IDprocu=$(cat deconcatenate3.txt)

        #deconversion du signé
        deconvBase64 deconcatenate1.txt

        #vérification du signé et donc de l'identité
        verif=$(verificationSign deconv.txt server/key/"$ID"_public.pem $ID)
        if [ "$verif" == "1" ] ; then
            send $Client <<< "1"
            echo "Erreur : signé invérifiable" && exit 1 
        else
            send $Client <<< "0"
        fi
        rm deconv.txt

        #deconvertion de procuration.txt
        deconvBase64 procuration.txt

        #verification de procuration.txt
        verif=$(verificationSign deconv.txt server/key/"$IDprocu"_public.pem $IDprocu)
        if [ "$verif" == "1" ] ; then
            send $Client <<< "1"
            echo "Erreur : procuration invalid" && exit 1 
        else
            send $Client <<< "0"
        fi
        rm deconv.txt
        
        echo "DEBUG : verif procuration"
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
        verif=$(verifVote $IDprocu $ville)
        if [ "$verif" -eq 1 ] ; then
            send $Client <<< "1"
            echo "Erreur : La personne a déja voté" && exit 1 
        else
            send $Client <<< "0"
        fi

        echo "DEBUG : verif déja voté"
        #vérification de si la personne a réellement le droit de voter pour IDprocu
        verif=$(verifRightProcu $ID $ville $IDprocu $(date "+%d/%m/%Y"))
        if [ "$verif" -ne 0 ] ; then
            send $Client <<< "1"
            echo "Erreur : Pas les droits pour voter" && exit 1 
        else
            send $Client <<< "0"
        fi
        echo "DEBUG : verif right to vote"

        #creation du haché
        hash=$(cat deconcatenate4.txt | cut -c 1-15)
        rm deconcatenate.txt
        echo "DEBUG : hashé creation"

        #vérification de type de connexion 
        if [ "$typeConnexion" == "1" ] ; then
            #prise en compte du vrai vote 
            #nextStep : chiffrer avec clé public d'une instance au dessus
            cat deconcatenate4.txt >> server/database/"$ville"_vote.txt
            rm deconcatenate4.txt
            rm base64.bin
        else    
            #creation d'un vote blanc pour que le vote ne soit pas prit en compte
            #nextStep : chiffrer avec clé public d'une instance au dessus
            chiffrementPubKey VoteBlanc server/key/public_Server_key.pem
            convBase64 encrypted_file.bin
            cat base64.bin >> server/database/"$ville"_vote.txt
            rm encrypted_file.bin
            rm base64.bin
        fi
        echo "DEBUG : verif connexion type"

        echo -n $hash > hash.txt

        #ajout du hashé dans la database
        addInfo $IDprocu $(cat hash.txt) col6 $ville


        #envoie de la reponse au client
        send $Client <<< "voteOk"
        
        rm deconcatenate3.txt deconcatenate1.txt hash.txt deconcatenate5.txt
        rm decrypted_key.txt

        echo "INFO: Vote terminé"

        continue
        ;;
    "init urne")
        echo "DEBUG : start"
        echo "ID : "$currentIDconnect
        city=$(getCitybyIDuser $currentIDconnect)
        
        echo "DEBUG : Debut get urne"
        #parsing du fichier database
        getUrne $city
        echo "DEBUG : getUrne"

        #creation de la signature du server
        signature $currentIDconnect server/key/private_Server_Key.pem
        convBase64 signature.sign
        mv base64.bin signatures64.bin
        echo "DEBUG : create signature"

        #recuperation du nombre de vote
        cat urne.txt
        echo " --- "
        nbVote1=$(getNbVote $city)
        echo "DEBUG : getnbVote1"
        nbVote2=$(getNbVotebyUrne urne.txt)
        echo "DEBUG : getnbVote2"
        

        #verification
        if [ "$nbVote1" -ne "$nbVote2" ] ; then
            echo "ERREUR : nbVote non synchro"
            send $Client <<< "1"
            exit 1
        else
            send $Client <<< "0"
        fi
        echo "DEBUG : nbVote diff"

        echo -n $nbVote1 > nbVote.txt
        echo -n $currentIDconnect > ID.txt

        #conversion de l'urne en base64
        convBase64 urne.txt
        mv base64.bin urne64.bin
        rm urne.txt

        #concatenation
        concatenation signatures64.bin ID.txt urne64.bin nbVote.txt
        rm nbVote.txt ID.txt urne64.bin signatures64.bin
        echo "DEBUG : concatenation"

        #chiffrement
        chiffrementSym concatenateFile.txt server/key/"$currentIDconnect"_public.pem
        rm concatenateFile.txt
        echo "DEBUG : chiff"

        #envoie au client 
        cat encrypted_key.bin | send $Client
        cat encrypted_message.txt | send $Client
        echo "DEBUG : send to client"

        rm encrypted_key.bin
        rm encrypted_message.txt
        continue
        ;;
    "...")
        echo "..."
        continue
        ;;
    
    "init liste")

        #Reception de la ville
        ville=$(recv $Server || echo "Erreur de reception !" >&2)
        filename="server/database/"$ville"_database.txt"

        while IFS=":" read -r col1 col2 col3 col4 col5 col6 col7
        do
            if [[ "$col6" == "X" ]]; then
                col6="Pas de vote"
            else
                col6="A vote"
            fi

            echo "$col1 $col2 $col3 $col6" >> "tempDB.txt"
        done < "$filename"

        sleep 1
        send "$Client" < <(cat "tempDB.txt")
        rm tempDB.txt
        ;;

    *)
        echo "erreur"
        continue
        ;;
    
    
    esac

    sleep 1
done



