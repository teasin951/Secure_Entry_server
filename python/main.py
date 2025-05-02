# This should act as a middle man between the database and the MQTT broker


from mqtt import MQTTHandler
from database import DatabaseHandler
import logging
from logging.handlers import RotatingFileHandler


def setup_logger():
    rotating_handler = RotatingFileHandler(
        filename    = "./logs/system.log",
        maxBytes    = 10 * 1024 * 1024,  # 10 MB
        backupCount = 5,              # Keep 5 rotated logs
    )

    logging.basicConfig(
        level    = logging.DEBUG,
        format   = "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers = [
            logging.StreamHandler(), 
            rotating_handler
        ]
    )


def main():
    mqtt = MQTTHandler(
        broker = "kharontest.w.sin.cvut.cz",
        port = 8883,
        username = "TestServer",
        password = "test",
        client_id = "SystemServer",
        ca_cert_path = "../mosquitto/certs/ca.crt",
        server_cert_path = "../mosquitto/certs/server.crt",
        server_key_path = "../mosquitto/certs/server.key"
    )
    DatabaseHandler(mqtt)



if __name__ == '__main__':
    setup_logger()
    main()