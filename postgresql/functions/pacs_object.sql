
/*
    Handle insert into pacs_object

    - Do nothing, devices will use it when needed
*/
CREATE OR REPLACE FUNCTION pacs_object_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on pacs_object

    - Update config (if there are device using it)
*/
CREATE OR REPLACE FUNCTION pacs_object_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on pacs_object
    
    - Do nothing, cannot be deleted while there are devices using it
*/
CREATE OR REPLACE FUNCTION pacs_object_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;