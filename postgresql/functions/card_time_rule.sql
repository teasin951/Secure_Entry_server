/*
    Handle insert into card_time_rule
    
    - Add time rule to whitelist
*/
CREATE OR REPLACE FUNCTION card_time_rule_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on card_time_rule

    - Remove old, add new to whitelist
*/
CREATE OR REPLACE FUNCTION card_time_rule_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card_time_rule

    - Remove time rule from whitelist (delete old, add new without constraints)
*/
CREATE OR REPLACE FUNCTION card_time_rule_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;