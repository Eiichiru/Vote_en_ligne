#openssl genpkey -algorithm RSA -out private.pem
#openssl rsa -in private.pem -pubout -out public.pem
#openssl rand -hex 16

chiffrement() {
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

chiffrement message.txt public.pem
