-- NOTE: Pin code is not implemented in readers yet

/*
    Handle insert into card

    - id_device filled -> personalization command
*/
CREATE OR REPLACE FUNCTION card_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card

    - check erase value
    - id_device change -> personalization command
    - UID change -> remove from old UID from whitelists, add new UID
*/
CREATE OR REPLACE FUNCTION card_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card

    THIS SHOULD NEVER HAPPEN!

    Deletion should be handled by the database on the 'erase' value change via SECURITY DEFINER function
*/
CREATE OR REPLACE FUNCTION card_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;