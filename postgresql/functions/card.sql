-- NOTE: Pin code is not implemented in readers yet


/*
    Handle insert into card

    Do nothing, card has to be personalized and inserted into tables first
*/
-- No function needed --



/*
    Handle update on card

    - UID change -> remove old UID from whitelists, add new UID if not filling from null
*/
CREATE OR REPLACE FUNCTION card_on_update()
RETURNS TRIGGER AS $$
BEGIN

    -- Updating card_zone triggers delete and insert exactly how we want
    UPDATE card_zone 
    SET id_card = id_card
    WHERE id_card IN(
        SELECT id_card FROM new_rows
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


/*
    Handle delete on card

    Delete on card can be issued by the operator but keep in mind that if the card is not
    depersonalized, our application will take up space on the person's card for no reason

    - Do nothing, the delete will cascade and relevant actions will be handled elsewhere
*/
-- No function needed --
