#!/bin/bash

source fonction/utils.sh
source fonction/fonctions.sh

echo "Veuillez indiquer le nom de la ville dont vous souhaitez voir la liste électorale"

read ville

#Initialisation de la demande de la liste electorale
send $Server <<< "init liste"
echo $ville | send $Server

recv $Client



