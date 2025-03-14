#!/bin/bash

# Get to the correct folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIR="${SCRIPT_DIR}/../certs"


# Check existance
if [ -f "$DIR"/server.crt ] || [ -f "$DIR"/server.key ] || [ -f "$DIR"/server.crt ]; then
	echo "Some server files already exist"
	exit 2
fi


# Warnings 
# https://mosquitto.org/man/mosquitto-tls-7.html
# https://mosquitto.org/man/mosquitto_sub-1.html
echo -e "
----------------------------------------------------------------------
When prompted for the CN (Common Name), please enter either your server (or broker) hostname or domain name. 

Without it, and the corresponding DNS record, you will not be able to connect without disabling the verification of the server hostname in the server certificate. If you need to resort to using this option in a production environment, your setup is at fault and there is no point in using encryption.
----------------------------------------------------------------------
"


# Create server key and cert
read -r -e -i "3650" -p "Server certificate validity in days: " CDAYS
if ! openssl genrsa -out "$DIR"/server.key 2048 ||                    # Generate server key
   ! openssl req -out "$DIR"/server.csr -key "$DIR"/server.key -new ||       # Generate cert singing request
   ! openssl x509 -req -in "$DIR"/server.csr -CA "$DIR"/ca.crt -CAkey "$DIR"/ca.key -CAcreateserial -out "$DIR"/server.crt -days "$CDAYS" ||       # Send request to CA
   ! openssl verify -CAfile "$DIR"/ca.crt -verbose "$DIR"/server.crt ; then       # Verify cert

	rm "$DIR"/server.*  # Sometimes it creates files even though it fails
	exit 1
fi

rm server.csr  # Remove the request