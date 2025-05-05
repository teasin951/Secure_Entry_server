from complete_func import Prober
import pytest


#
# These test the system API.
#
# Tests should be executed sequentially, but each test can be executed on it's own
# if the database is in the state it is expected to be from the previous tests
#


t = Prober()


@pytest.mark.asyncio
async def test_db_insert():
    TAG = "Basic DB insert"

    # Tables that do not need other tables populated to be inserted into
    t.db.assert_query_success(
    r"""
        INSERT INTO card_identifier(manufacturer, mutual_auth, comm_enc, customer_id, key_version)
        VALUES('Test', '\xCA02', '\x02', '\x00', 1);

        INSERT INTO pacs_object(version_major, version_minor, site_code, credential_id, reissue_code, customer_specific)
        VALUES(1, 1, '\xFFAAFFAAFF', '\x00110022', 34, '\x112233445566778899AABBCCDDEEFF0011223344');
    """,
    TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO config(appmok, appvok, ocpsk, name, id_card_identifier, id_pacs_object)
        VALUES('\x11111111111111111111111111111111', '\x22222222222222222222222222222222', 
               '\x33333333333333333333333333333333', 'Test config', 1, 1);
    """,
    TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO zone(name)
        VALUES('TestZone1'), ('TestZone2');
    """,
    TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO device(id_device, id_config, name, mqtt_username, mqtt_password)
        VALUES(1, 1, 'TestReader', 'TestReader', 'test'), 
              (2, 1, 'TestRegistrator', 'TestRegistrator', 'test');

    """,
    TAG)


@pytest.mark.asyncio
async def test_insert_card():
    TAG = "Insert card"
    await t.mqtt.await_connection()

    t.db.assert_query_success(
    r"""
        INSERT INTO card(id_card, name) VALUES(1, 'TestCard');
    """,
    TAG)

    # Card without UID cannot be in zone
    t.db.assert_query_fail(
    r"""
        INSERT INTO card_zone VALUES(1, 1);
    """,
    TAG)

    t.db.assert_query_success(
    r"""
        UPDATE card SET uid='\x11223344556677' WHERE id_card=1;
    """,
    TAG)

    t.db.assert_query_fail(
    r"""
        INSERT INTO card(name, uid) VALUES('FailCard', \x11223344556677');
    """,
    TAG)

    await t.query_check_mqtt_cbor(
    r"""
        INSERT INTO card_zone VALUES(1, 1);
    """,
    "whitelist/1/add",
    [bytes.fromhex("11223344556677")],
    TAG)


@pytest.mark.asyncio
async def test_update_card():
    TAG="Update card"
    await t.mqtt.await_connection()

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        UPDATE card SET uid='\x00112233445566' WHERE id_card = 1;
    """,
    [
        {
            "topic": "whitelist/1/remove",
            "payload": [[bytes.fromhex("11223344556677")]]
        },
        {
            "topic": "whitelist/1/add",
            "payload": [[bytes.fromhex("00112233445566")]]
        }
    ],
    TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO time_rule(id_time_rule, id_zone, name) VALUES(1, 1, 'TestRule');
    """,
    TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO time_constraint(id_time_constraint, id_time_rule, id_zone, allow_from, allow_to, week_days) 
        VALUES(1, 1, 1, '8:22', '16:44', '\x7C');
    """,
    TAG)

    await t.query_check_mqtt_cbor(
    r"""
        INSERT INTO card_time_rule VALUES(1, 1, 1);
    """,
    "whitelist/1/add",
    [bytes.fromhex("00112233445566"), {"t": bytes.fromhex("7C0816102C")}],
    TAG)


@pytest.mark.asyncio
async def test_insert_bulk():
    TAG="Bulk insert"
    await t.mqtt.await_connection()

    t.db.assert_query_success(
    r"""
        INSERT INTO card(id_card, name, uid)
        VALUES(2, 'TestCard2', '\x22334455667788'), 
              (3, 'TestCard3', '\x33445566778899'), 
              (4, 'TestCard4', '\x44556677889900');
    """,
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        INSERT INTO card_zone
        VALUES(2, 1), (3, 1), (4, 1);
    """,
    "whitelist/1/add",
    [
        [bytes.fromhex("22334455667788")],
        [bytes.fromhex("33445566778899")],
        [bytes.fromhex("44556677889900")]
    ],
    TAG)


    await t.query_check_mqtt_cbor(
    r"""
        INSERT INTO time_constraint(id_time_constraint, id_time_rule, id_zone, allow_from, allow_to, week_days) 
        VALUES(2, 1, 1, '9:33', '17:55', '\x7C'), 
              (3, 1, 1, '7:11', '15:33', '\x7C'), 
              (4, 1, 1, '6:00', '14:11', '\x7C');
    """,
    "whitelist/1/add",
    [
        bytes.fromhex("00112233445566"), {"t": bytes.fromhex("7C0816102C")},
                                         {"t": bytes.fromhex("7C09211137")},
                                         {"t": bytes.fromhex("7C070B0F21")},
                                         {"t": bytes.fromhex("7C06000E0B")}
    ],
    TAG)


@pytest.mark.asyncio
async def test_update_constraints():
    TAG="Updates"
    await t.mqtt.await_connection()

    await t.query_check_mqtt_cbor(
    r"""
        UPDATE time_constraint SET week_days = '\x00'
        WHERE id_time_constraint = 1; 
    """,
    "whitelist/1/add",
    [
        bytes.fromhex("00112233445566"), {"t": bytes.fromhex("000816102C")},
                                         {"t": bytes.fromhex("7C09211137")},
                                         {"t": bytes.fromhex("7C070B0F21")},
                                         {"t": bytes.fromhex("7C06000E0B")}
    ],
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        INSERT INTO card_time_rule 
        VALUES(2, 1, 1), (3, 1, 1);
    """,
    "whitelist/1/add",
    [
        [
            bytes.fromhex("22334455667788"), {"t": bytes.fromhex("000816102C")},
                                         {"t": bytes.fromhex("7C09211137")},
                                         {"t": bytes.fromhex("7C070B0F21")},
                                         {"t": bytes.fromhex("7C06000E0B")}
        ],
        [
            bytes.fromhex("33445566778899"), {"t": bytes.fromhex("000816102C")},
                                         {"t": bytes.fromhex("7C09211137")},
                                         {"t": bytes.fromhex("7C070B0F21")},
                                         {"t": bytes.fromhex("7C06000E0B")}
        ]
    ],
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        UPDATE time_constraint 
        SET week_days = '\x1C'
        WHERE week_days = '\x7C';
    """,
    "whitelist/1/add",
    [
        [
            bytes.fromhex("00112233445566"), {"t": bytes.fromhex("000816102C")},
                                            {"t": bytes.fromhex("1C09211137")},
                                            {"t": bytes.fromhex("1C070B0F21")},
                                            {"t": bytes.fromhex("1C06000E0B")}
        ],
        [
            bytes.fromhex("22334455667788"), {"t": bytes.fromhex("000816102C")},
                                         {"t": bytes.fromhex("1C09211137")},
                                         {"t": bytes.fromhex("1C070B0F21")},
                                         {"t": bytes.fromhex("1C06000E0B")}
        ],
        [
            bytes.fromhex("33445566778899"), {"t": bytes.fromhex("000816102C")},
                                         {"t": bytes.fromhex("1C09211137")},
                                         {"t": bytes.fromhex("1C070B0F21")},
                                         {"t": bytes.fromhex("1C06000E0B")}
        ]
    ],
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        DELETE FROM time_constraint 
        WHERE not id_time_constraint = 1;
    """,
    "whitelist/1/add",
    [
        [
            bytes.fromhex("00112233445566"), {"t": bytes.fromhex("000816102C")}
        ],
        [
            bytes.fromhex("22334455667788"), {"t": bytes.fromhex("000816102C")}
        ],
        [
            bytes.fromhex("33445566778899"), {"t": bytes.fromhex("000816102C")}
        ]
    ],
    TAG)

    t.db.assert_query_fail(
    """
        UPDATE time_rule
        SET id_zone = 2
        WHERE id_time_rule = 1;
    """
    )

    await t.query_check_mqtt_cbor_sequence(
    r"""
        DELETE FROM time_rule;
    """,
    "whitelist/1/add",
    [
        [
            bytes.fromhex("00112233445566")
        ],
        [
            bytes.fromhex("22334455667788")
        ],
        [
            bytes.fromhex("33445566778899")
        ]
    ],
    TAG)


@pytest.mark.asyncio
async def test_change_card_zone():
    TAG="Card_zone changes"
    await t.mqtt.await_connection()


    t.db.assert_query_success(
    r"""
        INSERT INTO time_rule(id_time_rule, id_zone, name)
        VALUES(2, 2, 'TimeRule2');
    """
    )

    t.db.assert_query_success(
    r"""
        INSERT INTO time_constraint(id_time_constraint, id_time_rule, id_zone, allow_from, allow_to, week_days) 
        VALUES(5, 2, 2, '9:33', '17:55', '\x7C');
    """
    )

    t.db.assert_query_success(
    r"""
        INSERT INTO card_time_rule
        VALUES(4, 2, 2);
    """
    )

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        UPDATE card_zone SET id_zone = 2 WHERE id_card = 4 OR id_card = 3;
    """,
    [
        {
            "topic": "whitelist/1/remove",
            "payload": [[bytes.fromhex("44556677889900")], [bytes.fromhex("33445566778899")]]
        },
        {
            "topic": "whitelist/2/add",
            "payload": [[bytes.fromhex("33445566778899")], 
                        [bytes.fromhex("44556677889900"), {"t": bytes.fromhex("7C09211137")}]]
        }
    ],
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        INSERT INTO card_time_rule VALUES(3, 2, 2);
    """,
    "whitelist/2/add",
    [
        [bytes.fromhex("33445566778899"), {"t": bytes.fromhex("7C09211137")}], 
    ],
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        DELETE FROM card_zone WHERE id_zone = 1;
    """,
    "whitelist/1/remove",
    [
        [bytes.fromhex("00112233445566")],
        [bytes.fromhex("22334455667788")]
    ],
    TAG)

    t.db.assert_query_success(
    r"""
        INSERT INTO time_rule(id_time_rule, id_zone, name)
        VALUES(3, 2, 'TimeRule3');
    """
    )

    t.db.assert_query_success(
    r"""
        INSERT INTO time_constraint(id_time_constraint, id_time_rule, id_zone, allow_from, allow_to, week_days) 
        VALUES(6, 3, 2, '1:33', '17:55', '\x7C');
    """
    )

    await t.query_check_mqtt_cbor_sequence(
    r"""
        UPDATE card_time_rule
        SET id_time_rule = 3
        WHERE id_time_rule = 2;
    """,
    "whitelist/2/add",
    [
        [bytes.fromhex("33445566778899"), {"t": bytes.fromhex("7C01211137")}], 
        [bytes.fromhex("44556677889900"), {"t": bytes.fromhex("7C01211137")}]
    ],
    TAG)

    await t.query_check_mqtt_cbor_sequence(
    r"""
        DELETE FROM card_time_rule
        WHERE id_time_rule = 3;
    """,
    "whitelist/2/add",
    [
        [bytes.fromhex("33445566778899")], 
        [bytes.fromhex("44556677889900")]
    ],
    TAG)


@pytest.mark.asyncio
async def test_update_zone():
    TAG="Zone changes"

    t.db.assert_query_success(
    r"""
        INSERT INTO zone(id_zone, name) VALUES(5, 'Test');
    """,
    TAG
    )

    t.db.assert_query_fail(
    r"""
        UPDATE zone SET id_zone = 6 WHERE id_zone = 5;
    """,
    TAG
    )


@pytest.mark.asyncio
async def test_mult_zone_card_update():
    TAG="Card in multiple zones update"
    await t.mqtt.await_connection()

    await t.query_check_mqtt_cbor_sequence(
    r"""
        INSERT INTO card_zone VALUES(4, 1);
    """,
    "whitelist/1/add",
    [
        [bytes.fromhex("44556677889900")], 
    ],
    TAG)

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        UPDATE card SET uid = '\x00445566778899' WHERE id_card = 4;
    """,
    [
        {
            "topic": "whitelist/1/remove",
            "payload": [[bytes.fromhex("44556677889900")]]
        },
        {
            "topic": "whitelist/2/remove",
            "payload": [[bytes.fromhex("44556677889900")]]
        },
        {
            "topic": "whitelist/1/add",
            "payload": [[bytes.fromhex("00445566778899")]]
        },
        {
            "topic": "whitelist/2/add",
            "payload": [[bytes.fromhex("00445566778899")]]
        }
    ],
    TAG)

    await t.query_check_mqtt_cbor_multi_sequence(
    r"""
        DELETE FROM card WHERE id_card = 4;
    """,
    [
        {
            "topic": "whitelist/1/remove",
            "payload": [[bytes.fromhex("00445566778899")]]
        },
        {
            "topic": "whitelist/2/remove",
            "payload": [[bytes.fromhex("00445566778899")]]
        },
    ],
    TAG)



