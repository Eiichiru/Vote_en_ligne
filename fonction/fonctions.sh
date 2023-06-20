source fonction/utils4mac.sh

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
#chiffrement message.txt public.pem

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
    cat decrypted_message.txt

    #Suppression des fichiers inutiles 
    rm encrypted_message.txt 
    rm encrypted_key.bin

}
#dechiffrement encrypted_key.bin encrypted_message.txt private.pem

sendPublicKey() {
    #Creation des clés si elles n'existes pas 
    if [ ! -f "publicKey/private_Server_key.pem" ]; then
        openssl genpkey -algorithm RSA -out publicKey/private_Server_key.pem
    fi 
    if [ ! -f "public_ssh_key.pub" ]; then
        openssl rsa -in publicKey/private_Server_key.pem -pubout -out publicKey/public_Server_key.pem
    fi 

    #envoie de la clé public du server au client 
    cat publicKey/public_Server_key.pem | send $Client
    echo "clé envoyé au client"

}

chiffrementMDP() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi

    echo $1 > mdp.txt

    #Chiffrement du mdp avec la clé publique du serveur 
    openssl rsautl -encrypt -pubin -inkey $2 -in mdp.txt -out encrypted_password.bin

    rm mdp.txt
}
#chiffrement $MDP public.pem

dechiffrementMDP() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi

    #Dechiffrement de la clé symetrique avec la clé privé du serveur 
    openssl rsautl -decrypt -inkey $2 -in $1 -out decrypted_password.txt

    cat decrypted_password.txt
    rm decrypted_password.txt
}
#chiffrement encrypted_password.txt publicKey/private_Server_key.pem

verifConnexion() {
    if [ $# -ne 3 ]; then
        echo "La fonction attend exactement 3 arguments."
        return 2
    fi
    cat database/"$3"_database.txt | while read -r ligne
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

    echo $signature

}
#signature $dataToSign $clientPrivateKey

verification() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 2
    fi

    echo -n "$3" | openssl dgst -verify "$2" -keyform PEM -sha256 -signature "$1"

    echo $?
}
#verification $signedData $clientpublicKey #IDClient

chiffrementConcatenation() {
    start_marker="#!START#!"
    end_marker="#!END#!"

    # Chiffrer la première donnée
    openssl rsautl -encrypt -pubin -inkey ../key/public.pem -in text.txt -out encrypted_text.bin
    cat encrypted_text.bin | base64 > base64_1.bin
    rm encrypted_text.bin

    # Chiffrer la deuxième donnée
    openssl rsautl -encrypt -pubin -inkey ../key/public.pem -in text2.txt -out encrypted_text2.bin
    cat encrypted_text2.bin | base64 > base64_2.bin
    rm encrypted_text2.bin

    # Concaténer les deux textes chiffrés
    echo -n $start_marker >> concatenateFile.txt
    cat base64_1.bin >> concatenateFile.txt
    echo -n $end_marker >> concatenateFile.txt
    echo -n $start_marker >> concatenateFile.txt
    cat base64_2.bin >> concatenateFile.txt
    echo -n $end_marker >> concatenateFile.txt
}
#chiffrementConcatenation fichier1.txt fichier2.txt

dechiffrementConcatenation() {
    start_marker="#!START#!"
    end_marker="#!END#!"

    #recupere la partie 1
    awk -v RS="$end_marker" '/'"$start_marker"'/{print substr($0, length("'"$start_marker"'")+1)}' <<< $(cat concatenateFile.txt) | awk 'NR==1' > deconcatenate1.txt
    cat deconcatenate1.txt | base64 -d | openssl rsautl -decrypt -inkey ../key/private.pem > decrypted1.txt
    rm deconcatenate1.txt

    #recupere la partie 2
    awk -v RS="$end_marker" '/'"$start_marker"'/{print substr($0, length("'"$start_marker"'")+1)}' <<< $(cat concatenateFile.txt) | awk 'NR==2' > deconcatenate2.txt
    cat deconcatenate2.txt | base64 -d | openssl rsautl -decrypt -inkey ../key/private.pem > decrypted2.txt
    rm deconcatenate2.txt

    rm base64_1.bin
    rm base64_2.bin
    rm concatenateFile.txt

}
#dechiffrementConcatenation() concatenateFile.txt