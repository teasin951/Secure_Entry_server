#!/bin/bash


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FOLDER="${SCRIPT_DIR}/../postgresql/"
FILE="${FOLDER}/deploy_all.sql"

cd "$FOLDER"

psql -h "$DATABASE_HOSTNAME" -p "$DATABASE_PORT" -U "$DATABASE_USERNAME" -d "$DATABASE_NAME" -f "$FILE"

cd -