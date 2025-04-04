/*
    Handle insert into time_constraint 

    - check if the associated time rule has any cards in card_time_rule and update the whitelist accordingly
*/
CREATE OR REPLACE FUNCTION time_constraint_on_insert()
RETURNS TRIGGER AS $$
DECLARE
  zone_record RECORD;
  card_ids INTEGER[];
BEGIN

    -- Loop through each unique zone in new_rows
    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM new_rows
    LOOP
    -- Get cards for THIS zone
    SELECT array_agg(id_card) INTO card_ids 
    FROM card_time_rule
    WHERE (id_zone, id_time_rule) IN (
        SELECT id_zone, id_time_rule 
        FROM new_rows 
        WHERE id_zone = zone_record.id_zone  -- Filter for current zone
    );

    -- Update whitelist for THIS zone and its cards
    PERFORM update_whitelist_for_cards_in_zone(
        card_ids, 
        zone_record.id_zone,  -- Current zone ID
        'add'  -- Add as we want to update existing values (if there are none, the card is not in zone and won't be updated)
    );
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on time_constraint

    - check if the associated time rule has any cards in card_time_rule and update the whitelist accordingly
*/
CREATE OR REPLACE FUNCTION time_constraint_on_update()
RETURNS TRIGGER AS $$
DECLARE
  zone_record RECORD;
  card_ids INTEGER[];
BEGIN

    -- Loop through each unique zone in new_rows
    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM new_rows
    LOOP
    -- Get cards for THIS zone
    SELECT array_agg(id_card) INTO card_ids 
    FROM card_time_rule
    WHERE (id_zone, id_time_rule) IN (
        SELECT id_zone, id_time_rule 
        FROM new_rows 
        WHERE id_zone = zone_record.id_zone  -- Filter for current zone
    );

    -- Update whitelist for THIS zone and its cards
    PERFORM update_whitelist_for_cards_in_zone(
        card_ids, 
        zone_record.id_zone,  -- Current zone ID
        'add'  -- Add as we want to update existing values (if there are none, the card is not in zone and won't be updated)
    );
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on time_constraint

    - check if the associated time rule has any cards in card_time_rule and update the whitelist accordingly
*/
CREATE OR REPLACE FUNCTION time_constraint_on_delete()
RETURNS TRIGGER AS $$
DECLARE
  zone_record RECORD;
  card_ids INTEGER[];
BEGIN

    -- Loop through each unique zone in new_rows
    FOR zone_record IN 
        SELECT DISTINCT id_zone FROM old_rows
    LOOP
    -- Get cards for THIS zone
    SELECT array_agg(id_card) INTO card_ids 
    FROM card_time_rule
    WHERE (id_zone, id_time_rule) IN (
        SELECT id_zone, id_time_rule 
        FROM old_rows 
        WHERE id_zone = zone_record.id_zone  -- Filter for current zone
    );

    -- Update whitelist for THIS zone and its cards
    PERFORM update_whitelist_for_cards_in_zone(
        card_ids, 
        zone_record.id_zone,  -- Current zone ID
        'add'  -- Add as we want to update existing values
    );
    END LOOP;


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;