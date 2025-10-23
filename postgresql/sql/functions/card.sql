-- NOTE: Pin code is not implemented in readers yet


/*
    Handle insert into card

    Do nothing, card has to be personalized and inserted into tables first
*/
-- No function needed --



/*
    Handle update on card

    - UID change -> remove old UID from whitelists, add new UID if not filling from null
*/
CREATE OR REPLACE FUNCTION card_on_update_before()
RETURNS TRIGGER AS $$
BEGIN

    -- If the card did not have UID, we do not need to update card_zone
    IF OLD.uid IS NULL THEN
        RETURN NEW;
    END IF;


    -- Remember what zones the card was in
    CREATE TEMP TABLE temp_card_table AS
        SELECT * FROM card_zone
        WHERE id_card = OLD.id_card;

    -- Delete will create whitelist remove task
    DELETE FROM card_zone WHERE id_card = OLD.id_card;


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION card_on_update_after()
RETURNS TRIGGER AS $$
BEGIN

    -- If the card did not have UID, we do not need to update card_zone
    IF OLD.uid IS NULL THEN
        RETURN NEW;
    END IF;


    -- Insert the same thing back, this will create whitelist add task
    INSERT INTO card_zone(id_card, id_zone)
    SELECT id_card, id_zone FROM temp_card_table;


    -- Drop the temporary table
    DROP TABLE IF EXISTS temp_card_table;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card

    Delete on card can be issued by the operator but keep in mind that if the card is not
    depersonalized, your application will take up space on the person's card for no reason
*/

-- To ensure always having the deleted_card_zones
CREATE OR REPLACE FUNCTION card_on_delete_before_statement()
RETURNS TRIGGER AS $$
BEGIN
    -- Create temp table
    CREATE TEMP TABLE IF NOT EXISTS deleted_card_zones (
        id_zone INTEGER,
        uid BYTEA
    );
    -- Clear any existing data to avoid leftovers from previous operations
    TRUNCATE deleted_card_zones;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Fill deleted_card_zones
CREATE OR REPLACE FUNCTION card_on_delete_before()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO deleted_card_zones (id_zone, uid)
    SELECT cz.id_zone, OLD.uid
    FROM card_zone cz
    WHERE cz.id_card = OLD.id_card;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- Push changes to task_queue
CREATE OR REPLACE FUNCTION card_on_delete_after()
RETURNS TRIGGER AS $$
DECLARE
    zone_record RECORD;
    remove_json JSON;
BEGIN

    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM deleted_card_zones
    LOOP

        SELECT COALESCE(json_agg(uid), '[]'::json) INTO remove_json
        FROM deleted_card_zones
        WHERE id_zone = zone_record.id_zone;

        -- No point inserting into task_queue if there is nothing
        IF json_array_length(remove_json) > 0 THEN

            -- Insert the task with changes
            INSERT INTO task_queue(task_type, payload)
            VALUES(
                'whitelist_remove',

                -- create a json array with updates
                (
                SELECT json_build_object(
                    'topic', 'whitelist/' || zone_record.id_zone || '/remove',
                    'UIDs', remove_json
                    ) 
                )
            );

        END IF;
    END LOOP;


    DROP TABLE IF EXISTS deleted_card_zones;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
