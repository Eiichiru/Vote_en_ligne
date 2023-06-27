#!/bin/bash

source fonction/utils4mac.sh
source fonction/fonctions.sh

getUrne amiens

nbVote1=$(getNbVote amiens)
echo "nb 1 : "$nbVote1

nbVote2=$(getNbVotebyUrne urne.txt)
echo "nb 2 : "$nbVote2