#!/bin/bash

# Get the correct folder
# CA split to prevent containers having access to the key 
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CADIR="${SCRIPT_DIR}/../ca"


# Check existance
if [ -f "$CADIR"/ca.crt ] || [ -f "$CADIR"/ca.key ]; then
	echo "Some CA files already exist"
	exit 2
fi


# Create CA
read -r -e -i "3650" -p "CA validity in days: " CADAYS
if ! openssl req -new -x509 -days "$CADAYS" -extensions v3_ca -keyout "$CADIR"/ca.key -out "$CADIR"/ca.crt ; then
	rm "$CADIR"/ca.*  # Sometimes it creates files even though it fails
	exit 1
fi
