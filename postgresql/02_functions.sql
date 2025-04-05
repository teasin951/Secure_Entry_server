
/*
    Update the full whitelist for a specified zone
*/
CREATE OR REPLACE FUNCTION update_full_whitelist_for_zone( zone_id INTEGER )
RETURNS INTEGER AS $$
BEGIN

    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'whitelist_full',

        (
        SELECT json_build_object(
            'topic', 'whitelist/' || cz.id_zone || '/full',
            'whitelist', json_agg(json_build_object(
                'UID', c.uid,
                'time_rules', (
                    SELECT json_agg(json_build_object(
                        'allow_from', tc.allow_from,
                        'allow_to', tc.allow_to,
                        'week_days', tc.week_days
                    ))
                    FROM card_time_rule ctr
                    JOIN time_constraint tc ON ctr.id_time_rule = tc.id_time_rule
                    WHERE ctr.id_card = c.id_card AND ctr.id_zone = cz.id_zone
                )
            ))
        )
        FROM card_zone cz
        JOIN card c ON cz.id_card = c.id_card
        WHERE cz.id_zone = zone_id
        GROUP BY cz.id_zone
        )
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Update whitelist for specified cards (if they are in a zone)

    Operation types can be 'add', 'remove'

    add - only add (or update existing) UIDs
    remove - only remove UIDs
*/
CREATE OR REPLACE FUNCTION update_whitelist_for_cards_in_zone( card_ids INTEGER[], zone_id INTEGER, operation_type TEXT )
RETURNS INTEGER AS $$
BEGIN
    IF card_ids IS NULL THEN
        RETURN NULL;
    END IF;

    /*
        Update full whitelist first to ensure potencial new reader gets it in full even if it misses the relative updates afterwards,
        if it the also gets the updates, no problem, those will either 
            - delete something that the reader does not have in it's whitelist -> no effect
            - add something it already has, which will just update it
    */
    PERFORM update_full_whitelist_for_zone(zone_id);

    -- Insert the task with changes
    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'whitelist_' || operation_type,

        -- create a json array with updates
        (
        SELECT json_agg(card_data) AS result
        FROM unnest(card_ids) AS card_id
        LEFT JOIN LATERAL (
            SELECT json_build_object(
                'UID', c.uid,
                'topic', 'whitelist/' || zone_id || '/' || operation_type,
                'time_rules', (
                    SELECT json_agg(json_build_object(
                        'allow_from', tc.allow_from,
                        'allow_to', tc.allow_to,
                        'week_days', tc.week_days
                    ))
                    FROM card_time_rule ctr
                    JOIN time_constraint tc USING(id_time_rule)
                    WHERE ctr.id_card = card_id AND ctr.id_zone = zone_id
                )
            ) AS card_data
            FROM card c
            JOIN card_zone cz USING(id_card)  -- limit to cards that are in the zone
            WHERE c.id_card = card_id AND cz.id_zone = zone_id
        ) AS data ON true
        )
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Update configurations for devices using specified config
*/
CREATE OR REPLACE FUNCTION push_new_config_to_devices(config_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    readers_array JSONB;
    registrators_array JSONB;
BEGIN

    -- TODO modify to use joins instead?

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


/*
    Check that one card cannot have multiple time rules for the same zone
*/
CREATE OR REPLACE FUNCTION card_has_multiple_timerules_for_zone_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT count(*) FROM card_time_rule ctr WHERE (ctr.id_card, ctr.id_zone) = (NEW.id_card, NEW.id_zone)
    ) > 1 THEN
        RAISE EXCEPTION 'Card cannot have multiple time rules for the same zone';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
