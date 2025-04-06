
--------------------------------- Checks ---------------------------------------

/*
    Only cards with UID can be added to zone 
*/
CREATE OR REPLACE TRIGGER card_has_uid_for_zone_trigger
BEFORE INSERT ON card_zone
FOR EACH ROW EXECUTE FUNCTION card_has_uid_for_zone_check();


/*
    Device cannot be assigned to both types
*/
CREATE OR REPLACE TRIGGER reader_is_not_registrator_check_trigger
BEFORE INSERT ON reader
FOR EACH ROW EXECUTE FUNCTION reader_is_not_registrator_check();


/*
    Device cannot be assigned to both types
*/
CREATE OR REPLACE TRIGGER registrator_is_not_reader_check_trigger
BEFORE INSERT ON registrator
FOR EACH ROW EXECUTE FUNCTION registrator_is_not_reader_check();


---------------------------------- API triggers --------------------------------

/*
    Create triggers for each operation on card_identifier table
*/
CREATE OR REPLACE TRIGGER card_identifier_operation_update_trigger
AFTER UPDATE ON card_identifier
FOR EACH ROW
EXECUTE FUNCTION card_identifier_on_update();


/*
    Create triggers for each operation on card_time_rule table
*/
CREATE OR REPLACE TRIGGER card_time_rule_operation_insert_trigger
AFTER INSERT ON card_time_rule
REFERENCING NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_time_rule_on_insert();

CREATE OR REPLACE TRIGGER card_time_rule_operation_update_trigger
AFTER UPDATE ON card_time_rule
REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_time_rule_on_update();

CREATE OR REPLACE TRIGGER card_time_rule_operation_delete_trigger
AFTER DELETE ON card_time_rule
REFERENCING OLD TABLE AS old_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_time_rule_on_delete();


/*
    Create triggers for each operation on card_zone table
*/
CREATE OR REPLACE TRIGGER card_zone_operation_insert_trigger
AFTER INSERT ON card_zone
REFERENCING NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_zone_on_insert();

CREATE OR REPLACE TRIGGER card_zone_operation_update_trigger
AFTER UPDATE ON card_zone
REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_zone_on_update();

CREATE OR REPLACE TRIGGER card_zone_operation_delete_trigger
AFTER DELETE ON card_zone
REFERENCING OLD TABLE AS old_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_zone_on_delete();


/*
    Create triggers for each operation on card table
*/
CREATE OR REPLACE TRIGGER card_operation_insert_trigger
AFTER INSERT ON card
REFERENCING NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_on_insert();

CREATE OR REPLACE TRIGGER card_operation_update_trigger
AFTER UPDATE ON card
REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION card_on_update();


/*
    Create triggers for each operation on config table
*/
CREATE OR REPLACE TRIGGER config_operation_update_trigger
AFTER UPDATE ON config
FOR EACH ROW
EXECUTE FUNCTION config_on_update();


/*
    Create triggers for each operation on device table
*/
CREATE OR REPLACE TRIGGER device_operation_update_trigger
AFTER UPDATE ON device
FOR EACH ROW
EXECUTE FUNCTION device_on_update();


/*
    Create triggers for each operation on pacs_object table
*/
CREATE OR REPLACE TRIGGER pacs_object_operation_update_trigger
AFTER UPDATE ON pacs_object
FOR EACH ROW
EXECUTE FUNCTION pacs_object_on_update();


/*
    Create triggers for each operation on reader table
*/
CREATE OR REPLACE TRIGGER reader_operation_insert_trigger
AFTER INSERT ON reader
FOR EACH ROW
EXECUTE FUNCTION reader_on_insert();

CREATE OR REPLACE TRIGGER reader_operation_update_trigger
AFTER UPDATE ON reader
FOR EACH ROW
EXECUTE FUNCTION reader_on_update();

CREATE OR REPLACE TRIGGER reader_operation_delete_trigger
AFTER DELETE ON reader
FOR EACH ROW
EXECUTE FUNCTION reader_on_delete();


/*
    Create triggers for each operation on reader table
*/
CREATE OR REPLACE TRIGGER registrator_operation_insert_trigger
AFTER INSERT ON registrator
FOR EACH ROW
EXECUTE FUNCTION registrator_on_insert();

CREATE OR REPLACE TRIGGER registrator_operation_update_trigger
AFTER UPDATE ON registrator
FOR EACH ROW
EXECUTE FUNCTION registrator_on_update();

CREATE OR REPLACE TRIGGER registrator_operation_delete_trigger
AFTER DELETE ON registrator
FOR EACH ROW
EXECUTE FUNCTION registrator_on_delete();


/*
    Create triggers for each operation on time_constraint table
*/
CREATE OR REPLACE TRIGGER time_constraint_operation_insert_trigger
AFTER INSERT ON time_constraint
REFERENCING NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION time_constraint_on_insert();

CREATE OR REPLACE TRIGGER time_constraint_operation_update_trigger
AFTER UPDATE ON time_constraint
REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
FOR EACH STATEMENT
EXECUTE FUNCTION time_constraint_on_update();

CREATE OR REPLACE TRIGGER time_constraint_operation_delete_trigger
AFTER DELETE ON time_constraint
REFERENCING OLD TABLE AS old_rows
FOR EACH STATEMENT
EXECUTE FUNCTION time_constraint_on_delete();


/*
    Create triggers for each operation on time_rule table
*/
-- None needed --


/*
    Create triggers for each operation on zone table
*/
CREATE OR REPLACE TRIGGER zone_operation_insert_trigger
AFTER INSERT ON zone
FOR EACH ROW
EXECUTE FUNCTION zone_on_insert();

CREATE OR REPLACE TRIGGER zone_operation_delete_trigger
AFTER DELETE ON zone
FOR EACH ROW
EXECUTE FUNCTION zone_on_delete();


/*
    Create trigger for insert into command
*/
CREATE OR REPLACE TRIGGER command_operation_insert_trigger
BEFORE INSERT ON command
FOR EACH ROW EXECUTE FUNCTION command_on_insert();