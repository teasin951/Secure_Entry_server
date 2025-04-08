import paho.mqtt.client as mqtt


class MQTTHandler:
    def __init__(self, broker, port, username, password, client_id, ca_cert_path, server_cert_path, server_key_path, dbconn=None):
        self.conn = dbconn
        self.client = mqtt.Client(client_id=client_id)
        self.card_registrators = {}  # Should be a dictionary with id_device to register id_card

        self.client.tls_set(
            ca_certs=ca_cert_path,
            certfile=server_cert_path,
            keyfile=server_key_path,
            tls_version=mqtt.ssl.PROTOCOL_TLS  # Use the default TLS version
        )

        self.client.username_pw_set(username, password)

        # Assign callback functions
        self.client.on_connect = self.mqtt_on_connect
        self.client.on_message = self.mqtt_on_message

        self.client.loop_start()
        self.client.connect(broker, port, 60)


    # Callback when the client receives a message
    def mqtt_on_message(self, client, userdata, message):
        print(f"Received message on topic {message.topic}: {message.payload.decode()}")
        match message.topic:
            case "reader/logs":
                # TODO INSERT logs
                print("Reader logs: %s", message.payload.decode())
                pass
        
            case "registrator/logs":
                # TODO INSERT logs
                print("Registrator logs: %s", message.payload.decode())
                pass

            case client.topic_matches_subscription("registrator/+/UID", message.topic):
                print("UID: %s", message.payload.decode())
                self.receive_UID(message)

            case "$CONTROL/dynamic-security/v1/response":
                print("DynSec response: ", message.payload)


    def receive_UID(self, message):
        # If the card failed to be registered, TODO then what?
        if( message.payload == 0xFFFFFFFFFFFFFF ):
            return

        mqtt_registrator = message.topic.split('/')[1]
        self.fill_UID_to_card( self.card_registrators.pop(mqtt_registrator), message.payload )
            

    def fill_UID_to_card(self, id_card, UID):
        with self.conn.cursor() as cur:
            cur.execute("""
                UPDATE card SET uid = %s
                WHERE id_card = %d
            """, (UID,), id_card)


    # Callback when the client connects to the broker
    def mqtt_on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT broker!")
            client.subscribe([
                ("reader/logs", 0),
                ("registrator/logs", 0),
                ("registrator/+/UID", 2)
            ])
        else:
            print(f"Connection failed with code {rc}")


    def wait_registrator_get_UID(self, mqtt_username, id_card):
        self.card_registrators[mqtt_username] = id_card

    
    def publish_message(self, topic, payload, qos, retain):
        self.client.publish(topic, payload, qos, retain)
        # TODO failure handeling


