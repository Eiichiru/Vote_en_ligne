chiffrement() {
    if [ $# -ne 2 ]; then
        echo "La fonction attend exactement 2 arguments."
        return 1
    fi

    message=$1 #message qui est la concaténation de X+Vote
    serverPubKey=$2
    iv="6a0cd1c23b6319e2a97fcc5a60be848e"
    delimiteur="|"

    #Génération du random (clé symétrique)
    symKey=$(openssl rand -hex 32) 

    #Chiffrement du message avec la clé symétrique 
    messageChif=$(echo -n $message | openssl enc -aes-256-cbc -K $symKey -iv $iv) 

    #Chiffrement de la clé symetrique avec la clé publique du serveur 
    symKeyChif=$(echo -n $symKey | openssl rsautl -encrypt -pubin -inkey $serverPubKey)  
    
    resultat=$messageChif$delimiteur$symKeyChif
    echo $resultat

}

resultat=$(chiffrement message.txt public_ssh_key.pub)
echo $resultat
