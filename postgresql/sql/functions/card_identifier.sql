
/*
    Handle insert into card_identifier

    - Do nothing, devices will use it when needed
*/
-- No function needed --


/*
    Handle update on card_identifier (FOR EACH ROW)

    - Update config (if there are devices using it)
*/
CREATE OR REPLACE FUNCTION card_identifier_on_update()
RETURNS TRIGGER AS $$
BEGIN

    PERFORM push_new_config_to_devices( 
        (SELECT id_config FROM config WHERE id_card_identifier = NEW.id_card_identifier) 
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card_identifier

    - Do nothing, cannot be deleted while there are devices using it
*/
-- No function needed --