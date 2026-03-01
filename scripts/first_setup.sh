#!/bin/bash

#
#	This script serves as a quick and easy setup of a new server
#

# echo "
# ----------------------------------------------------------------------
# WARNING: This script creates the most basic setup where all keys are stored on the server, thus the entire security of this system depends on the security of this server and it's hard drives. If you want to have a more elaborate setup, as of right now, you will have to do it manually.
# ----------------------------------------------------------------------
# "

# echo -e "\n ------------ Site Setup ------------ "


# Make sure everything is called correctly
cd "$(dirname "$0")" || exit 2

echo "

Welcome to the Eleados server initial setup. 

This script should be used for first setup only, if you need to modify the setup of an already initialized server, please use the individual scripts or commands provided.



"


# Make sure we are ready to create containers
read -r -e -p "Have you already prepared the 'docker_compose.yml' file? y/N: " PREP 
if [ "$PREP" != "y" ] ; then
	echo "Then go ahead and set all environmental variables that need changing first."
	exit 0
fi


echo -e "\n ------------ TLS Setup ------------ "
echo "
----------------------------------------------------------------------
NOTE: It is important to use different certificate subject parameters for your CA, server and clients.

If the certificates appear identical, even though generated separately, the broker/client will not be able to distinguish between them and you will experience difficult to diagnose errors.
----------------------------------------------------------------------
"

echo -e "\n ---------- CA ---------- "
source ../certs/scripts/create_CA.sh || exit 1

echo -e "\n -------- Mosquitto -------- "
source ../certs/scripts/create_mosquitto_cert.sh || exit 1

echo -e "\n -------- Event service -------- "
source ../certs/scripts/create_service_cert.sh || exit 1


echo -e "\n ------------ Mosquitto DynSec setup ------------ "
docker compose up -d mosquitto || exit 1
docker exec -i mosquitto mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json admin || exit 1
docker compose restart mosquitto
source setup_dynsec.sh


echo -e "\n ------------ Database setup ------------ "
docker compose up -d postgres
docker exec -it -w /etc/eleados postgres psql -U admin -f /etc/eleados/deploy_all.sql


echo -e "\n ------------ Event service setup ------------ "
docker compose up -d


echo "

---
The server should now be up and running. You should now create certificates for your devices using the script certs/scripts/create_device_cert.sh
"
