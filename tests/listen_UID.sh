#!/bin/bash

# You have to fill this to use this script!
HOST=kharontest.w.sin.cvut.cz

SERVER=TestServer
CLIENT=TestClient
PASSW="test"

echo -e "Listening to UIDs from $CLIENT..."

mosquitto_sub -u $SERVER -P $PASSW -h $HOST -t "registrator/$CLIENT/UID" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key --id test_server_uids
