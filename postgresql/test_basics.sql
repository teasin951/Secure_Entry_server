-- Create basic config and zone
INSERT INTO card_identifier(manufacturer, mutual_auth, comm_enc, key_version)
VALUES('Test', '\x0000', '\x00', 1);

INSERT INTO pacs_object(version_major, version_minor, site_code, reissue_code, customer_specific)
VALUES(1, 1, '\x00', 0, '\x00');

INSERT INTO config(appmok, appvok, ocpsk, name, id_card_identifier, id_pacs_object)
VALUES('\x11111111111111111111111111111111', '\x22222222222222222222222222222222', '\x33333333333333333333333333333333', 'Test config', 1, 1);

INSERT INTO zone(name)
VALUES('TestZone'), ('TestZone2');

-------------------------------------------------------------------------------------------

-- Create a device
INSERT INTO device(id_config, name, mqtt_username, mqtt_password)
VALUES(1, 'TestReader', 'TestClient', 'test');

-- Make it a reader
INSERT INTO reader(id_device, id_zone, max_time_rules)
VALUES(1, 1, 2);

-- Try to make it a registrator as well
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO registrator(id_device) VALUES(1);
        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'One device must not be allowed to be both types';
    END IF;

    ROLLBACK;
END $$;


-- Create a second device
INSERT INTO device(id_config, name, mqtt_username, mqtt_password)
VALUES(1, 'TestRegistrator', 'TestClient2', 'test');

-- Make it a registrator
INSERT INTO registrator(id_device) VALUES(2);

-- Try to make it a reader as well
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO reader(id_device, id_zone, max_time_rules)
        VALUES(2, 1, 2);
        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'One device must not be allowed to be both types';
    END IF;

    ROLLBACK; 
END $$;

-- Try to make reader register a card
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO card(name, id_device) VALUES('FaultyCard', 1);
        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'Card must not be allowed to be registered by a reader';
    END IF;

    ROLLBACK; 
END $$;

-----------------------------------------------------------------------------------------------------------

-- Clear task queue
DELETE FROM task_queue WHERE id_registrator = 2;

-- Update UID of a card
INSERT INTO command(command, id_registrator, id_card)
VALUES ('personalize', 2, 3);

-- Clear task queue
DELETE FROM task_queue WHERE id_registrator = 2;

-- Send depersonalize
INSERT INTO command(command, id_registrator)
VALUES ('depersonalize', 2);

-- Clear task queue
DELETE FROM task_queue WHERE id_registrator = 2;

-- Send delete_last
INSERT INTO command(command, id_registrator)
VALUES ('delete_app', 2);

-- Try to issue command to a busy registrator
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO command(command, id_registrator, id_card)
        VALUES ('personalize', 2, 3);
        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'You should not be able to issue command to already busy registrators';
    END IF;

    ROLLBACK; 
END $$;

-- Clear task queue
DELETE FROM task_queue WHERE id_registrator = 2;

-----------------------------------------------------------------------------------------------------------

-- Update card_identifier
UPDATE card_identifier
SET manufacturer = 'Changed';

-- Update pacso
UPDATE pacs_object
SET version_minor = 1;

-- Update config
UPDATE config
SET name = 'ChangedConfig';

-----------------------------------------------------------------------------------------------------------

-- Create new cards in bulk & test that it creates a task
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    INSERT INTO card(name, id_device)
    VALUES
        ('TestCard',  2),
        ('TestCard2', NULL),
        ('TestCard3', NULL),
        ('TestCard4', NULL);

    IF NOT (SELECT count(*) FROM task_queue) = (task_count + 1) THEN
        RAISE EXCEPTION 'Inserting into a card with id_device does not create a task';
    END IF;
END $$;

-- Try to add card without UID to zone
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO card_zone(id_zone, id_card) VALUES(1, 2);
        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'Card must not be allowed to be added to zone without UID';
    END IF;

    ROLLBACK; 
END $$;


-- Delete card
DELETE FROM card WHERE name = 'TestCard4';


-- Mass delete
INSERT INTO card(name) VALUES ('TT'), ('TT'), ('TT');
DELETE FROM card WHERE name = 'TT';


-- Simulate registrator filling UID
UPDATE card
SET uid = '\x11223344556677'
WHERE id_card = 3;

