
/*
    Handle insert into card_identifier

    - Do nothing, devices will use it when needed
*/
CREATE OR REPLACE FUNCTION card_identifier_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card_identifier

    - Update config (if there are device using it)
*/
CREATE OR REPLACE FUNCTION card_identifier_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card_identifier

    - Do nothing, cannot be deleted while there are devices using it
*/
CREATE OR REPLACE FUNCTION card_identifier_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;