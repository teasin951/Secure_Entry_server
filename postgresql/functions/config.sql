
/*
    Handle insert into config

    - Do nothing, devices will use it when needed
*/
-- No function needed --


/*
    Handle update on config (FOR EACH ROW)

    - Update config (if there are device using it)
*/
CREATE OR REPLACE FUNCTION config_on_update()
RETURNS TRIGGER AS $$
BEGIN

    PERFORM push_new_config_to_devices(NEW.id_config);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on config

    - Do nothing, cannot be deleted while there are devices using it
*/
-- No function needed --