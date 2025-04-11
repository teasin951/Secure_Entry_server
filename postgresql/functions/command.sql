
/*
    Handle insert into command

    - put the selected command to task_queue
*/
CREATE OR REPLACE FUNCTION command_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    registrator_mqtt TEXT;
BEGIN
    /* Check that there are no pending commands for the same registrator */
    IF EXISTS( SELECT 1 FROM task_queue WHERE id_registrator = NEW.id_registrator ) THEN
        RAISE EXCEPTION 'Cannot issue command, selected registrator is already busy';
    END IF;


    -- Get registrators MQTT username
    SELECT mqtt_username INTO registrator_mqtt FROM device
    WHERE id_device = NEW.id_registrator;

    -- Put task to queue
    INSERT INTO task_queue(task_type, payload, id_registrator)
    VALUES (
        NEW.command::text, 

        json_build_object(
            'topic', 'registrator/' || registrator_mqtt || '/command',
            'username', registrator_mqtt,
            'id_card', NEW.id_card
        ),

        NEW.id_registrator
    );

    -- We don't need to store the command
    DELETE FROM command WHERE id_command = NEW.id_command;

    RETURN NULL;  
END;
$$ LANGUAGE plpgsql;