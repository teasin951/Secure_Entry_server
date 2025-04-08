#!/bin/bash

# You have to fill this to use this script!
SERVER=TestServer
SERVER_ROLE=TestServer_role


echo -e "--- Might require sudo if it can't find files or you have to generate them ---"
echo -e "This script assumes, that your admin account for DynSec is called admin\n"
read -resp "Admin password for the broker DynSec: " PASSW


# -- To allow a "TestServer" client to publish -- #
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec createClient $SERVER  || exit 1
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec createRole $SERVER_ROLE  || exit 2

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE subscribeLiteral "reader/logs" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "reader/+/setup" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "whitelist/+/full" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "whitelist/+/add" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "whitelist/+/remove" allow 5  || exit 4

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE subscribeLiteral "registrator/logs" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "registrator/+/setup" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "registrator/+/command" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE subscribePattern "registrator/+/UID" allow 5  || exit 3

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addClientRole $SERVER $SERVER_ROLE 5  || exit 5
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addClientRole $SERVER "admin" 5  || exit 5

