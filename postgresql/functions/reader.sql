
/*
    Handle insert into reader (FOR EACH ROW)

    - Set proper ACLs & publish reader/<mqtt_username>/setup configuration 
*/
CREATE OR REPLACE FUNCTION reader_on_insert()
RETURNS TRIGGER AS $$
BEGIN

    -- Set ACLs
    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'DynSec',
        ( 
        SELECT json_build_object(
            'commands', json_build_array(

                -- Create role
                json_build_object(
                    'command', 'createRole',
                    'rolename', d.mqtt_username || '_role',
                    'allowwildcardsubs', FALSE,
                    'acls', json_build_array(

                        -- allow sending logs
                        json_build_object(
                            'acltype', 'publishClientSend',
                            'topic', 'reader/' || d.mqtt_username || '/logs',
                            'allow', TRUE,
                            'priority', 5
                        ),

                        -- allow reading reader specifig topics
                        json_build_object(
                            'acltype', 'subscribePattern',
                            'topic', 'reader/' || d.mqtt_username || '/#',
                            'allow', TRUE,
                            'priority', 5
                        )
                    )
                ),

                -- Create client with role and group
                json_build_object(
                    'command', 'createClient',
                    'username', d.mqtt_username,
                    'password', d.mqtt_password,

                    'roles', json_build_array(
                        json_build_object(
                            'rolename', d.mqtt_username || '_role',
                            'priority', 5
                        )
                    ),

                    'groups', json_build_array(      -- group created by zone
                        json_build_object(
                            'groupname', NEW.id_zone::text,
                            'priority', 5
                        )
                    )
                )
            )
        ) 
        FROM device d
        JOIN reader USING(id_device)
        WHERE d.id_device = NEW.id_device
        )
    );


    -- Push config
    PERFORM push_new_config_to_devices(
        (SELECT id_config FROM device JOIN reader USING(id_device) WHERE id_device = NEW.id_device),
        NEW.id_device
    );


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on reader (FOR EACH ROW)

    - id_zone -> publish new zone
*/
CREATE OR REPLACE FUNCTION reader_on_update()
RETURNS TRIGGER AS $$
BEGIN

    IF NOT OLD.id_device = NEW.id_device THEN
        RAISE EXCEPTION 'id_device UPDATE is forbidden on reader'; 
    END IF;


    PERFORM push_new_config_to_devices(NEW.id_zone, NEW.id_device);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on reader (FOR EACH ROW)

    - Remove ACLs & persistent config 
*/
CREATE OR REPLACE FUNCTION reader_on_delete()
RETURNS TRIGGER AS $$
BEGIN

    -- Set ACLs
    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'DynSec',
        ( 
        SELECT json_build_object(
            'commands', json_build_array(

                -- Delete role
                json_build_object(
                    'command', 'deleteRole',
                    'rolename', d.mqtt_username || '_role'
                ),

                -- Remove from group  (just to make sure)
                json_build_object(
                    'command', 'removeGroupClient',
                    'groupname', OLD.id_zone::text,
                    'username', d.mqtt_username
                ),

                -- Remove client
                json_build_object(
                    'command', 'deleteClient',
                    'username', d.mqtt_username
                )
            )
        ) 
        FROM device d
        WHERE d.id_device = OLD.id_device
        )
    );

    -- Remove persistent config
    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'remove_config',
        
        json_build_object(
            'topic', 'reader/' || (SELECT mqtt_username FROM device WHERE id_device = OLD.id_device) || '/setup'
        )
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;