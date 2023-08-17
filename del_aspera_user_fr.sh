#!/bin/bash

# Vérifier si le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script en tant que superutilisateur (sudo)."
  exit 1
fi

# Obtenir la liste des utilisateurs ayant un dossier dans /dataStore/home/aspera/
user_list=($(ls -1 /dataStore/home/aspera/))

# Afficher la liste des utilisateurs disponibles
echo "Utilisateurs ayant un dossier dans /dataStore/home/aspera/ :"
for user in "${user_list[@]}"; do
  echo "- $user"
done

# Demander le nom de l'usager à supprimer
read -p "Entrez le nom de l'usager à supprimer parmi la liste ci-dessus : " username

# Afficher les actions détaillées
echo -e "\nVous êtes sur le point d'effectuer les opérations suivantes pour l'usager $username :\n"
echo "- Suppression de l'usager $username de la configuration d'Aspera"
echo "- Suppression de l'usager $username du système Linux ainsi que de son répertoire personnel"
echo "- Suppression du groupe $username"
echo "- Suppression du répertoire /dataStore/home/aspera/$username"
echo "- Vérification de l'intégrité du fichier de configuration d'Aspera"

# Demander confirmation à l'utilisateur
read -p "Voulez-vous continuer ? (oui/non) : " confirm

if [[ "$confirm" != "oui" ]]; then
  echo "Opération annulée."
  exit 0
fi

# Supprimer l'usager de Cassandra
asconfigurator -x "delete_user;user_name,$username"

# Supprimer l'usager Linux et son répertoire personnel
userdel -r $username 2>/dev/null

# Supprimer le groupe portant le même nom que l'usager, en supprimant le message d'erreur
groupdel $username

# Supprimer le répertoire
rm -rf /dataStore/home/aspera/$username

# Vérifier l'intégrité du fichier de configuration
/opt/aspera/bin/asuserdata -v
