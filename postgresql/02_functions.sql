\i functions/card_identifier.sql
\i functions/card_time_rule.sql
\i functions/card_zone.sql
\i functions/card.sql
\i functions/config.sql
\i functions/device.sql
\i functions/pacs_object.sql
\i functions/reader.sql
\i functions/registrator.sql
\i functions/time_constraint.sql
\i functions/time_rule.sql
\i functions/zone.sql


/*
    Check that we are not trying to make current registrator reader as well
*/
CREATE OR REPLACE FUNCTION reader_is_not_registrator_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(
        SELECT * FROM registrator AS r
        WHERE r.id_device = NEW.id_device
    ) THEN
        RAISE EXCEPTION 'This device is already registrator';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Check that we are not trying to make current reader registrator as well
*/
CREATE OR REPLACE FUNCTION registrator_is_not_reader_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(
        SELECT * FROM reader AS r
        WHERE r.id_device = NEW.id_device
    ) THEN
        RAISE EXCEPTION 'This device is already reader';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
    Check that when adding card to a zone, that it already has UID filled in.

    This is kinda annoying but for me the simples option to implement this
    as the whitelist cannot be created until we have the UID, thus any 
    managements system will have to wait until the card is
    registered before it assigns it to zones.

    TODO; THIS CAN BE HANDLED BY POSTGRES using retry logic or by queue table and pg_cron
*/
CREATE OR REPLACE FUNCTION card_has_uid_for_zone_check()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM card
		WHERE id_card = NEW.id_card
		AND uid IS NOT NULL
		AND uid <> ''
    ) THEN
        RAISE EXCEPTION 'Card has to have UID before it is added to a zone';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
