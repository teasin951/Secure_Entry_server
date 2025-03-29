#!/bin/bash

# You have to fill this to use this script!
HOST=kharontest.w.sin.cvut.cz

SERVER=TestServer
PASSW="test"


read -resp "Listen to reader(1) or registrator(2) logs? " RESP

case $RESP in
1)
    echo -e "Listening to reader logs..."

	mosquitto_sub -u "$SERVER" -P $PASSW -h $HOST -t "reader/logs" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key --id test_server_logs_reader
    ;;
2)
    echo -e "Listening to registrator logs..."

	mosquitto_sub -u "$SERVER" -P $PASSW -h $HOST -t "registrator/logs" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key --id test_server_logs_registrator
    ;;
esac

