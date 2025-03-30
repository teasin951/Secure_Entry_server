/*
    Handle insert into card_zone

    - Add card with constraints to whitelist
*/
CREATE OR REPLACE FUNCTION card_zone_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card_zone

    - Remove old, add new to whitelist
*/
CREATE OR REPLACE FUNCTION card_zone_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card_zone

    - Remove card from whitelist
        Should test if there is a zone as it might have been deleted prior, and then there is nothing to do
*/
CREATE OR REPLACE FUNCTION card_zone_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;