from prober import Prober
import pytest
import asyncio
import cbor2


t = Prober()

# Simple tests of the DB testing suite
def test_db():
    """Simple test of my DB tests
    """
    TAG = "Test DB tests"

    t.db.assert_query_success(
    r"""
        SELECT * FROM card;
    """,
    TAG)

    t.db.assert_query_fail(
    r"""
        SELECT * FROM cards;
    """,
    TAG)

    t.db.assert_query_response(
    r"""
        SELECT * FROM card;
    """,
    [], TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO card_identifier(manufacturer, mutual_auth, comm_enc, customer_id, key_version)
        VALUES('Test', '\xCA02', '\x02', '\x00', 1);
    """,
    TAG 
    )

    t.db.assert_query_response(
    r"""
        SELECT manufacturer, mutual_auth, key_version FROM card_identifier;
    """,
    [
        ("Test", bytes.fromhex('CA02'), 1)
    ], 
    TAG)

    t.db.assert_query_success(
    r"""
        DELETE FROM card_identifier;
    """,
    TAG 
    )

    t.db.assert_query_response(
    r"""
        SELECT * FROM card_identifier;
    """,
    [], TAG)


async def simple_command_send():
    """Just to send a message to test that my tests work
    """

    await asyncio.sleep(3)
    t.mqtt.client.publish("registrator/TestCommands/command", bytes.fromhex("FF"), qos=0, retain=0)
    await asyncio.sleep(1)
    t.mqtt.client.publish("registrator/TestCommands/command", 
        cbor2.dumps({"status":"OP_OK", "UID":bytes.fromhex("11223344556677")}), 
        qos=2, retain=0)


# Simple test of the MQTT testing suite
@pytest.mark.asyncio
async def test_mqtt():
    """Test that the simple test works
    """
    TAG = "Test MQTT tests"

    asyncio.create_task(simple_command_send())
    await t.mqtt.assert_receive("registrator/TestCommands/command", bytes.fromhex("FF"), TAG)
    await t.mqtt.assert_receive_cbor("registrator/TestCommands/command", 
        {"status":"OP_OK", "UID":bytes.fromhex("11223344556677")}, TAG)
