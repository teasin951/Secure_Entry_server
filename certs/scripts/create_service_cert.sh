#!/bin/bash

# Get to the correct folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIR="${SCRIPT_DIR}/../event_service/"
CADIR="${SCRIPT_DIR}/../ca/"


# Check existance
if [ -f "$DIR"/service.crt ] || [ -f "$DIR"/service.key ]; then
	echo "Some service files already exist"
	exit 2
fi

# Check CA exists 
if ! [ -f "$CADIR"/ca.crt ] || ! [ -f "$CADIR"/ca.key ]; then
	echo "CA files do not exist"
	exit 3
fi

# Copy CA cert to service folder
cp "$CADIR"/ca.crt "$DIR"


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
read -r -e -i "3650" -p "Event service certificate validity in days: " CDAYS
if ! openssl genrsa -out "$DIR"/service.key 2048 ||                    # Generate server key
   ! openssl req -out "$DIR"/service.csr -key "$DIR"/service.key -new ||       # Generate cert singing request
   ! openssl x509 -req -in "$DIR"/service.csr -CA "$CADIR"/ca.crt -CAkey "$CA"/ca.key -CAcreateserial -out "$DIR"/service.crt -days "$CDAYS" ||       # Send request to CA
   ! openssl verify -CAfile "$CA"/ca.crt -verbose "$DIR"/service.crt ; then       # Verify cert

	rm "$DIR"/service.*  # Sometimes it creates files even though it fails
	exit 1
fi

rm "$DIR"/service.csr  # Remove the request

