/*
    Handle insert into time_rule

    - Do nothing, time rule has to be assigned first to have effect
*/
CREATE OR REPLACE FUNCTION time_rule_on_insert()
RETURNS TRIGGER AS $$
BEGIN

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on time_rule

    - Do nothing, id_zone and id_time_rule are identifying - cannot be changed - name and notes are unimportant
*/
CREATE OR REPLACE FUNCTION time_rule_on_update()
RETURNS TRIGGER AS $$
BEGIN

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on time_rule

    - Do nothing
        after this the delete will cascade to time_constraints, but when they will try to select dependencies
        there won't be any, thus nothing will happen. card_time_rule delete will handle whitelist modifications
*/
CREATE OR REPLACE FUNCTION time_rule_on_delete()
RETURNS TRIGGER AS $$
BEGIN

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;