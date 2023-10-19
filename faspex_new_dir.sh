#!/bin/bash

if [ "$EUID" -ne 0 ]; then
	echo "Veuillez exécuter ce script en tant que superutilisateur (root)."
	exit
fi

# Base directory path
base_dir="/dataStore/home/faspex/packages/dropboxes"

# Prompt the user for folder names
echo "Enter the names of the folders to create (separated by spaces):"
read -r -a folder_names

# Iterate over the provided folder names
for folder_name in "${folder_names[@]}"; do
  full_dir_path="$base_dir/$folder_name"

  # Create the directory if it doesn't exist
  if [ ! -d "$full_dir_path" ]; then
	mkdir -p "$full_dir_path"
	echo "Created directory: $full_dir_path"
  else
	echo "Directory already exists: $full_dir_path"
  fi

  # Set ownership to faspex:faspex
  chown faspex:faspex "$full_dir_path"

  # Set permissions to 770
  chmod 770 "$full_dir_path"
done

echo "Directories created or already existed with the specified ownership and permissions."