#!/bin/bash

# Redirect output to a log file
exec > >(tee -a /var/log/faspex_upgrade.log) 2>&1

# Exit immediately if a command exits with a non-zero status
set -e

if [ "$EUID" -ne 0 ]; then
	echo "Error: This script must be run as a sudoer (root)."
	exit 1
fi

# Define patch path
patch_path="/home/fgladu"

# Confirm Faspex version
#current_version=$(asctl faspex:version)
#required_version="4.4.2.185316"

#if [[ "$current_version" != "$required_version" ]]; then
#	echo "Error: Current Faspex version ($current_version) does not match the required version ($required_version)."
#	exit 1
#fi

# Stop all services
echo "Stopping all services..."
asctl all:stop
echo "Services stopped successfully."

# Backup common and faspex folders
echo "Backing up common and faspex folders..."
/bin/cp -r /opt/aspera/common /home/fgladu/aspera_4.4.2PL3/common
/bin/cp -r /opt/aspera/faspex /home/fgladu/aspera_4.4.2PL3/faspex
echo "Backup completed successfully."

# Replace existing files with patch files
echo "Applying patch files..."
/bin/cp -r "$patch_path/IBM_Aspera_Faspex_4.4.2_Linux_Patch_Level_4/common/*" /opt/aspera/common/
/bin/cp -r "$patch_path/IBM_Aspera_Faspex_4.4.2_Linux_Patch_Level_4/faspex/*" /opt/aspera/faspex/
echo "Patch applied successfully."

# Start MySQL
echo "Starting MySQL..."
asctl mysql:start
echo "MySQL started successfully."

# Run Apache setup and upgrade Apache
echo "Setting up and upgrading Apache..."
asctl apache:setup
asctl apache:upgrade
echo "Apache setup and upgrade completed successfully."

# Change ownership of the /opt/aspera/faspex folder
echo "Changing ownership of the faspex folder..."
cd /opt/aspera/
chown -R faspex:faspex faspex
echo "Ownership changed successfully."

# Run database schema migration
echo "Running database schema migration..."
asctl faspex:migrate_database
echo "Database schema migration completed successfully."

echo "Faspex has been successfully upgraded to version $required_version."
