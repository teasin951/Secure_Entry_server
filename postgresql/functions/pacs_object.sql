
/*
    Handle insert into pacs_object

    - Do nothing, devices will use it when needed
*/
-- No function needed --



/*
    Handle update on pacs_object (FOR EACH ROW)

    - Update config (if there are device using it)
*/
CREATE OR REPLACE FUNCTION pacs_object_on_update()
RETURNS TRIGGER AS $$
BEGIN

    PERFORM push_new_config_to_devices( 
        (SELECT id_config FROM config WHERE id_pacs_object = NEW.id_pacs_object) 
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on pacs_object
    
    - Do nothing, cannot be deleted while there are devices using it
*/
-- No function needed --