#!/bin/bash

if [ "$EUID" -ne 0 ]; then
	echo "Veuillez exécuter ce script en tant que superutilisateur (root)."
	exit
fi

read -p "Entrez le nom d'utilisateur : " username

# Lire et valider la ou les clés publiques fournies si l'utilisateur choisit d'en ajouter
read -p "Voulez-vous entrer la ou les clé(s) publique(s) RSA ? (o/N) : " enter_keys
if [[ "$enter_keys" =~ ^[Oo]$ ]]; then
	while true; do
		read -p "Entrez la ou les clé(s) publique(s) RSA SEULEMENT séparé(s) par une virgule : " provided_keys
		valid_keys=true
		
		# Séparer les clés fournies par des virgules
		IFS=',' read -ra keys_array <<< "$provided_keys"
		for key in "${keys_array[@]}"; do
			if [[ ! "$key" =~ ^ssh-rsa[[:space:]] ]]; then
				echo "Les clés doivent être de type RSA (ssh-rsa). Veuillez réessayer."
				valid_keys=false
				break
			fi
		done
		
		if [ "$valid_keys" = true ]; then
			break
		fi
	done
fi

# Répertoire contenant les fichiers de clés supplémentaires
additional_keys_dir="/etc/new_aspera_user/additional_keys"

# Combinez les clés fournies avec les clés supplémentaires provenant des fichiers
all_keys="${provided_keys}"

# Parcourir tous les fichiers .txt dans le répertoire
for additional_keys_file in "$additional_keys_dir"/*.txt; do
	while IFS= read -r key; do
		all_keys="${all_keys}
$key"
	done < "$additional_keys_file"
done

# Générer un mot de passe complexe
complex_password=$(openssl rand -base64 12)

# Créer un utilisateur avec le mot de passe généré
useradd -m -p $(echo "$complex_password" | openssl passwd -1 -stdin) $username
usermod -aG sshUsers $username
usermod -s /bin/aspshell $username

# Configuration SSH
mkdir -p /home/$username/.ssh
chown -R $username:$username /home/$username/
chmod 700 /home/$username/.ssh
echo -e "$all_keys" | tee /home/$username/.ssh/authorized_keys >/dev/null
chown $username:$username /home/$username/.ssh/authorized_keys
chmod 600 /home/$username/.ssh/authorized_keys

# Mettre à jour le groupe principal dans /etc/passwd
usermod -g 9001 $username

# Créer des répertoires et définir les autorisations
mkdir -p /dataStore/home/aspera/$username
chown $username:partners /dataStore/home/aspera/$username
chmod 770 /dataStore/home/aspera/$username

# Configurer l'utilisateur Aspera
asconfigurator_commands=(
	"set_user_data;user_name,$username;read_allowed,true"
	"set_user_data;user_name,$username;write_allowed,true"
	"set_user_data;user_name,$username;dir_allowed,true"
	"set_user_data;user_name,$username;absolute,/dataStore/home/aspera/$username"
)
for cmd in "${asconfigurator_commands[@]}"; do
	asconfigurator -x "$cmd"
done

# Vérifier l'intégrité du fichier de configuration
/opt/aspera/bin/asuserdata -v

# Définir la propriété de l'utilisateur pour le dossier de l'utilisateur dans /home/
chown -R $username:$username /home/$username

echo "Configuration terminée pour l'utilisateur $username."
