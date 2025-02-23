#!/bin/bash

#
#	This script serves as a quick and easy setup of a new KharonACS server
#
#	Many parts of this setup can be done using stand-alone scripts or
#	manualy if you know what you are doing
#



echo -e "\n ------------ TLS Setup ------------ "

echo "
----------------------------------------------------------------------
WARNING: It is important to use different certificate subject parameters for your CA, server and clients.

If the certificates appear identical, even though generated separately,the broker/client will not be able to distinguish between them and you will experience difficult to diagnose errors.
----------------------------------------------------------------------
"

echo -e "\n ---------- CA ---------- "
source ../mosquitto/scripts/create_CA.sh;

echo -e "\n -------- Server -------- "
source ../mosquitto/scripts/create_server_cert.sh;

echo -e "\n -------- Client -------- "
source ../mosquitto/scripts/create_client_cert.sh;
