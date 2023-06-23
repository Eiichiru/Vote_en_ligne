#!/bin/bash

source fonction/utils.sh
source fonction/fonctions.sh


echo "Verification de votre clé de chiffrement personnelle ...
(On verifie que la clé USB fournie est bien branchée)

Clé personnelle valide !

A qui souhaitez vous donner votre procurations ?
Son ID unique :"
read IDprocu
echo Son prenom :
read prenom
echo Son nom :
read nom
echo "Pendant combien de temps "$prénom $nom" 
aura t-il le droit de voter pour vous ? 
1 : La prochaine élection
2 : 2 ans
3 : 3 ans"

read tempsProcu
