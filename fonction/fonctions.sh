source fonction/utils.sh

#openssl genpkey -algorithm RSA -out private.pem
#openssl rsa -in private.pem -pubout -out public.pem
#openssl rand -hex 16
chiffrementSym() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 1
    fi

    iv="6a0cd1c23b6319e2a97fcc5a60be848e"

    #Génération du random (clé symétrique)
    openssl rand -hex 16 > symKey.txt

    #Chiffrement de la clé symetrique avec la clé publique du serveur 
    openssl rsautl -encrypt -pubin -inkey $2 -in symKey.txt -out encrypted_key.bin
    symKey=$(cat symKey.txt)

    #Chiffrement du message avec la clé symétrique 
    openssl enc -aes-256-cbc -K $symKey -iv $iv -in $1 -out encrypted_message.txt

    #Suppression des fichiers inutiles
    rm symKey.txt
}
#chiffrementSym fichierConcatener.txt public.pem

dechiffrementSym() {
    if [ $# -ne 3 ]; then
        echo "La fonction attend exactement 3 arguments."
        return 1
    fi

    iv="6a0cd1c23b6319e2a97fcc5a60be848e"

    #Dechiffrement de la clé symetrique avec la clé privé du serveur 
    openssl rsautl -decrypt -inkey $3 -in $1 -out decrypted_key.txt
    symKey=$(cat decrypted_key.txt)

    #Dechiffrement du message avec la clé symétrique 
    openssl enc -d -aes-256-cbc -K $symKey -iv "$iv" -in $2 -out decrypted_message.txt
    #cat decrypted_message.txt

}
#dechiffrement encrypted_key.bin encrypted_message.txt private.pem

sendPublicKey() {
    #Creation des clés si elles n'existes pas 
    if [ ! -f "server/key/private_Server_key.pem" ]; then
        openssl genpkey -algorithm RSA -out server/key/private_Server_key.pem
    fi 
    if [ ! -f "server/key/public_ssh_key.pub" ]; then
        openssl rsa -in server/key/private_Server_key.pem -pubout -out server/key/public_Server_key.pem
    fi 

    #envoie de la clé public du server au client 
    cat server/key/public_Server_key.pem | send $Client
    echo "clé envoyé au client"

}

chiffrementPubKey() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi

    echo $1 > filetochif.txt

    #Chiffrement du mdp avec la clé publique du serveur 
    openssl rsautl -encrypt -pubin -inkey $2 -in filetochif.txt -out encrypted_file.bin

    rm filetochif.txt
}
#chiffrementPubKey $MDP public.pem

dechiffrementPubKey() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi

    #Dechiffrement de la clé symetrique avec la clé privé du serveur 
    openssl rsautl -decrypt -inkey $2 -in $1 -out decrypted_file.txt

    cat decrypted_file.txt
    rm decrypted_file.txt
}
#chiffrement encrypted_file.txt publicKey/private_Server_key.pem

verifConnexion() {
    if [ $# -ne 3 ]; then
        echo "La fonction attend exactement 3 arguments."
        return 2
    fi
    cat server/database/"$3"_database.txt | while read -r ligne
    do
        IDinFile=$(echo "$ligne" | cut -d ':' -f1)
        MDPinFile=$(echo "$ligne" | cut -d ':' -f9)
        if [ "$IDinFile" = "$1" ] ; then
            if [ "$IDinFile" = "$1" ] && [ "$MDPinFile" = "$2" ]; then
                send $Client <<< "connexion1"
            else
                MDPinFile=$(echo "$ligne" | cut -d ':' -f10)
                if [ "$IDinFile" = "$1" ] && [ "$MDPinFile" = "$2" ]; then
                    send $Client <<< "connexion2"
                else
                    send $Client <<< "connexion3"
                fi
            fi
        fi
    done

}
#verifConnexion $ID $MDP $ville

signature() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi

    echo -n "$1" | openssl dgst -sign "$2" -keyform PEM -sha256 -out signature.sign

    #echo $signature

}
#signature $dataToSign $clientPrivateKey

