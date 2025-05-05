#!/bin/bash

# You have to fill this to use this script!
HOST=kharontest.w.sin.cvut.cz

SERVER=Server
CLIENT=TestRegistrator
PASSW="admin"
ZONE=1


while true 
do

	read -resp "What command to send? Personalize (0), Depersonalize (1), Erase last (2), Add test whitelist(3), Remove test whitelist (4)" RESP

case $RESP in
0)
    echo -e "Sending personalize..."

    mosquitto_pub -u $SERVER -P "$PASSW" -h "$HOST" -t "registrator/$CLIENT/command" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f personalize_code.bin --id test_server --qos 2
    ;;
1)
    echo -e "Sending depersonalize..."

    mosquitto_pub -u $SERVER -P "$PASSW" -h "$HOST" -t "registrator/$CLIENT/command" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f depersonalize_code.bin --id test_server --qos 2
    ;;
2)
    echo -e "Sending delete last..."

    mosquitto_pub -u $SERVER -P "$PASSW" -h "$HOST" -t "registrator/$CLIENT/command" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f delete_app.bin --id test_server --qos 2
    ;;
3)
    echo -e "Adding test whitelist..."

    mosquitto_pub -u $SERVER -P "$PASSW" -h "$HOST" -t "whitelist/$ZONE/add" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f test_whitelist.cbor --id test_server --qos 2
    ;;
4)
    echo -e "Removing test whitelist..."

    mosquitto_pub -u $SERVER -P "$PASSW" -h "$HOST" -t "whitelist/$ZONE/remove" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -f test_whitelist.cbor --id test_server --qos 2
    ;;
esac

done
# sudo mosquitto_sub -P test -h "$HOST" -t "registrator/$CLIENT/command" --cafile ../mosquitto/certs/ca.crt --cert ../mosquitto/certs/clients/test.crt --key ../mosquitto/certs/clients/test.key -u $CLIENT
