from prober import Prober
import pytest
import asyncio
import cbor2
from termcolor import colored
from datetime import datetime

#
# These test the reader's reaction to stimuli
#
# The tests are expected to be launched after the API tests at least the db_insert test is required
#
# A basic reader and a registrator connected to the Wi-Fi and ready to be connected to the MQTT
# is expected with the credentials TestReader, test and TestRegistrator, test
#
# This test is interactive and you will need at least 2 DESFire ev1 cards. Follow the instructions given.
#

t = Prober()


# Clean some stuff from previous tests and add cards
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


# Add reader to the system
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


# Add registrator to the system
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

    await t.mqtt.assert_receive_log("registrator/TestRegistrator/logs", "", TAG, 60)



# Test updating config pushes it to devices if allowed
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

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        UPDATE card_identifier SET id_card_identifier = 1 WHERE id_card_identifier = 1;
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

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        UPDATE pacs_object SET id_pacs_object = 1 WHERE id_pacs_object = 1;
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


# Try updating device mqtt credentials (should fail)
@pytest.mark.asyncio
async def test_update_device():
    TAG="Change MQTT credentials"
    await t.mqtt.await_connection()
    
    t.db.assert_query_fail(
    """
        UPDATE device
        SET mqtt_username = 'Incorrect'
        WHERE id_device = 1;
    """,
    TAG)

    t.db.assert_query_fail(
    """
        UPDATE device
        SET mqtt_password = 'Incorrect'
        WHERE id_device = 1;
    """,
    TAG)


# Try to personalize a card and check that the UID is returned to database
@pytest.mark.asyncio
async def test_personalize():
    TAG="Operations"
    await t.mqtt.await_connection()

    print(colored("=========== Personalize card A on the registrator ===========", "yellow"))
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('personalize', 2, 1);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("1E"),
    TAG)

    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert ret is not None, "Did not receive UID after personalization"
    await asyncio.sleep(0.5)

    t.db.assert_query_response_not_null(
    """
        SELECT uid FROM card WHERE name = 'TestCardA';
    """,
    TAG)


