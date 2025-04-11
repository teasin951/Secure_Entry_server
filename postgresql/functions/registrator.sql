
/*
    Handle insert into registrator (FOR EACH ROW)

    - Set proper ACLs & publish registrator/<mqtt_username>/setup
*/
CREATE OR REPLACE FUNCTION registrator_on_insert()
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
                            'topic', 'registrator/' || d.mqtt_username || '/logs',
                            'allow', TRUE,
                            'priority', 5
                        ),

                        -- allow sending UIDs
                        json_build_object(
                            'acltype', 'publishClientSend',
                            'topic', 'registrator/' || d.mqtt_username || '/UID',
                            'allow', TRUE,
                            'priority', 5
                        ),

                        -- allow reading setup
                        json_build_object(
                            'acltype', 'subscribePattern',
                            'topic', 'registrator/' || d.mqtt_username || '/#',  -- allow any subtopic of the registrator
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
                    )
                )
            )
        ) 
        FROM device d
        JOIN registrator USING(id_device)
        WHERE d.id_device = NEW.id_device
        )
    );

    -- Push config
    PERFORM push_new_config_to_devices(
        (SELECT id_config FROM device JOIN registrator USING(id_device) WHERE id_device = NEW.id_device),
        NEW.id_device
    );


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on registrator (FOR EACH ROW)

    SHOULD NOT HAPPEN! Update on registrator should be forbidden
*/
CREATE OR REPLACE FUNCTION registrator_on_update()
RETURNS TRIGGER AS $$
BEGIN

    RAISE EXCEPTION 'Update on registrator is not allowed';

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on registrator (FOR EACH ROW)

    - Remove persistent config & remove ACLs
*/
CREATE OR REPLACE FUNCTION registrator_on_delete()
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
            'topic', 'registrator/' || (SELECT mqtt_username FROM device WHERE id_device = OLD.id_device) || '/setup'
        )
    );


    RETURN OLD;
END;
$$ LANGUAGE plpgsql;