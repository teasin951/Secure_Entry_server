
/*
    Update configurations for devices using specified config
*/
CREATE OR REPLACE FUNCTION push_new_config_to_devices(config_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    readers_array JSONB;
    registrators_array JSONB;
BEGIN

    -- Make array with reader topics and respective zones to update
    SELECT json_agg(json_build_object(
        'topic', 'reader/' || mqtt_username || '/setup',
        'zone', (SELECT id_zone FROM reader WHERE id_device IN (
            SELECT id_device FROM device WHERE id_config = config_id
        )))
        ) INTO readers_array 
    FROM device
    WHERE id_config = config_id AND id_device IN (
        SELECT id_device FROM reader 
    ); 

    -- Make array with registrators and their APPMOK
    SELECT json_agg(json_build_object(
        'topic', 'registrator/' || mqtt_username || '/setup',
        'appmok', (SELECT appmok::text FROM config WHERE id_config = config_id))
        ) INTO registrators_array 
    FROM device
    WHERE id_config = config_id AND id_device IN (
        SELECT id_device FROM registrator
    ); 

    -- Put to queue
    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'config',
        
        json_build_object(
            'devices', json_build_object(
                'readers', readers_array,
                'registrators', registrators_array
            ),

            'config', json_build_object(
                'APPVOK', (SELECT appvok FROM config WHERE id_config = config_id),
                'OCPSK', (SELECT ocpsk FROM config WHERE id_config = config_id),
                'CardID', (SELECT row_to_json(card_identifier) FROM card_identifier WHERE id_card_identifier = (
                    SELECT id_card_identifier FROM config WHERE id_config = config_id
                )),
                'PACSO', (SELECT row_to_json(pacs_object) FROM pacs_object WHERE id_pacs_object = (
                    SELECT id_pacs_object FROM config WHERE id_config = config_id
                ))
            )
        )
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


\i functions/card_identifier.sql
\i functions/card_time_rule.sql
\i functions/card_zone.sql
\i functions/card.sql
\i functions/config.sql
\i functions/device.sql
\i functions/pacs_object.sql
\i functions/reader.sql
\i functions/registrator.sql
\i functions/time_constraint.sql
\i functions/time_rule.sql
\i functions/zone.sql
\i functions/command.sql


/*
    Check that we are not trying to make current registrator reader as well
*/
CREATE OR REPLACE FUNCTION reader_is_not_registrator_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(
        SELECT * FROM registrator AS r
        WHERE r.id_device = NEW.id_device
    ) THEN
        RAISE EXCEPTION 'This device is already a registrator';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Check that we are not trying to make current reader registrator as well
*/
CREATE OR REPLACE FUNCTION registrator_is_not_reader_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(
        SELECT * FROM reader AS r
        WHERE r.id_device = NEW.id_device
    ) THEN
        RAISE EXCEPTION 'This device is already a reader';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Check that when adding card to a zone, that it already has UID filled in.

    This is kinda annoying but for me the simples option to implement this
    as the whitelist cannot be created until we have the UID, thus any 
    managements system will have to wait until the card is
    registered before it assigns it to zones.

    TODO; THIS CAN BE HANDLED BY POSTGRES using retry logic or by queue table and pg_cron
*/
CREATE OR REPLACE FUNCTION card_has_uid_for_zone_check()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM card
		WHERE id_card = NEW.id_card
		AND uid IS NOT NULL
		AND uid <> ''
    ) THEN
        RAISE EXCEPTION 'Card has to have UID before it is added to a zone';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
