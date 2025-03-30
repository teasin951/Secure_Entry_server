
/*
    Handle insert into registrator

    - Set proper ACLs & publish registrator/<mqtt_username>/config
*/
CREATE OR REPLACE FUNCTION registrator_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on registrator

    SHOULD NOT HAPPEN! Update on registrator should be forbidden
*/
CREATE OR REPLACE FUNCTION registrator_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on registrator

    - Remove persistent config & remove ACLs
*/
CREATE OR REPLACE FUNCTION registrator_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;