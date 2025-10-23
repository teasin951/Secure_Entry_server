
/*
    Push whitelist modifications on change in card_time_rule

    Expects to have temp_new_rows table that contains the changed rows
*/
CREATE OR REPLACE FUNCTION update_whitelist_on_card_time_rule_change()
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
        JOIN card_zone USING(id_card, id_zone)      -- To get only cards that are in a zone
        WHERE id_zone = zone_record.id_zone;        -- Filter for current zone

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
    Handle insert into card_time_rule
    
    - Add time rule to whitelist
*/
CREATE OR REPLACE FUNCTION card_time_rule_on_insert()
RETURNS TRIGGER AS $$
BEGIN

    -- Create a temporary table to hold the transition data for the next function 
    CREATE TEMP TABLE temp_new_rows AS
    SELECT * FROM new_rows;

    PERFORM update_whitelist_on_card_time_rule_change();

    DROP TABLE IF EXISTS temp_new_rows;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card_time_rule

    - Update whitelist
*/
CREATE OR REPLACE FUNCTION card_time_rule_on_update()
RETURNS TRIGGER AS $$
BEGIN

    -- Create a temporary table to hold the transition data for the next function 
    CREATE TEMP TABLE temp_new_rows AS
    SELECT * FROM new_rows;

    PERFORM update_whitelist_on_card_time_rule_change();

    DROP TABLE IF EXISTS temp_new_rows;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card_time_rule

    - Remove time rule from whitelist (make it have no constraints)
*/
CREATE OR REPLACE FUNCTION card_time_rule_on_delete()
RETURNS TRIGGER AS $$
BEGIN

    -- Create a temporary table to hold the transition data for the next function 
    CREATE TEMP TABLE temp_new_rows AS
    SELECT * FROM old_rows;

    PERFORM update_whitelist_on_card_time_rule_change();

    DROP TABLE IF EXISTS temp_new_rows;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;