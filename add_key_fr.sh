#!/bin/bash
#test Nova

if [ "$EUID" -ne 0 ]; then
	echo "Veuillez exécuter ce script en tant que superutilisateur (root)."
	exit
fi

# Liste des utilisateurs ayant des dossiers correspondants dans /dataStore/home/aspera/
liste_utilisateurs=($(find /dataStore/home/aspera -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

if [ ${#liste_utilisateurs[@]} -eq 0 ]; then
	echo "Aucun utilisateur avec un dossier correspondant trouvé dans /dataStore/home/aspera/."
	exit
fi

echo "Sélectionnez un utilisateur pour ajouter des clés RSA :"
for i in "${!liste_utilisateurs[@]}"; do
	echo "$((i+1)). ${liste_utilisateurs[i]}"
done

read -p "Entrez le numéro de l'utilisateur : " index_selectionne
index_selectionne=$((index_selectionne-1))

if [ $index_selectionne -lt 0 ] || [ $index_selectionne -ge ${#liste_utilisateurs[@]} ]; then
	echo "Sélection d'utilisateur non valide."
	exit
fi

utilisateur_selectionne="${liste_utilisateurs[index_selectionne]}"

read -p "Entrez les clés RSA séparées par des virgules : " cles_rsa

# Valider et formater les clés RSA
cles_valides=true
IFS=',' read -ra tableau_cles <<< "$cles_rsa"
for cle in "${tableau_cles[@]}"; do
	if [[ ! "$cle" =~ ^ssh-rsa[[:space:]] ]]; then
		echo "Les clés doivent être de type RSA (ssh-rsa). Veuillez réessayer."
		cles_valides=false
		break
	fi
done

if [ "$cles_valides" = false ]; then
	exit
fi

echo    # Empty line for spacing
# Ajouter les clés au fichier authorized_keys de l'utilisateur sélectionné
fichier_authorized_keys="/home/$utilisateur_selectionne/.ssh/authorized_keys"
for cle in "${tableau_cles[@]}"; do
	echo "$cle" >> "$fichier_authorized_keys"
done

echo "Clés RSA ajoutées pour l'utilisateur $utilisateur_selectionne."