verificationSign() {
    if [ $# -ne 3 ]; then
        echo "La fonction attend exactement 3 arguments."
        return 2
    fi

    echo -n "$3" | openssl dgst -verify "$2" -keyform PEM -sha256 -signature "$1"

    return $?
}
#verificationSign signedData.txt clientpublicKey.pem #IDClient


convBase64() {
    cat $1 | base64 > base64.bin
}
#convBase64 fileToConv.txt

deconvBase64() {
    cat $1 | base64 -d > deconv.txt
}
#deconvBase64 fileToDeconv.txt

concatenation() {
    start_marker="#!START#!"
    end_marker="#!END#!"

    for file in $*
    do
        echo -n $start_marker >> concatenateFile.txt
        cat $file >> concatenateFile.txt
        echo -n $end_marker >> concatenateFile.txt
    done
}
#concatenation file1.txt file2.txt ... filen.txt

deconcatenation() {
    start_marker="#!START#!"
    end_marker="#!END#!"

    #recuperation du nombre de fichier qui ont été concatené 
    nbFile=$(grep -o '#!START#!' $1 | wc -l | sed 's/ //g')
    
    #recupation de chaque partie 
    for (( i=1; i<=$nbFile; i++ ))
    do  
        awk -v RS="$end_marker" '/'"$start_marker"'/{print substr($0, length("'"$start_marker"'")+1)}' <<< $(cat $1) | awk 'NR=='$i > deconcatenate$i.txt
    done
    

}
#deconcatenation concatenateFile.txt 

verifHeure() {
    heure=$(date +%H) 

    if (( heure >= 8 && heure < 20 )); then
        echo 0 
    else
        echo 1 
    fi
}
#verifHeure

verifVote() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi
    cat server/database/"$2"_database.txt | while read -r ligne
    do
        IDinFile=$(echo "$ligne" | cut -d ':' -f1)
        fingerprint=$(echo "$ligne" | cut -d ':' -f6)
        if [ "$IDinFile" = "$1" ] ; then
            if [ "$fingerprint" = "X" ] ; then
                echo 0
            else
                echo 1
            fi
        fi
    done
}
#verifVote $ID $ville

addInfo() {
    file="server/database/"$4"_database.txt"
    search_id=$1
    new_data=$2

    # Création d'un fichier temporaire pour stocker les modifications
    temp_file=$(mktemp)

    # Parcours du fichier et mise à jour de la ligne appropriée
    cat "$file" | while IFS=: read -r col1 col2 col3 col4 col5 col6 col7 col8 col9 col10; do
        if [ "$col1" = "$search_id" ]; then
            case $3 in
            "col2")
                col2=$2
                ;;
            "col3")
                col3=$2
                ;;
            "col4")
                col4=$2
                ;;
            "col5")
                col5=$2
                ;;
            "col6")
                col6=$2
                ;;
            "col7")
                col7=$2
                ;;
            "col8")
                col8=$2
                ;;
            "col9")
                col9=$2
                ;;
            "col10")
                col10=$2
                ;;
            esac
        fi
        echo "$col1:$col2:$col3:$col4:$col5:$col6:$col7:$col8:$col9:$col10" >> "$temp_file"
    done

    # Remplacement du fichier d'origine par le fichier temporaire modifié
    mv "$temp_file" "$file"
}
#addInfo $ID $InfoToAdd $numColonne(/!\ Format colX) $ville

existUser() {
    for fichier in server/database/*_database.txt; do
        cat "$fichier" | while read -r ligne
        do
            premiere_colonne=$(echo "$ligne" | cut -d ':' -f1)
            if [ "$premiere_colonne" = "$1" ]; then
                echo 0
                break 
            fi
        done
    done
}
#existUser IDProcu 

getCitybyIDuser() {
    for fichier in server/database/*_database.txt; do
        cat "$fichier" | while read -r ligne
        do
            premiere_colonne=$(echo "$ligne" | cut -d ':' -f1)
            if [ "$premiere_colonne" = "$1" ]; then
                temp=$(echo "$fichier" | cut -d '_' -f1)
                city=$(echo "$temp" | cut -d '/' -f3)
                echo $city
            fi
        done
    done
}
#getCitybyIDuser $ID

verifRightProcu() {
    if [ $# -ne 4 ]; then
        echo "La fonction attend exactement 4 arguments."
        return 2
    fi
    cat server/database/"$2"_database.txt | while read -r ligne
    cpt=0
    do
        IDinFile=$(echo "$ligne" | cut -d ':' -f1)
        if [ "$IDinFile" = "$1" ] ; then
            IDprocuInFile=$(echo "$ligne" | cut -d ':' -f7)
            DateprocuInFile=$(echo "$ligne" | cut -d ':' -f8)
            IFS='-' read -ra ids <<< "$IDprocuInFile"
            IFS='-' read -ra dates <<< "$DateprocuInFile"
            for id in "${ids[@]}"; do
                if [ "$id" = "$3" ]; then
                    #echo "id : "$id
                    #echo "date : "${dates[$cpt]} 
                    num_date1=$(date -j -f "%d/%m/%Y" "$4" +"%s")
                    num_date2=$(date -j -f "%d/%m/%Y" "${dates[$cpt]}" +"%s")
                    
                    if [ "$num_date1" -le "$num_date2" ]; then
                        echo 0
                        exit 0
                    fi 
                fi
                ((cpt++))
            done
        fi
    done
}
#verifRightProcu $ID $ville $IDprocu date

