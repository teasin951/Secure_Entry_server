# This should act as a middle man between the database and the MQTT broker


from mqtt import MQTTHandler
from database import run_database


def main():
    mqtt = MQTTHandler(
        broker="kharontest.w.sin.cvut.cz",
        port=8883,
        username="TestServer",
        password="test",
        client_id="SystemServer",
        ca_cert_path="../mosquitto/certs/ca.crt",
        server_cert_path="../mosquitto/certs/server.crt",
        server_key_path="../mosquitto/certs/server.key"
    )

    conn = run_database(mqtt)
    mqtt.conn = conn



if __name__ == '__main__':
    main()