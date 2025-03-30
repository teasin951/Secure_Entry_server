
/*
    Handle insert into device

    - Do nothing, only when the device becomes a registrator or a reader we can do something
*/
CREATE OR REPLACE FUNCTION device_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on device

    - id_config -> publish new config
    - mqtt_(username, password, client_id) -> update ACLs & remove persistent message & publish new
        or maybe don't implement and restrict update on these as it's a weird and complex operation
*/
CREATE OR REPLACE FUNCTION device_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on device

    - Remove persistent messages & remove ACLs (if exist)
*/
CREATE OR REPLACE FUNCTION device_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;