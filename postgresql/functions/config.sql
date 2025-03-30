
/*
    Handle insert into config

    - Do nothing, devices will use it when needed
*/
CREATE OR REPLACE FUNCTION config_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on config

    - Update config (if there are device using it)
*/
CREATE OR REPLACE FUNCTION config_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on config

    - Do nothing, cannot be deleted while there are devices using it
*/
CREATE OR REPLACE FUNCTION config_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;