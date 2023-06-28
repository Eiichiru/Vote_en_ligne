#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh

nbAlice=0
nbBob=0
nbEve=0
nbBlanc=0

# Pour chaque fichier de vote existant (pour chaque ville)
for fileVote in server/database/*_vote.txt; do
    # Pour chaque ligne (pour chaque vote)
    while read -r vote64
    do
        echo -n "$vote64" > vote64.txt

        # Déconversion du vote
        deconvBase64 vote64.txt

        # Déchiffrement avec clé privée server
        vote=$(dechiffrementPubKey deconv.txt server/key/private_Server_Key.pem)

        rm vote64.txt deconv.txt

        case "$vote" in
            "1")
                ((nbAlice++))
                echo "+1 voix pour Alice"
            ;;
            "2")
                ((nbBob++))
                echo "+1 voix pour Bob"
            ;;
            "3")
                ((nbEve++))
                echo "+1 voix pour Eve"
            ;;
            "4")
                ((nbBlanc++))
                echo "Vote Blanc"
            ;;
            *)
            echo "Vote non pris en compte"
            ;;
        esac
    done < "$fileVote"
done

echo "$nbAlice"
echo "$nbBob"
echo "$nbEve"

if [ "$nbAlice" -eq "$nbBob" ] ; then
    echo "egalité"
    exit 1
fi
if [ "$nbAlice" -eq "$nbEve" ] ; then
    echo "egalité"
    exit 1
fi
if [ "$nbEve" -eq "$nbBob" ] ; then
    echo "egalité"
    exit 1
fi

gagnant="erreur"
if [ "$nbAlice" -gt "$nbBob" ] && [ "$nbAlice" -gt "$nbEve"] ; then
    gagnant="Alice"
else
    if [ "$nbBob" -gt "$nbAlice" ] && [ "$nbBob" -gt "$nbEve" ] ; then
        gagnant="Bob"
    else
        gagnant="Eve"
    fi
fi



echo ">Resultat : 
Le gagnant est $gagnant.
Il y a eu $nbBlanc votes blanc"