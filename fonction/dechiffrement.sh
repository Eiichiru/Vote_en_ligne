#openssl genpkey -algorithm RSA -out private_key.pem
#openssl rsa -in private_key.pem -pubout -out public_key.pem
#openssl rand -hex 16

dechiffrement() {
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

dechiffrement encrypted_key.bin encrypted_message.txt private.pem

