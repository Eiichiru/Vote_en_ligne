#!/bin/bash

source fonction/utils.sh
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
        encrypted_password=$(recv $Server)

        #dechiffrement du mdp 
        MDP=$(dechiffrementMDP $encrypted_password publicKey/private_Server_key.pem)

        #reception de la ville
        ville=$(recv $Server)

        #fonction de verification id/mdp
        verifConnexion $ID $MDP $ville


        ;;
    "...")
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



