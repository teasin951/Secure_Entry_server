#!/bin/bash

#
# This scripts set basic DynSec ACLs for the server to operate
#
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CERT_DIR="${SCRIPT_DIR}/../certs/"

echo -e "--- Might require sudo if it can't find files or you have to generate them ---"


docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' event_service > .tmp_env || ( rm .tmp_env && echo "You probably wouldn't guess so but the event_service has to be running for this to work :)" && exit 2 )
sed 's/=\(.*\)/="\1"/' .tmp_env > .tmp_env2 && source .tmp_env2 && rm .tmp_env .tmp_env2

SERVICE_ROLE="$SERVICE_MQTT_USERNAME""_role"
SERVICE_CERT_FILE_PATH="${CERT_DIR}/event_service/service.crt"
SERVICE_KEY_FILE_PATH="${CERT_DIR}/event_service/service.key"
MOSQUITTO_CA_FILE_PATH="${CERT_DIR}/mosquitto/ca.crt"


mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec createClient "$SERVICE_MQTT_USERNAME"  || exit 1
mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec createRole "$SERVICE_ROLE"  || exit 2


mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addRoleACL "$SERVICE_ROLE" subscribePattern "reader/#" allow 5  || exit 3
mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addRoleACL "$SERVICE_ROLE" publishClientSend "reader/#" allow 5  || exit 3

mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addRoleACL "$SERVICE_ROLE" subscribePattern "registrator/#" allow 5  || exit 3
mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addRoleACL "$SERVICE_ROLE" publishClientSend "registrator/#" allow 5  || exit 3

mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addRoleACL "$SERVICE_ROLE" subscribePattern "whitelist/#" allow 5  || exit 4
mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addRoleACL "$SERVICE_ROLE" publishClientSend "whitelist/#" allow 5  || exit 4


mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addClientRole "$SERVICE_MQTT_USERNAME" "$SERVICE_ROLE" 5  || exit 5
mosquitto_ctrl --cafile "$MOSQUITTO_CA_FILE_PATH" --cert "$SERVICE_CERT_FILE_PATH" --key "$SERVICE_KEY_FILE_PATH" -u "$MOSQUITTO_DYNSEC_USERNAME" -h "$MOSQUITTO_HOSTNAME" -P "$MOSQUITTO_DYNSEC_PASSWORD" dynsec addClientRole "$SERVICE_MQTT_USERNAME" "$MOSQUITTO_DYNSEC_USERNAME" 5  || exit 5

