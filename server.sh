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
        MDP=$(dechiffrementMDP encrypted_password.txt publicKey/private_Server_key.pem)
        rm encrypted_password.txt

        echo "DEBUG > ID : "$ID
        echo "DEBUG > MDP : "$MDP
        echo "DEBUG > ID : "$ville
        #fonction de verification id/mdp
        verifConnexion $ID $MDP $ville

        continue
        ;;
    "init vote")
        echo "..."
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



