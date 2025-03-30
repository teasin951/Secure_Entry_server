/*
    Handle insert into time_constraint

    - check if the associated time rule has any cards in card_time_rule and update the whitelist accordingly
*/
CREATE OR REPLACE FUNCTION time_constraint_on_insert()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle update on time_constraint

    - check if the associated time rule has any cards in card_time_rule and update the whitelist accordingly
*/
CREATE OR REPLACE FUNCTION time_constraint_on_update()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on time_constraint

    - check if the associated time rule has any cards in card_time_rule and update the whitelist accordingly
*/
CREATE OR REPLACE FUNCTION time_constraint_on_delete()
RETURNS TRIGGER AS $$
BEGIN


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;