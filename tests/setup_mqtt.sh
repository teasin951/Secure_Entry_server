#!/bin/bash

# This will create a test client "TestClient" ACLs according to the mosquitto_connect_options
# https://mosquitto.org/documentation/dynamic-security/
# 
# and setup the necessary things for reader tests

# You have to fill this to use this script!
HOST=kharontest.w.sin.cvut.cz

ZONEID=1
CLIENT=TestClient
CLIENT_ROLE=TestRole
SERVER=TestServer
SERVER_ROLE=TestServerRole


echo -e "--- Might require sudo if it can't find files or you have to generate them ---"
echo -e "This script assumes, that your admin account for DynSec is called admin and key with cert for the $CLIENT are called test.crt, test.key\n"
read -resp "Admin password for the broker DynSec: " PASSW
echo -e "Please input 'test' as the password for the $CLIENT"

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec createClient $CLIENT  || exit 1
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec createRole $CLIENT_ROLE  || exit 2

# -- For reader -- #
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE publishClientSend "reader/logs" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE subscribeLiteral "reader/$CLIENT" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE subscribeLiteral "whitelist/$ZONEID/full" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE subscribeLiteral "whitelist/$ZONEID/add" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE subscribeLiteral "whitelist/$ZONEID/remove" allow 5  || exit 4

# -- For registrator -- #
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE publishClientSend "registrator/logs" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE subscribeLiteral "registrator/$CLIENT/setup" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE subscribeLiteral "registrator/$CLIENT/command" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $CLIENT_ROLE publishClientSend "registrator/$CLIENT/UID" allow 5  || exit 3

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addClientRole $CLIENT $CLIENT_ROLE 5  || exit 5


# -- To allow a "TestServer" client to publish -- #
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec createClient $SERVER  || exit 1
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec createRole $SERVER_ROLE  || exit 2

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE subscribeLiteral "reader/logs" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "reader/$CLIENT" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "whitelist/$ZONEID/full" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "whitelist/$ZONEID/add" allow 5  || exit 4
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "whitelist/$ZONEID/remove" allow 5  || exit 4

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE subscribeLiteral "registrator/logs" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "registrator/$CLIENT/setup" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE publishClientSend "registrator/$CLIENT/command" allow 5  || exit 3
mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addRoleACL $SERVER_ROLE subscribeLiteral "registrator/$CLIENT/UID" allow 5  || exit 3

mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec addClientRole $CLIENT $SERVER_ROLE 5  || exit 5



# -- Publish basic setup -- #
python create_messages.py

mosquitto_pub -u $CLIENT -P test -h "$HOST" -t "reader/$CLIENT" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f test_setup.cbor --id test_server  --retain --qos 2  || exit 6
mosquitto_pub -u $CLIENT -P test -h "$HOST" -t "whitelist/$ZONEID/full" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f test_whitelist.cbor --id test_server --retain --qos 2  || exit 6
mosquitto_pub -u $CLIENT -P test -h "$HOST" -t "registrator/$CLIENT/setup" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f test_setup.cbor --id test_server --retain --qos 2  || exit 6











# Modify the -P for the proper password if necessary
# Then try something like this from this directory:
#
# sudo mosquitto_sub -P test -h "$HOST" -t "test/test" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/Test.crt --key ../mosquitto/certs/clients/Test.key -u TestClient
#
#
# In another terminal:
#
# sudo mosquitto_pub -P test -h "$HOST" -t "test/test" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/Test.crt --key ../mosquitto/certs/clients/Test.key -u TestClient -m "Test message" --id Tester_ID
#
#
# Then to disable the TestClient:
# mosquitto_ctrl -o ./mosquitto_connect_options -P "$PASSW" dynsec disableClient TestClient
