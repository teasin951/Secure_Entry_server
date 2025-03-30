
/*
    Handle insert into reader

    - Set proper ACLs & publish reader/<mqtt_username> configuration 
*/
CREATE OR REPLACE FUNCTION reader_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on reader

    - id_zone -> publish new zone
*/
CREATE OR REPLACE FUNCTION reader_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on reader

    - Remove persistent config & remove ACLs
*/
CREATE OR REPLACE FUNCTION reader_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;