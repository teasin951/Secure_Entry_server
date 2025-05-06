from mqtt_func import MQTTHandler
from db_func import AssertDB
import asyncio


class Prober():
    def __init__(self):
        self.mqtt = MQTTHandler(
            hostname="kharontest.w.sin.cvut.cz",
            port=8883,
            username="Server",
            password="admin",
            client_id="TestServer",
            ca_cert_path = "../mosquitto/certs/ca.crt",
            server_cert_path = "../mosquitto/certs/server.crt",
            server_key_path = "../mosquitto/certs/server.key"
        )

        self.db = AssertDB(
            host="localhost",
            dbname="test",
            username="admin",
            password="admin"
        )

    
    async def query_check_mqtt(self, query, topic, payload, test_name="", timeout=10):
        self.db.assert_query_success(query, test_name=test_name)
        await self.mqtt.assert_receive(topic, payload, test_name, timeout)


    async def query_check_mqtt_cbor(self, query, topic, cbor, test_name="", timeout=10):
        self.db.assert_query_success(query, test_name=test_name)
        await self.mqtt.assert_receive_cbor(topic, cbor, test_name, timeout)


    async def query_check_mqtt_cbor_sequence(self, query, topic, cbor, test_name="", timeout=10):
        self.db.assert_query_success(query, test_name=test_name)
        await self.mqtt.assert_receive_sequence(topic, cbor, test_name, timeout)


    async def query_check_mqtt_cbor_multi_sequence(self, query, expected, test_name="", timeout=10):
        self.db.assert_query_success(query, test_name=test_name)
        await self.mqtt.assert_receive_multi_sequence_cbor(expected, test_name, timeout)


    async def query_check_no_message(self, query, topic, test_name="", timeout=1):
        self.db.assert_query_success(query, test_name=test_name)
        await self.mqtt.assert_not_receive(topic, test_name, timeout)