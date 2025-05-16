import paho.mqtt.client as mqtt
import logging
import re
import cbor2


logger = logging.getLogger(__name__)


class MQTTHandler:
    def __init__(self, hostname, port, username, password, client_id, ca_cert_path, server_cert_path, server_key_path, dbconn=None):
        """ Init MQTTHandler and connect to MQTT broker
        """
        self.conn = dbconn
        self.client = mqtt.Client(client_id=client_id)
        self.card_personalize = {}  # Should be a dictionary with id_device to register (id_card, id_task)
        self.card_depersonalizators = {} # dict of registrator that try to delete cards with id_task

        self.client.tls_set(
            ca_certs=ca_cert_path,
            certfile=server_cert_path,
            keyfile=server_key_path,
            tls_version=mqtt.ssl.PROTOCOL_TLS  # Use the default TLS version
        )

        self.client.username_pw_set(username, password)
        self.client.max_inflight_messages_set(1)  # TODO change after adapting per-device restrictions

        # Assign callback functions
        self.client.on_connect = self.mqtt_on_connect
        self.client.on_message = self.mqtt_on_message

        self.client.loop_start()
        self.client.connect(hostname, port, 60)


    def set_db_connection(self, dbconn):
        """ Set db connection handle from psycopg2
        """
        self.conn = dbconn


    def wait_registrator_depersonalize(self, mqtt_username, id_task):
        """ Put mqtt_username of a registrator that should depersonalize a card
            into the dict
        """
        self.card_depersonalizators[mqtt_username] = id_task


    def wait_registrator_get_UID(self, mqtt_username, id_card, id_task):
        """ Put mqtt_username of a registrator that should personalize a card
            into the dict
        """
        self.card_personalize[mqtt_username] = (id_card, id_task)


    def mqtt_on_connect(self, client, userdata, flags, rc):
        """ Callback function for MQTT on connection
        """

        if rc == 0:
            logger.debug("Connected to MQTT broker!")
            client.subscribe([
                ("reader/+/logs", 0),
                ("registrator/+/logs", 0),
                ("registrator/+/UID", 2),
                ("whitelist/+/request", 2)
            ])
        else:
            logger.ERROR(f"Connection failed with code {rc}")


    def mqtt_on_message(self, client, userdata, message):
        """ Callback function for MQTT on new message
        """

        if( mqtt.topic_matches_sub("reader/+/logs", str(message.topic)) or 
            mqtt.topic_matches_sub("registrator/+/logs", str(message.topic)) ):
            logger.debug(f"Received log on topic {message.topic}: {message.payload.decode()}")
            self.handle_device_logs(message)

        elif ( mqtt.topic_matches_sub("registrator/+/UID", str(message.topic)) ):
            self.receive_UID(message)

        elif ( mqtt.topic_matches_sub("whitelist/+/request", str(message.topic)) ):
            self.retrieve_full_whitelist(message.topic.split('/')[1])


    def handle_device_logs(self, message):
        """ Handle receiving a log from devices
        """

        esp_logger = logging.getLogger( message.topic.rstrip('/logs') )
        log_text = self.remove_ansi_escape_sequences(message.payload.decode())
        match log_text[0]:
            case 'I':
                esp_logger.info(log_text[2:-1])

            case 'W':
                esp_logger.warning(log_text[2:-1])

            case 'E':
                esp_logger.error(log_text[2:-1])

            case 'D':
                esp_logger.debug(log_text[2:-1])


    def remove_ansi_escape_sequences(self, text):
        """ Remove ANSI escape sequences (color codes) from a string.
        """

        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        return ansi_escape.sub('', text)


    def receive_UID(self, message):
        """ Handle receiving UID from registrators
        """

        mqtt_registrator = message.topic.split('/')[1]
        conv_message = cbor2.loads(message.payload)
        logger.debug(f"Received on UID: {conv_message}")

        # Try personalization dict
        try:
            arguments = self.card_personalize.pop(mqtt_registrator)
            self.fill_UID_to_card( 
                arguments[0],
                conv_message,
                arguments[1]
            )
            return

        except KeyError:
            # Registrator should have not registered anybody
            pass

        # Try depersonalization dict
        try:
            id_task = self.card_depersonalizators.pop(mqtt_registrator)
            self.delete_card(
                conv_message,
                id_task
            )
            return

        except KeyError:
            # Registrator should have not depersonalized anybody
            pass


    def fill_UID_to_card(self, id_card, message, id_task):
        """ Fill UID to card entry in the DB based on the message and delete from task_queue
        """

        # If the operation has not succeeded, just finish the task
        if( message['status'].rstrip('\x00') == 'OP_FAIL' or \
            message['UID'] == bytes.fromhex('ffffffffffffff')):

            self.finish_task(id_task)
            return

        with (self.conn).cursor() as cur:
            cur.execute("""
                UPDATE card SET uid = %s
                WHERE id_card = %s
            """, (message['UID'], id_card))

        self.finish_task(id_task)


    def delete_card(self, message, id_task):
        """ Delete card from the DB based on the message and delete from task_queue
        """

        # If the operation has not succeeded, just finish the task
        if( message['status'].rstrip('\x00') == 'OP_FAIL' or \
            message['UID'] == bytes.fromhex('ffffffffffffff')):

            self.finish_task(id_task)
            return

        with (self.conn).cursor() as cur:
            cur.execute("""
                DELETE FROM card
                WHERE uid = %s
            """, (message['UID'], ))

        self.finish_task(id_task)


    def finish_task(self, id_task):
        """ Delete task from task_queue
        """

        with self.conn.cursor() as cur:
            cur.execute("""
                DELETE FROM task_queue
                WHERE id_task = %s;
            """, (id_task,))


    def retrieve_full_whitelist(self, id_zone):
        """ Make the DB create a full whitelist for a zone
        """

        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT update_full_whitelist_for_zone(%s);
            """, (id_zone,))

    
    def publish_message(self, topic, payload, qos, retain):
        """ Publish message to a MQTT topic
        """

        self.client.publish(topic, payload, qos, retain)