-- Add card to zone
INSERT INTO card_zone
VALUES(3, 1);


-- Try to add cards in bulk with registrators
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO card(name, id_device)
        VALUES
            ('TestCrd',  2),
            ('TestCrd2', 2),
            ('TestCrd3', 2);
        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'Letting multiple cards get registered at once must not be allowed';
    END IF;

    ROLLBACK; 
END $$;

-----------------------------------------------------------------------------------------------------------

-- Create two timerules for zone 1
INSERT INTO time_rule(id_zone, name)
VALUES
	(1, 'TestZone1'),
	(1, 'TestZone2');


-- Add time_rule to a card
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    INSERT INTO card_time_rule VALUES(3, 1, 1);

    IF NOT (SELECT count(*) FROM task_queue) > (task_count + 1) THEN
        RAISE EXCEPTION 'Card added to zone but no whitelist update issued';
    END IF;
END $$;


-- Test that a card cannot have multiple time rules in one zone
DO $$
DECLARE
    success BOOLEAN;
BEGIN
    BEGIN
        INSERT INTO card_time_rule VALUES(3, 2, 1);

        success := TRUE;
    EXCEPTION WHEN OTHERS THEN
        success := FALSE;
    END;

    IF success THEN
        RAISE WARNING 'One card must not be allowed to have multiple time rules for the same zone';
    END IF;

    ROLLBACK; 
END $$;


-- Give card a time rule in a different zone
INSERT INTO time_rule(id_zone, name) VALUES(2, 'RuleZone2');
INSERT INTO card_time_rule VALUES(3, 3, 2);


-- Create time_constraints for rule 1 and rule 2 
-- Test that there have been tasks created (1. whitelist full and 2. whitelist add)
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    INSERT INTO time_constraint(id_time_rule, id_zone, allow_from, allow_to, week_days)
    VALUES
        (1, 1, '01:11', '1:11', '\x7C'),
        (1, 1, '01:22', '01:22', '\x01'),
        (2, 1, '02:11', '02:11', '\x7C');

    IF NOT (SELECT count(*) FROM task_queue) = (task_count + 2) THEN
        RAISE WARNING 'There should have been a task created after time_constraint insert';
    END IF;
END $$;


-- Add different time rule to a different card
UPDATE card
SET uid = '\x22334455667788'
WHERE id_card = 4;


-- Add time_rule to card
INSERT INTO card_time_rule VALUES(4, 2, 1);


-- Test that inserting a new constraint to a card without a zone does not create tasks
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    INSERT INTO time_constraint(id_time_rule, id_zone, allow_from, allow_to, week_days)
    VALUES
        (2, 1, '13:33', '14:44', '\x02');

    IF NOT (SELECT count(*) FROM task_queue) = (task_count) THEN
        RAISE WARNING 'We should not update whitelist on insert to time_constraint when the card is not in a zone';
    END IF;
END $$;


-- Test that inserting a card into card_zone creates tasks
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    INSERT INTO card_zone
    VALUES(4, 1);

    IF NOT (SELECT count(*) FROM task_queue) = (task_count + 2) THEN
        RAISE WARNING 'We should issue a task when adding card to a zone';
    END IF;
END $$;


-- Test that updating a constraint creates tasks
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    UPDATE time_constraint
    SET allow_to = '12:30'
    WHERE id_time_constraint = 1;

    IF NOT (SELECT count(*) FROM task_queue) = (task_count + 2) THEN
        RAISE WARNING 'Updating constraints should create tasks';
    END IF;
END $$;


-- Test that deleting a constraint creates tasks (should have null now as time_rule)
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    DELETE FROM time_constraint
    WHERE id_time_rule = 1;

    IF NOT (SELECT count(*) FROM task_queue) = (task_count + 2) THEN
        RAISE WARNING 'Updating constraints should create tasks';
    END IF;
END $$;


-- Test deleting a rule creates tasks
DO $$
DECLARE
    task_count INTEGER;
BEGIN
    SELECT count(*) INTO task_count FROM task_queue;

    DELETE FROM time_rule
    WHERE id_time_rule = 2;

    IF NOT (SELECT count(*) FROM task_queue) = (task_count + 2) THEN
        RAISE WARNING 'Updating constraints should create tasks';
    END IF;
END $$;