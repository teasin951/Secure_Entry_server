
/*
    Handle insert into zone (FOR EACH ROW)

    - Create ACL group for this zone
*/
CREATE OR REPLACE FUNCTION zone_on_insert()
RETURNS TRIGGER AS $$
BEGIN

    -- Set ACLs
    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'DynSec',

        json_build_object(
            'commands', json_build_array(

                -- Create role                
                json_build_object(
                    'command', 'createRole',
                    'rolename', NEW.id_zone::text || '_zone_role',
                    'allowwildcardsubs', TRUE,
                    'acls', json_build_array(

                        -- allow reading whitelist
                        json_build_object(
                            'acltype', 'subscribePattern',
                            'topic', 'whitelist/' || NEW.id_zone || '/#',
                            'allow', TRUE,
                            'priority', 5
                        ),

                        -- allow requesting whitelist
                        json_build_object(
                            'acltype', 'publishClientSend',
                            'topic', 'whitelist/' || NEW.id_zone || '/request',
                            'allow', TRUE,
                            'priority', 5
                        )
                    )
                ),

                -- Create group
                json_build_object(
                    'command', 'createGroup',
                    'groupname', NEW.id_zone::text,
                    'roles', json_build_array(
                        json_build_object(
                            'rolename', NEW.id_zone::text || '_zone_role',
                            'priority', 5
                        )
                    )
                )
            )
        ) 
    );


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on zone

    - Do nothing, only name and notes can be changed if in use
    - Only check we are not changing id_zone when unused
*/
CREATE OR REPLACE FUNCTION zone_on_update()
RETURNS TRIGGER AS $$
BEGIN

    IF not NEW.id_zone = OLD.id_zone THEN
        RAISE EXCEPTION 'Updating id_zone is forbidden';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on zone (FOR EACH ROW)

    - Delete ACL group
*/
CREATE OR REPLACE FUNCTION zone_on_delete()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO task_queue(task_type, payload)
    VALUES(
        'DynSec',

        json_build_object(
            'commands', json_build_array(

                -- Delete role (just to be sure)
                json_build_object(
                    'command', 'deleteRole',
                    'rolename', OLD.id_zone::text || '_zone_role'
                ),

                -- Delete group
                json_build_object(
                    'command', 'deleteGroup',
                    'groupname', OLD.id_zone::text
                )
            )
        ) 
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;