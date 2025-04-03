-- NOTE: Pin code is not implemented in readers yet


/*
    Handle insert into card
    Expects to have transition table new_rows

    - id_device filled -> issue command (only non bulk inserts)
*/
CREATE OR REPLACE FUNCTION card_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    registrator_id INTEGER;
    card_id INTEGER;
    registrator_mqtt TEXT;
BEGIN
    /* Check that we are not personalizing multiple cards at once */
    IF (SELECT count(id_device) FROM new_rows WHERE id_device IS NOT NULL) > 1 THEN
        RAISE EXCEPTION 'Cards can only be personalized one at a time';
    END IF;


    -- The id_device is now guaranteed to be a registrator and max 1 will be present
    SELECT id_device, id_card 
    INTO registrator_id, card_id 
    FROM new_rows
    WHERE id_device IS NOT NULL;

    IF registrator_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Issue personalize command
    INSERT INTO command(command, id_registrator, id_card)
    VALUES('personalize', registrator_id, card_id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card

    - UID change -> remove old UID from whitelists, add new UID      -- TODO (but you can delete and insert)
*/
CREATE OR REPLACE FUNCTION card_on_update()
RETURNS TRIGGER AS $$
BEGIN
    -- TODO find relevant zones, delete and add to them should do
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card

    Delete on card can be issued by the operator but keep in mind that if the card is not
    depersonalized, our application will take up space on the person's card for no reason

    - Do nothing, the delete will cascade and relevant actions will be handled elsewhere
*/
CREATE OR REPLACE FUNCTION card_on_delete()
RETURNS TRIGGER AS $$
BEGIN

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;