#!/bin/bash

# Get the correct folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIR="${SCRIPT_DIR}/../certs"


# Check existance
if [ -f "$DIR"/ca.crt ] || [ -f "$DIR"/ca.key ]; then
	echo "Some CA files already exist"
	exit 2
fi


# Create CA
read -r -e -i "3650" -p "CA validity in days: " CADAYS
if ! openssl req -new -x509 -days "$CADAYS" -extensions v3_ca -keyout "$DIR"/ca.key -out "$DIR"/ca.crt ; then
	rm "$DIR"/ca.*  # Sometimes it creates files even though it fails
	exit 1
fi
