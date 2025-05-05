import paho.mqtt.client as mqtt
import cbor2
import asyncio
from io import BytesIO
import re


class MQTTHandler:
    def __init__(self, hostname, port, username, password, client_id, ca_cert_path, server_cert_path, server_key_path):
        self.wait_topic = None
        self.wait_payload = None
        self.event = asyncio.Event()
        self.connection_event = asyncio.Event()
        self.loop = None

        # For checking multiple topics after one query
        self.wait_multi_topic = False
        self.multi_topics = []
        self.multi_message = []


        self.client = mqtt.Client(client_id=client_id)
        self.client.tls_set(
            ca_certs=ca_cert_path,
            certfile=server_cert_path,
            keyfile=server_key_path,
            tls_version=mqtt.ssl.PROTOCOL_TLS_CLIENT
        )

        self.client.max_inflight_messages_set(1)  # TODO change after adapting per-device restrictions
        self.client.username_pw_set(username, password)

        # Assign callback functions
        self.client.on_connect = self.mqtt_on_connect
        self.client.on_message = self.mqtt_on_message

        self.client.loop_start()
        self.client.connect(hostname, port, 60)


    def mqtt_on_connect(self, client, userdata, flags, rc):
        """ Callback function for MQTT
        
        Sub to everything on connection
        """

        if rc == 0:
            print("Connected to MQTT broker!")
            client.subscribe([
                ("reader/#", 0),
                ("registrator/#", 0),
                ("whitelist/#", 0),
            ])

            self.loop.call_soon_threadsafe(self.connection_event.set)

        else:
            print(f"Connection failed with code {rc}")


    def mqtt_on_message(self, client, userdata, message):
        """ Callback function for MQTT

        Check if we are waiting on this topic and if then set event
        """

        print(f"Received on topic {str(message.topic)}: {str(message.payload)}")

        # Set topic and payload for multi topic check
        if( self.wait_multi_topic ):
            print(f"Received: {message.payload}")
            if message.topic in self.multi_topics:
                self.multi_message.append( {"topic": message.topic, "payload": message.payload} )

            if len(self.multi_message) == len(self.multi_topics):
                self.loop.call_soon_threadsafe(self.event.set)

        # Set payload for single topic check
        if( str(message.topic) == self.wait_topic ):
            self.wait_payload = message.payload
            self.loop.call_soon_threadsafe(self.event.set)


    async def await_connection(self):
        """If we are not connected to MQTT, wait
        """

        if( self.client.is_connected() ):
            return


        self.loop = asyncio.get_running_loop()
        self.connection_event = asyncio.Event()
        try:
            await asyncio.wait_for(self.connection_event.wait(), timeout=10)

        except TimeoutError:
            return


    async def await_topic(self, topic, timeout):
        """Waits for a message on a topic

        Args:
            topic (string): Topic to monitor
            timeout (int): The time to wait in seconds
        """

        while( self.wait_topic is not None and not self.wait_multi_topic ):
            await asyncio.sleep(0.2)

        self.loop = asyncio.get_running_loop()
        self.event = asyncio.Event()
        self.wait_topic = topic

        try:
            await asyncio.wait_for(self.event.wait(), timeout=timeout)

        except TimeoutError:
            return None


        self.event.clear()
        tmp = self.wait_payload
        self.wait_payload = None
        self.wait_topic = None
        return tmp


    async def await_topics(self, topics, timeout):
        """Waits for a messages on a topics

        Args:
            topics (array): Topics to monitor
            timeout (int): The time to wait in seconds
        """

        while( self.wait_topic is not None and not self.wait_multi_topic ):
            await asyncio.sleep(0.2)

        self.loop = asyncio.get_running_loop()
        self.event = asyncio.Event()
        self.wait_multi_topic = True 
        self.multi_topics = topics

        try:
            await asyncio.wait_for(self.event.wait(), timeout=timeout)

        except TimeoutError:
            return None


        self.event.clear()
        tmp = self.multi_message
        self.multi_topics = []
        self.multi_message = []
        self.wait_multi_topic = False
        return tmp


    async def assert_receive(self, topic, payload, test_name="", timeout=10):
        """Wait for a message and assert if we expected it

        Args:
            topic (string): Topic to monitor
            payload (string): The expected payload
            timeout (int, optional): The time to wait in seconds. Defaults to 10.
        """

        ret = await self.await_topic(topic, timeout)

        assert ret is not None, f"-- {test_name} --\nNo message received on topic {topic}, timed out."
        assert ret == payload, f"-- {test_name} --\nPayloads do not match, Expected: {payload}\nGot: {ret}"


    async def assert_not_receive(self, topic, test_name="", timeout=1):
        """Wait for a message and assert if we expected it

        Args:
            topic (string): Topic to monitor
            timeout (int, optional): The time to wait in seconds. Defaults to 10.
        """

        ret = await self.await_topic(topic, timeout)

        assert ret is None, f"-- {test_name} --\nUnexpected message received on topic {topic}\nGot: {ret}"


    async def assert_receive_cbor(self, topic, cbor, test_name="", timeout=10):
        """Wait for a message and assert if we expected this CBOR

        Args:
            topic (string): Topic to monitor
            cbor (object): Dict or array that is to be made into CBOR
            timeout (int, optional): The time to wait in seconds. Defaults to 10.
        """

        ret = await self.await_topic(topic, timeout)

        assert ret is not None, f"-- {test_name} --\nNo message received on topic {topic}, timed out."

        for e in cbor2.loads(ret):
            assert e in cbor, f"-- {test_name} --\nPayloads do not match, Expected: {cbor}\nGot: {cbor2.loads(ret)}"


    def match_entry_to_cbor_sequence(self, entry, cbor):
        """Assert if a entry is in cbor sequence

        Args:
            entry (array): Whitelist entry to check
            cbor (array): Array of whitelist entries to check
        """

        found = False
        for e in entry:
            for c in cbor:
                if e in c:
                    found = True
                    break
                found = False

        assert found, f"Received entry {entry} could not be found in expected entries.\nExpected entries: {cbor}"


    async def assert_receive_sequence(self, topic, cbor, test_name="", timeout=10):
        """Wait for a message and assert if we expected this CBOR sequence

        Args:
            topic (string): Topic to monitor
            cbor (array): Array of cbor objects to create the sequence 
            timeout (int, optional): The time to wait in seconds. Defaults to 10.
        """

        ret = await self.await_topic(topic, timeout)

        assert ret is not None, f"-- {test_name} --\nNo message received on topic {topic}, timed out."


        # Create a file-like object from the payload so that it is sequentially readable by cbor2.load()
        file_ret = BytesIO(ret)

        # Go through the entries and try to find corresponding one in our array
        for x in range(len(cbor)):
            try:
                entry = cbor2.load(file_ret)
                self.match_entry_to_cbor_sequence(entry, cbor)

            except EOFError:
                assert False, f"Not all expected entries have been received. Received:{ret}\nExpected: {cbor}"

        
    async def assert_receive_multi_sequence_cbor(self, expected, test_name="", timeout=10):
        """Wait for a messages on different topics and assert if we expected those CBOR sequences

        Args:
            expected (array): Array of objects with topic and cbor sequences. Format:
                [
                    {
                        "topic": "whitelist/1/remove",
                        "payload": [[bytes.fromhex("11223344556677")]]
                    },
                    {
                        "topic": "whitelist/1/add",
                        "payload": [[bytes.fromhex("00112233445566")],
                            [bytes.fromhex("00112233445566"), {"t": bytes.fromhex("7C0816102C")}]]
                    },
                ]

            timeout (int, optional): The time to wait in seconds. Defaults to 10.
        """

        # Get topics to monitor
        topics = []
        for top in expected:
            topics.append(top['topic'])


        ret = await self.await_topics(topics, timeout)

        assert ret is not None, f"-- {test_name} --\nNot all messages received on topics {topics}, timed out."


        # Check that we have all expected topics
        rtops = []
        for top in ret:
            rtops.append(top['topic'])

        for top in topics:
            assert top in rtops, f"-- {test_name} --\nTopic {top} has not been received. Received topics {rtops}."


        # Check their content
        for top in ret:
            exp_cbor = []
            # Find the corresponding expected output
            for e in expected:
                if e['topic'] == top['topic']:
                    exp_cbor = e['payload']

            assert exp_cbor != []  # Should not happen because of the previous check


            # Create a file-like object from the payload so that it is sequentially readable by cbor2.load()
            file_ret = BytesIO(top['payload'])

            # Go through the entries and try to find corresponding one in our array
            for x in range(len(exp_cbor)):
                try:
                    entry = cbor2.load(file_ret)
                    self.match_entry_to_cbor_sequence(entry, exp_cbor)

                except EOFError:
                    assert False, f"Not all expected entries have been received. Received: {ret}\nExpected: {exp_cbor}"


    def remove_ansi_escape_sequences(self, text):
        """Remove ANSI escape sequences (color codes) from a string.
        """
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        return ansi_escape.sub('', text)


    async def assert_receive_log(self, topic, log, test_name="", timeout=10):
        """Wait for a message and assert if it is the log we were waiting for

        Args:
            topic (string): Topic to monitor
            log (string): Log message to wait for
            timeout (int, optional): The time to wait in seconds. Defaults to 10.
        """

        while True:
            ret = await self.await_topic(topic, timeout)
            assert ret is not None, f"-- {test_name} --\nNo message received on topic {topic}, timed out."

            log_string = self.remove_ansi_escape_sequences(ret.decode())
            if( re.search(log, log_string) ):
                break

