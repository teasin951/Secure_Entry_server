DROP TABLE IF EXISTS message_queue CASCADE;

-- TODO create users and make DELETE not possible on card table for other than system_server
-- TODO restrict timerules to max_time_rules
-- TODO prevent deleting zone and config that is attached to a reader
-- TODO prevent deleting card_id and pacs_object when attached to a config
-- TODO make deleting a registrator not take down cards with it
-- TODO views

-- Make changes trigger a notification describing the changes
CREATE OR REPLACE FUNCTION operation_notify()
RETURNS TRIGGER AS $$
BEGIN
	-- If the system is making changes, do not queue those changes
	IF CURRENT_USER IN ('System_server') THEN
		RETURN NEW;
	END IF;

	-- Notify services that there has been a change
	PERFORM pg_notify(
		'database_operation',
		json_build_object(
			'table', TG_TABLE_NAME,
			'operation', TG_OP,
			'changes', json_build_object(
				'old', row_to_json(OLD),
				'new', row_to_json(NEW)
			)
		)::text
	);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Create triggers for each table
CREATE OR REPLACE TRIGGER card_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON card
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER zone_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON zone
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER time_rule_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON time_rule
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER time_constraint_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON time_constraint
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER reader_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON reader
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER config_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON config
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER card_identifier_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON card_identifier
FOR EACH ROW EXECUTE FUNCTION operation_notify();

CREATE OR REPLACE TRIGGER pacs_object_operation_trigger
AFTER INSERT OR UPDATE OR DELETE ON pacs_object
FOR EACH ROW EXECUTE FUNCTION operation_notify();


-- Check that when adding card to a zone, that it already has UID filled in
-- this is kinda annoying but for me the simples option to implement this
-- as the whitelist cannot be created until we have the UID, thus any 
-- managements system will have to wait until the card is
-- registered before it assigns it to zones.
-- THIS CAN BE HANDLED BY POSTGRES, by retry logic or by queue table and pg_cron
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

CREATE OR REPLACE TRIGGER card_has_uid_for_zone_trigger
BEFORE INSERT ON card_zone
FOR EACH ROW EXECUTE FUNCTION card_has_uid_for_zone_check();
