#!/bin/bash

#
#	This script serves as a quick and easy setup of a new KharonACS server
#

# echo "
# ----------------------------------------------------------------------
# WARNING: This script creates the most basic setup where all keys are stored on the server, thus the entire security of this system depends on the security of this server and it's hard drives. If you want to have a more elaborate setup, as of right now, you will have to do it manually.
# ----------------------------------------------------------------------
# "

# echo -e "\n ------------ Site Setup ------------ "


# Make sure everything is called correctly
cd "$(dirname "$0")" || exit 2


echo -e "\n ------------ TLS Setup ------------ "
echo "
----------------------------------------------------------------------
NOTE: It is important to use different certificate subject parameters for your CA, server and clients.

If the certificates appear identical, even though generated separately,the broker/client will not be able to distinguish between them and you will experience difficult to diagnose errors.
----------------------------------------------------------------------
"

echo -e "\n ---------- CA ---------- "
source ../mosquitto/scripts/create_CA.sh || exit 1

echo -e "\n -------- Server -------- "
source ../mosquitto/scripts/create_server_cert.sh || exit 1

echo -e "\n -------- Client -------- "
source ../mosquitto/scripts/create_client_cert.sh || exit 1


echo -e "\n ------------ Mosquitto DynSec setup ------------ "
docker compose up -d mosquitto || exit 1
docker exec -i mosquitto mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json admin-user || exit 1
docker compose down
docker compose up -d
