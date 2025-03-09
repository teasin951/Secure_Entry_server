import paho.mqtt.client as mqtt

# MQTT broker details
broker = "your.broker.address"
port = 8883
topic = "your/topic"  # TODO more topics

# Client details
mqtt_username = "your_username"
mqtt_password = "your_password"

# TLS/SSL configuration
ca_cert = "path/to/ca.crt"  # Path to the CA certificate
client_cert = "path/to/client.crt"  # Path to the client certificate
client_key = "path/to/client.key"  # Path to the client private key


# Create an MQTT client instance
client = mqtt.Client()

# Set up TLS/SSL
client.tls_set(
    ca_certs=ca_cert,  # Path to the CA certificate
    certfile=client_cert,  # Path to the client certificate (if required)
    keyfile=client_key,  # Path to the client private key (if required)
    tls_version=mqtt.ssl.PROTOCOL_TLS  # Use the default TLS version
)

# Set username and password (if required)
client.username_pw_set(mqtt_username, mqtt_password);


# Callback when the client receives a message
def on_message(client, userdata, message):
    print(f"Received message on topic {message.topic}: {message.payload.decode()}")

# Callback when the client connects to the broker
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT broker!")
        client.subscribe(topic)  # Subscribe to the topic
    else:
        print(f"Connection failed with code {rc}")


# Assign callback functions
client.on_connect = on_connect
client.on_message = on_message

# Connect to the broker
client.connect(broker, port, 60)

# Start the non-blocking loop
client.loop_start()