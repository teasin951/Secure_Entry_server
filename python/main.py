# This should act as a middle man between the database and the MQTT broker


from mqtt import MQTTHandler
from database import DatabaseHandler
import logging
from logging.handlers import RotatingFileHandler
import os


logger = logging.getLogger(__name__)


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
    try:
        mqtt = MQTTHandler(
            hostname = os.environ["MOSQUITTO_HOSTNAME"],
            port = int(os.environ["MOSQUITTO_PORT"]),
            username = os.environ["SERVER_MQTT_USERNAME"],
            password = os.environ["SERVER_MQTT_PASSWORD"],
            client_id = "SystemServer",
            ca_cert_path = os.environ["MOSQUITTO_CA_FILE_PATH"],
            server_cert_path = os.environ["SERVER_CERT_FILE_PATH"],
            server_key_path = os.environ["SERVER_KEY_FILE_PATH"]
        )
        DatabaseHandler(
            hostname = os.environ["DATABASE_HOSTNAME"],
            port = int(os.environ["DATABASE_PORT"]),
            dbname = os.environ["DATABASE_NAME"],
            username = os.environ["DATABASE_USERNAME"],
            password = os.environ["DATABASE_PASSWORD"],
            mqtthandler = mqtt
        )

    except KeyError as e:
        logger.error(f"Environmental variable missing: {e}")
        logger.error("Aborting")
        exit



if __name__ == '__main__':
    setup_logger()
    main()