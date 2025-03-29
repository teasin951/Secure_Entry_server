-- Create basic config and zone
INSERT INTO card_identifier(manufacturer, mutual_auth, comm_enc, key_version)
VALUES('Test', '\x0000', '\x00', 1);

INSERT INTO pacs_object(version_major, version_minor, site_code, reissue_code, customer_specific)
VALUES(1, 1, '\x00', 0, '\x00');

INSERT INTO config(appmok, appvok, ocpsk, name, id_card_identifier, id_pacs)
VALUES('\x00112233445566778899AABBCCDDEEFF', '\x00112233445566778899AABBCCDDEEFF', '\x00112233445566778899AABBCCDDEEFF', 'Test config', 1, 1);

INSERT INTO zone(name)
VALUES('Test zone');

-- Create a registrator
INSERT INTO reader(id_config, id_zone, name, mqtt_username, mqtt_password, registrator, max_time_rules)
VALUES(1, 1, 'TestReader', 'TestClient', 'test', TRUE, 2);

-- Create a reader
INSERT INTO reader(id_config, id_zone, name, mqtt_username, mqtt_password, registrator, max_time_rules)
VALUES(1, 1, 'TestReader2', 'TestClient2', 'test', FALSE, 2);

-- Create a new card entry
INSERT INTO card(name, id_reader)
VALUES('TestCard', 1);

-- Simulate registrator filling UID
UPDATE card
SET uid = '\x11223344556677'
WHERE id_card = 1;

-- Add card to zone
INSERT INTO card_zone
VALUES(1, 1);
