#!/bin/bash

# Get to the correct folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIR="${SCRIPT_DIR}/../certs/clients"
CADIR="${SCRIPT_DIR}/../certs"


# Prompt the user
read -r -e -p "Client name: " CNAME
CLIENT="${DIR}/${CNAME}"
read -r -e -i "n" -p "Encrypt client key? [y/n]: " CENC
read -r -e -i "3650" -p "Client certificate validity in days: " CDAYS

# Create unencrypted key
if [ "$CENC" == "n" ] ; then
	if ! openssl genrsa -out "$CLIENT".key 2048 ; then
		rm "$CLIENT".key
		exit 1
	fi

# Create encrypted key
else 
	if ! openssl genrsa -aes256 -out "$CLIENT".key 2048 ; then
		rm "$CLIENT".key
		exit 1
	fi
fi

if ! openssl req -out "$CLIENT".csr -key "$CLIENT".key -new ||       # Generate cert singing request
   ! openssl x509 -req -in "$CLIENT".csr -CA "$CADIR"/ca.crt -CAkey "$CADIR"/ca.key -CAcreateserial -out "$CLIENT".crt -days "$CDAYS" || 
   ! openssl verify -CAfile "$CADIR"/ca.crt -verbose "$CLIENT".crt ; then       # Verify cert

	rm "$CLIENT".*  # Sometimes it creates files even though it fails
	exit 1
fi

