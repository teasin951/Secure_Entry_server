
/*
    Handle insert into device

    - Do nothing, only when the device becomes a registrator or a reader we can do something
*/
-- No function needed --


/*
    Handle update on device  (FOR EACH ROW)

    - id_config -> publish new config
    - mqtt_(username, password, client_id) -> update ACLs & remove persistent message & publish new
        or maybe don't implement and restrict update on these as it's a weird and complex operation
*/
CREATE OR REPLACE FUNCTION device_on_update()
RETURNS TRIGGER AS $$
BEGIN

    IF NOT (NEW.mqtt_username, NEW.mqtt_password, NEW.mqtt_client_id) = (OLD.mqtt_username, OLD.mqtt_password, OLD.mqtt_client_id) THEN
        RAISE EXCEPTION 'Updating MQTT information is not yet supported';
    END IF;

    IF NOT NEW.id_config = OLD.id_config THEN
        PERFORM push_new_config_to_devices(NEW.id_config, NEW.id_device);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on device  (FOR EACH ROW)

    - Do nothing, reader or registrator tables will handle it
*/
-- No function needed --