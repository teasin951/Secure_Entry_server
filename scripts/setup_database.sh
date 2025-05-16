#!/bin/bash

#
# This script expects environmental variables to be set
#


# Get correct folder and file path
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FOLDER="${SCRIPT_DIR}/../postgresql/"
FILE="${FOLDER}/deploy_all.sql"


cd "$FOLDER"

# Execute deploy_all.sql file
psql -h "$DATABASE_HOSTNAME" -p "$DATABASE_PORT" -U "$DATABASE_USERNAME" -d "$DATABASE_NAME" -f "$FILE"

cd -