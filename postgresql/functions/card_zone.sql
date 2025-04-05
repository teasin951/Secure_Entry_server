
/*
    Push whitelist add modifications on change in card_zone

    Expects to have temp_new_rows table that contains the changed rows
*/
CREATE OR REPLACE FUNCTION update_whitelist_on_card_zone_change()
RETURNS VOID AS $$
DECLARE
    zone_record RECORD;
    card_ids INTEGER[];
BEGIN

    -- Loop through each unique zone in temp_new_rows
    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM temp_new_rows
    LOOP
        -- Get cards for THIS zone
        SELECT array_agg( DISTINCT tnr.id_card ) INTO card_ids 
        FROM temp_new_rows tnr 
        WHERE id_zone = zone_record.id_zone;        -- Filter for current zone


        PERFORM update_full_whitelist_for_zone(zone_record.id_zone);

        -- Update whitelist for THIS zone and its cards
        PERFORM update_whitelist_for_cards_in_zone(
            card_ids, 
            zone_record.id_zone,  -- Current zone ID
            'add'
        );
    END LOOP;

END;
$$ LANGUAGE plpgsql;


/*
    Push whitelist remove modifications on change in card_zone

    Expects to have temp_old_rows table that contains the changed rows
*/
CREATE OR REPLACE FUNCTION remove_from_whitelist_on_card_zone_change()
RETURNS VOID AS $$
DECLARE
    zone_record RECORD;
    card_ids INTEGER[];
BEGIN

    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM temp_old_rows
    LOOP

        PERFORM update_full_whitelist_for_zone(zone_record.id_zone);

        -- Insert the task with changes
        INSERT INTO task_queue(task_type, payload)
        VALUES(
            'whitelist_remove',

            -- create a json array with updates
            (
            SELECT json_build_object(
                'UIDs', (
                    SELECT json_agg(uid) FROM card 
                    JOIN temp_old_rows nr USING(id_card)
                    WHERE nr.id_zone = zone_record.id_zone
                ),

                'topic', 'whitelist/' || zone_record.id_zone || '/remove'
                ) 
            )
        );
    END LOOP;

END;
$$ LANGUAGE plpgsql;


/*
    Handle insert into card_zone

    - Add card with constraints to whitelist
*/
CREATE OR REPLACE FUNCTION card_zone_on_insert()
RETURNS TRIGGER AS $$
BEGIN

    -- Create a temporary table to hold the transition data for the next function 
    CREATE TEMP TABLE temp_new_rows AS
    SELECT * FROM new_rows;

    PERFORM update_whitelist_on_card_zone_change();

    DROP TABLE IF EXISTS temp_new_rows;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card_zone

    - Remove old, add new to whitelist
*/
CREATE OR REPLACE FUNCTION card_zone_on_update()
RETURNS TRIGGER AS $$
DECLARE
    zone_record RECORD;
    card_ids INTEGER[];
BEGIN

    -- Create a temporary table to hold the transition data for the next function 
    CREATE TEMP TABLE temp_old_rows AS
    SELECT * FROM old_rows;

    PERFORM remove_from_whitelist_on_card_zone_change();

    DROP TABLE IF EXISTS temp_old_rows;


    -- Then create add list
    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM new_rows
    LOOP
        -- Get cards for THIS zone
        SELECT array_agg( DISTINCT nr.id_card ) INTO card_ids 
        FROM new_rows nr 
        WHERE id_zone = zone_record.id_zone;        -- Filter for current zone

        -- Update whitelist for THIS zone and its cards
        PERFORM update_whitelist_for_cards_in_zone(
            card_ids, 
            zone_record.id_zone,  -- Current zone ID
            'add'
        );
    END LOOP;


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card_zone

    - Remove cards from whitelist
*/
CREATE OR REPLACE FUNCTION card_zone_on_delete()
RETURNS TRIGGER AS $$
DECLARE
    zone_record RECORD;
BEGIN

    -- Create a temporary table to hold the transition data for the next function 
    CREATE TEMP TABLE temp_old_rows AS
    SELECT * FROM old_rows;

    PERFORM remove_from_whitelist_on_card_zone_change();

    DROP TABLE IF EXISTS temp_old_rows;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;