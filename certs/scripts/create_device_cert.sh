#!/bin/bash

# Get to the correct folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIR="${SCRIPT_DIR}/../devices"
CA="${SCRIPT_DIR}/../ca/"


# Prompt the user
read -r -e -p "Client name: " CNAME
DEVICE="${DIR}/${CNAME}"
read -r -e -i "n" -p "Encrypt client key? [y/n]: " CENC
read -r -e -i "3650" -p "Client certificate validity in days: " CDAYS

# Create unencrypted key
if [ "$CENC" == "n" ] ; then
	if ! openssl genrsa -out "$DEVICE".key 2048 ; then
		rm "$DEVICE".key
		exit 1
	fi

# Create encrypted key
else 
	if ! openssl genrsa -aes256 -out "$DEVICE".key 2048 ; then
		rm "$DEVICE".key
		exit 1
	fi
fi

if ! openssl req -out "$DEVICE".csr -key "$DEVICE".key -new ||       # Generate cert singing request
   ! openssl x509 -req -in "$DEVICE".csr -CA "$CA"/ca.crt -CAkey "$CA"/ca.key -CAcreateserial -out "$DEVICE".crt -days "$CDAYS" || 
   ! openssl verify -CAfile "$CA"/ca.crt -verbose "$DEVICE".crt ; then       # Verify cert

	rm "$DEVICE".*  # Sometimes it creates files even though it fails
	exit 1
fi

rm "$DEVICE".csr  # Remove the request
