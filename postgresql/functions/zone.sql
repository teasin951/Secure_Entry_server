
/*
    Handle insert into zone

    - Create ACL group for this zone
*/
CREATE OR REPLACE FUNCTION zone_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on zone

    - Do nothing, only name and notes can be changed
*/
CREATE OR REPLACE FUNCTION zone_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on zone

    - Delete ACL group & clear persistent full whitelist
*/
CREATE OR REPLACE FUNCTION zone_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;