# Verify that the card has been personalized correctly and works when added to whitelist
@pytest.mark.asyncio
async def test_verify_personalization():
    TAG="Verify personalization"
    await t.mqtt.await_connection()

    print(colored("=========== Verify card A on the registrator ===========", "yellow"))
    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert cbor2.loads(ret)['status'].rstrip('\x00') == 'AUTH_OK', "Failed to AUTH card that should be personalized"


    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)


    t.db.assert_query_success(
    """
        INSERT INTO card_zone VALUES(1, 1);
    """, 
    TAG)

    print(colored("=========== Try card A on the reader (again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)
    

# Push new config to registrator
@pytest.mark.asyncio
async def test_different_config():
    TAG="Different config"
    await t.mqtt.await_connection()

    t.db.assert_query_success(
    r"""
        INSERT INTO config(id_config, appmok, appvok, ocpsk, name, id_card_identifier, id_pacs_object)
        VALUES(2, '\x11111111111111111111111111111111', '\x88888888888888888888888888888888', 
               '\x33333333333333333333333333333333', 'Test config 2', 1, 1);
    """,
    TAG)

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE device SET id_config = 2 WHERE name = 'TestRegistrator';
    """,
    "registrator/TestRegistrator/setup",
    {
        "APPMOK": int("11111111111111111111111111111111", 16), 
        "APPVOK": int("88888888888888888888888888888888", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
    },
    TAG)

    print(colored("=========== Personalize card B on the registrator ===========", "yellow"))
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('personalize', 2, 2);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("1E"),
    TAG)


# Test that card personalized on a different config cannot be accepted by a reader with a different config
@pytest.mark.asyncio
async def test_new_config():
    TAG="Test new config"
    await t.mqtt.await_connection()

    print(colored("=========== Verify card A on the registrator ===========", "yellow"))
    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert cbor2.loads(ret)['status'].rstrip('\x00') == 'AUTH_FAIL', "Authenticated card that should not be personalized"

    print(colored("=========== Verify card B on the registrator ===========", "yellow"))
    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert cbor2.loads(ret)['status'].rstrip('\x00') == 'AUTH_OK', "Failed to AUTH card that should be personalized"

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    print(colored("=========== Try card B on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)

    t.db.assert_query_success(
    """
        INSERT INTO card_zone VALUES(2, 1) ON CONFLICT DO NOTHING;
    """, 
    TAG)

    print(colored("=========== Try card B on the reader (again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE device SET id_config = 2 WHERE name = 'TestReader';
    """,
    "reader/TestReader/setup",
    {
        "APPVOK": int("88888888888888888888888888888888", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
        "Zone": int(1)
    },
    TAG)
    
    print(colored("=========== Try card B on the reader (again, again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)


# Depersonalize A 
@pytest.mark.asyncio
async def test_depersonalize():
    TAG="Test depersonalization"
    await t.mqtt.await_connection()

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE device SET id_config = 1 WHERE name = 'TestRegistrator';
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

    print(colored("=========== Verify card A on the registrator ===========", "yellow"))
    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert cbor2.loads(ret)['status'].rstrip('\x00') == 'AUTH_OK', "Failed to AUTH card that should be personalized"

    print(colored("=========== Depersonalize card A on the registrator ===========", "yellow"))
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('depersonalize', 2, 1);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("DE"),
    TAG)

    await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    await asyncio.sleep(0.5)

    t.db.assert_query_response_null(
    """
        SELECT id_card FROM card WHERE id_card = 1;
    """,
    TAG)


# Personalize A with new config
@pytest.mark.asyncio
async def test_again_personalize():
    TAG="Test new personalization"
    await t.mqtt.await_connection()

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE device SET id_config = 2 WHERE name = 'TestRegistrator';
    """,
    "registrator/TestRegistrator/setup",
    {
        "APPMOK": int("11111111111111111111111111111111", 16), 
        "APPVOK": int("88888888888888888888888888888888", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
    },
    TAG)

    print(colored("=========== Personalize card A on the registrator ===========", "yellow"))
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('personalize', 2, 3);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("1E"),
    TAG)


# Test with different zones
@pytest.mark.asyncio
async def test_zones():
    TAG="Test with zones"
    await t.mqtt.await_connection()

    print(colored("=========== Verify card B on the registrator ===========", "yellow"))
    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert cbor2.loads(ret)['status'].rstrip('\x00') == 'AUTH_OK', "Failed to AUTH card that should be personalized"

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)

    t.db.assert_query_success(
    """
        INSERT INTO card_zone VALUES(3, 1) ON CONFLICT DO NOTHING;
    """, 
    TAG)

    print(colored("=========== Try card A on the reader (again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    t.db.assert_query_success(
    """
        INSERT INTO card_zone VALUES(2, 2) ON CONFLICT DO NOTHING;
    """, 
    TAG)

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE reader SET id_zone = 2;
    """,
    "reader/TestReader/setup",
    {
        "APPVOK": int("88888888888888888888888888888888", 16), 
        "OCPSK": int("33333333333333333333333333333333", 16), 
        "CardID": bytes.fromhex("54657374000000000000000000000000CA02020000000001"),
        "PACSO": bytes.fromhex("0101FFAAFFAAFF00000000001100222200000000112233445566778899AABBCCDDEEFF0011223344"), 
        "Zone": int(2)
    },
    TAG)

    print(colored("=========== Try card B on the reader  ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)

    t.db.assert_query_success(
    """
        INSERT INTO card_zone VALUES(3, 2) ON CONFLICT DO NOTHING;
    """, 
    TAG)

    print(colored("=========== Try card A on the reader (again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)


# Test with time constraints
@pytest.mark.asyncio
async def test_time_constraints():
    TAG="Test time constraints"
    await t.mqtt.await_connection()

    now = datetime.now()
    hour = int(now.strftime("%H"))
    next_hour = hour + 1
    if(next_hour > 23): 
        next_hour = 0
    minute = int(now.strftime("%M"))
    prev_hour = hour - 1
    if(prev_hour < 0):
        prev_hour = 23

    t.db.assert_query_success(
    """
        INSERT INTO time_rule(id_time_rule, id_zone, name) VALUES(1, 2, 'TestZone')
        ON CONFLICT DO NOTHING;
    """, 
    TAG)

    t.db.assert_query_success(
    """
        INSERT INTO card_time_rule VALUES(3, 1, 2);
    """,
    TAG)

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    t.db.assert_query_success(
    f"""
        INSERT INTO time_constraint VALUES(1, 1, 2, '{hour}:{minute}', '{next_hour}:{minute}', '\x7f')
        ON CONFLICT DO NOTHING;
    """
    )

    print(colored("=========== Try card A on the reader (again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    t.db.assert_query_success(
    f"""
        INSERT INTO time_constraint VALUES(2, 1, 2, '{prev_hour}:{minute}', '{prev_hour}:{minute}', '\x7f')
        ON CONFLICT DO NOTHING;
    """
    )

    print(colored("=========== Try card A on the reader (again, again) ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)

    t.db.assert_query_success(
    """
        DELETE FROM time_constraint WHERE id_time_constraint = 1;
    """
    )

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "rejected", TAG)

    print(colored("=========== Try card B on the reader  ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)
    
    t.db.assert_query_success(
    """
        DELETE FROM time_rule;
    """
    )

    print(colored("=========== Try card A on the reader ===========", "yellow"))
    await t.mqtt.assert_receive_log("reader/TestReader/logs", "accepted", TAG)


# Clean some stuff from previous tests and add cards
@pytest.mark.asyncio
async def test_deletes():
    TAG="Test deletes"
    await t.mqtt.await_connection()

    print(colored("=========== Depersonalize card A on the registrator ===========", "yellow"))
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('delete_app', 2, 3);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("FF"),
    TAG)

    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert ret is not None, "Did not receive UID after personalization"

    print(colored("=========== Depersonalize card B on the registrator ===========", "yellow"))
    await t.query_check_mqtt(
    r"""
        INSERT INTO command(command, id_registrator, id_card)
        VALUES('depersonalize', 2, 2);
    """,
    "registrator/TestRegistrator/command",
    bytes.fromhex("DE"),
    TAG)

    ret = await t.mqtt.await_topic("registrator/TestRegistrator/UID", 10)
    assert ret is not None, "Did not receive UID after personalization"


    t.db.assert_query_success(
    """
        DELETE FROM card;
        DELETE FROM time_rule;
        DELETE FROM reader;
        DELETE FROM registrator;
    """
    )

    print(colored("=========== Readers should now disconnect ===========", "yellow"))

    t.db.assert_query_success(
    """
        DELETE FROM zone;
        DELETE FROM device;
        DELETE FROM config;
        DELETE FROM pacs_object;
        DELETE FROM card_identifier;
    """
    )