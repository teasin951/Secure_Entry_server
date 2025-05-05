from complete_func import Prober
import pytest
import asyncio
import cbor2

#
# These test the reader's reaction to stimuli
#
# The tests are expected to be launched after the API tests at least the db_insert test is required
#
# A basic reader and a registrator connected to the Wi-Fi and ready to be connected to the MQTT
# is expected with the credentials TestReader, test and TestRegistrator, test
#
# This test is interactive and you will need at least 2 desfire ev1 cards. Follow the instructions given.
#

t = Prober()


def test_cleanup():
    t.db.assert_query_success(
    """
        DELETE FROM card;
        DELETE FROM time_rule;
        DELETE FROM reader;
        DELETE FROM registrator;
    """
    )

    t.db.assert_query_success(
    """
        INSERT INTO card(id_card, name) 
        VALUES(1, 'TestCardA'), (2, 'TestCardB'), (3, 'TestCardC');
    """
    )


@pytest.mark.asyncio
async def test_insert_reader():
    TAG = "Insert reader"
    await t.mqtt.await_connection()

    print("--- The reader should now connect and receive setup ---")
    await t.query_check_mqtt_cbor(
    r"""
        INSERT INTO reader(id_device, id_zone)
        VALUES(1, 1);
    """,
    "reader/TestReader/setup",
    {
        "APPVOK": int("22222222222222222222222222222222", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
        "Zone": 1
    },
    TAG)

    await t.mqtt.assert_receive(
        "whitelist/1/request",
        bytes("request_full", "ascii"),
        TAG,
        timeout=60
    )

    await t.mqtt.assert_receive(
        "whitelist/1/full",
        bytes(),
        TAG
    )

    # Reader cannot be a registrator as well
    t.db.assert_query_fail(
    r"""
        INSERT INTO registrator(id_device) VALUES(1);
    """,
    TAG)


@pytest.mark.asyncio
async def test_insert_registrator():
    TAG = "Insert registrator"
    await t.mqtt.await_connection()


    print("--- The registrator should now connect and receive setup ---")
    await t.query_check_mqtt_cbor(
    r"""
        INSERT INTO registrator(id_device)
        VALUES(2);
    """,
    "registrator/TestRegistrator/setup",
    {
        "APPMOK": int("11111111111111111111111111111111", 16), 
        "APPVOK": int("22222222222222222222222222222222", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
    },
    TAG)

    # Registrator cannot be a reader as well
    t.db.assert_query_fail(
    r"""
        INSERT INTO reader(id_device, id_zone) VALUES(2, 1);
    """,
    TAG)


@pytest.mark.asyncio
async def test_update_config():
    TAG="Update config"
    await t.mqtt.await_connection()

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        UPDATE config SET id_config = 1 WHERE id_config = 1;
    """,
    [
        {
            "topic": "reader/TestReader/setup",
            "payload": [
                {
                    "APPVOK": int("22222222222222222222222222222222", 16), 
                    "OCPSK": int("33333333333333333333333333333333", 16), 
                    "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
                    "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
                    "Zone": 1
                }]
        },
        {
            "topic": "registrator/TestRegistrator/setup",
            "payload": [
                {
                    "APPMOK": int("11111111111111111111111111111111", 16), 
                    "APPVOK": int("22222222222222222222222222222222", 16), 
                    "OCPSK": int("33333333333333333333333333333333", 16), 
                    "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
                    "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
                }]
        }
    ],
    TAG)

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE card_identifier SET id_card_identifier = 1 WHERE id_card_identifier = 1;
    """,
    "reader/TestReader/setup",
    {
        "APPVOK": int("22222222222222222222222222222222", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
        "Zone": 1
    },
    TAG)

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE pacs_object SET id_pacs_object = 1 WHERE id_pacs_object = 1;
    """,
    "reader/TestReader/setup",
    {
        "APPVOK": int("22222222222222222222222222222222", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
        "Zone": 1
    },
    TAG)

    t.db.assert_query_fail(
    """
        DELETE FROM config;
    """,
    TAG)

    t.db.assert_query_fail(
    """
        DELETE FROM card_identifier;
    """,
    TAG)

    t.db.assert_query_fail(
    """
        DELETE FROM pacs_object;
    """,
    TAG)


@pytest.mark.asyncio
async def test_update_device():
    TAG="Bulk insert"
    await t.mqtt.await_connection()
    
    t.db.assert_query_fail(
    """
        UPDATE device
        SET mqtt_username = 'Incorrect'
        WHERE id_device = 1;
    """,
    TAG)

#     # TODO create new config and update the device after it has reader assigned



@pytest.mark.asyncio
async def test_personalize():
    TAG="Operations"
    await t.mqtt.await_connection()

    print("=========== Personalize card A on the registrator ===========")
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('personalize', 2, 1);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("1E"),
    TAG)

    await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    await asyncio.sleep(0.5)

    t.db.assert_query_response_not_null(
    """
        SELECT uid FROM card WHERE name = 'TestCardA';
    """,
    TAG)


@pytest.mark.asyncio
async def test_verify_personalization():
    TAG="Verify personalization"
    await t.mqtt.await_connection()

    print("=========== Verify card A on the registrator ===========")
    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert cbor2.loads(ret)['status'].rstrip('\x00') == 'AUTH_OK', "Failed to AUTH card that should be personalized"


    print("=========== Try card A on the reader ===========")
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)


    t.db.assert_query_success(
    """
        INSERT INTO card_zone VALUES(1, 1);
    """, 
    TAG)

    print("=========== Try card A on the reader ===========")
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)
    
