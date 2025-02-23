#!/bin/bash

#
# Create or replace current site configuration
#
# You should only replace the current configuration if you know what you are doing
# This script is not intended to update the configuration on its own
#

# Get the correct folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DATADIR="${SCRIPT_DIR}/../data"
KEYDIR="${SCRIPT_DIR}/../keys"


if [ -f "$KEYDIR"/APPMOK.key ]; then
	read -rei "n" -p "WARNING: APPMOK already exists, regenerate? [y/n]: " ANSW
	if [ "$ANSW" == "y" ] ; then
		# .old can be useful for key rotation if ever implemented
		mv "$KEYDIR"/APPMOK.key "$KEYDIR"/APPMOK.key.old
		openssl rand 128 > "$KEYDIR"/APPMOK.key
	fi
fi

if [ -f "$KEYDIR"/APPVOK.key ]; then
	read -rei "n" -p "WARNING: APPVOK already exists, regenerate? [y/n]: " ANSW
	if [ "$ANSW" == "y" ] ; then
		mv "$KEYDIR"/APPVOK.key "$KEYDIR"/APPVOK.key.old
		openssl rand 128 > "$KEYDIR"/APPVOK.key
	fi
fi

if [ -f "$KEYDIR"/OCPSK.key ]; then
	read -rei "n" -p "WARNING: OCPSK already exists, regenerate? [y/n]: " ANSW
	if [ "$ANSW" == "y" ] ; then
		mv "$KEYDIR"/OCPSK.key "$KEYDIR"/OCPSK.key.old
		openssl rand 128 > "$KEYDIR"/OCPSK.key
	fi
fi


if [ -f "$DATADIR"/CardID.bin ]; then
	read -rei "n" -p "WARNING: CardID already exists, regenerate? [y/n]: " ANSW
	if [ "$ANSW" == "y" ] ; then
		mv "$DATADIR"/CardID.bin "$DATADIR"/CardID.bin.old
		python3 card_id.py
	fi
fi

if [ -f "$DATADIR"/PACS.bin ]; then
	read -rei "n" -p "WARNING: PACS object already exists, regenerate? [y/n]: " ANSW
	if [ "$ANSW" == "y" ] ; then
		mv "$DATADIR"/PACS.bin "$DATADIR"/PACS.bin.old
		python3 pacs_obj.py
	fi
fi
