-- Remove conflicting tables
DROP TABLE IF EXISTS card CASCADE;
DROP TABLE IF EXISTS card_identifier CASCADE;
DROP TABLE IF EXISTS config CASCADE;
DROP TABLE IF EXISTS pacs_object CASCADE;
DROP TABLE IF EXISTS reader CASCADE;
DROP TABLE IF EXISTS time_constraint CASCADE;
DROP TABLE IF EXISTS time_rule CASCADE;
DROP TABLE IF EXISTS zone CASCADE;
DROP TABLE IF EXISTS card_zone CASCADE;
DROP TABLE IF EXISTS card_time_rule CASCADE;
DROP TYPE IF EXISTS card_removal CASCADE;
-- End of removing


-- active        - default, not to be removed
-- depersonalize - send depersonalize command first, when successful, DELETE
-- delete_app    - send delete last app command first, when successful, DELETE
-- clear         - just remove the card from the system
CREATE TYPE card_removal AS ENUM ('active', 'depersonalize', 'delete_app', 'clear');

CREATE TABLE card (
    id_card SERIAL NOT NULL,
    id_reader INTEGER NOT NULL,
    name VARCHAR(256) NOT NULL,
    uid BYTEA CHECK (octet_length(uid) = 4 OR octet_length(uid) = 7),
	erase card_removal DEFAULT 'active',
    external_user_id INTEGER,
    pin_code BYTEA CHECK (octet_length(pin_code) = 4),
    notes TEXT,
    create_time TIMESTAMP NOT NULL DEFAULT NOW()
);
ALTER TABLE card ADD CONSTRAINT pk_card PRIMARY KEY (id_card);
ALTER TABLE card ADD CONSTRAINT u_fk_card_reader UNIQUE (id_reader);

CREATE TABLE card_identifier (
    id_card_identifier SERIAL NOT NULL,
    manufacturer TEXT NOT NULL CHECK (
		octet_length(manufacturer) < 17
	),
    mutual_auth BYTEA NOT NULL CHECK (octet_length(mutual_auth) = 2),
    comm_enc BYTEA NOT NULL CHECK (octet_length(comm_enc) = 1),
    key_version SMALLINT NOT NULL CHECK (key_version < 256)
);
ALTER TABLE card_identifier ADD CONSTRAINT pk_card_identifier PRIMARY KEY (id_card_identifier);

CREATE TABLE config (
    id_config SERIAL NOT NULL,
    id_card_identifier INTEGER NOT NULL,
    id_pacs INTEGER NOT NULL,
    appmok BYTEA NOT NULL CHECK (octet_length(appmok) = 16),
    appvok BYTEA NOT NULL CHECK (octet_length(appvok) = 16),
    ocpsk BYTEA NOT NULL CHECK (octet_length(ocpsk) = 16),
    name VARCHAR(256) NOT NULL,
    notes TEXT
);
ALTER TABLE config ADD CONSTRAINT pk_config PRIMARY KEY (id_config);

CREATE TABLE pacs_object (
    id_pacs SERIAL NOT NULL,
    version_major SMALLINT NOT NULL CHECK (version_major < 256),
    version_minor SMALLINT NOT NULL CHECK (version_minor < 256),
    site_code BYTEA NOT NULL CHECK (octet_length(site_code) < 6),
    reissue_code SMALLINT NOT NULL CHECK (reissue_code < 256),
    customer_specific BYTEA NOT NULL CHECK (octet_length(customer_specific) < 21)
);
ALTER TABLE pacs_object ADD CONSTRAINT pk_pacs_object PRIMARY KEY (id_pacs);

CREATE TABLE reader (
    id_reader SERIAL NOT NULL,
    id_config INTEGER NOT NULL,
    id_zone INTEGER NOT NULL,
    name VARCHAR(256) NOT NULL,
    mqtt_username VARCHAR(20) NOT NULL,
    mqtt_password VARCHAR(256) NOT NULL,
    mqtt_client_id VARCHAR(256),
    registrator BOOLEAN NOT NULL,
    location VARCHAR(256),
    notes TEXT,
    max_time_rules SMALLINT NOT NULL
);
ALTER TABLE reader ADD CONSTRAINT pk_reader PRIMARY KEY (id_reader);
ALTER TABLE reader ADD CONSTRAINT uc_reader_mqtt_username UNIQUE (mqtt_username);
ALTER TABLE reader ADD CONSTRAINT uc_reader_mqtt_client_id UNIQUE (mqtt_client_id);

CREATE TABLE time_constraint (
    id_time_constraint SERIAL NOT NULL,
    id_time_rule INTEGER NOT NULL,
    id_zone INTEGER NOT NULL,
    allow_from TIME NOT NULL,
    allow_to TIME NOT NULL,
    week_days BYTEA NOT NULL CHECK (octet_length(week_days) = 1)
);
ALTER TABLE time_constraint ADD CONSTRAINT pk_time_constraint PRIMARY KEY (id_time_constraint);

CREATE TABLE time_rule (
    id_time_rule SERIAL NOT NULL,
    id_zone INTEGER NOT NULL,
    name VARCHAR(256) NOT NULL,
    note TEXT
);
ALTER TABLE time_rule ADD CONSTRAINT pk_time_rule PRIMARY KEY (id_time_rule, id_zone);

CREATE TABLE zone (
    id_zone SERIAL NOT NULL,
    name VARCHAR(256) NOT NULL,
    notes TEXT
);
ALTER TABLE zone ADD CONSTRAINT pk_zone PRIMARY KEY (id_zone);

CREATE TABLE card_zone (
    id_card INTEGER NOT NULL,
    id_zone INTEGER NOT NULL
);
ALTER TABLE card_zone ADD CONSTRAINT pk_card_zone PRIMARY KEY (id_card, id_zone);

CREATE TABLE card_time_rule (
    id_card INTEGER NOT NULL,
    id_time_rule INTEGER NOT NULL,
    id_zone INTEGER NOT NULL
);
ALTER TABLE card_time_rule ADD CONSTRAINT pk_card_time_rule PRIMARY KEY (id_card, id_time_rule, id_zone);

ALTER TABLE card ADD CONSTRAINT fk_card_reader FOREIGN KEY (id_reader) REFERENCES reader (id_reader) ON DELETE CASCADE;

ALTER TABLE config ADD CONSTRAINT fk_config_card_identifier FOREIGN KEY (id_card_identifier) REFERENCES card_identifier (id_card_identifier) ON DELETE CASCADE;
ALTER TABLE config ADD CONSTRAINT fk_config_pacs_object FOREIGN KEY (id_pacs) REFERENCES pacs_object (id_pacs) ON DELETE CASCADE;

ALTER TABLE reader ADD CONSTRAINT fk_reader_config FOREIGN KEY (id_config) REFERENCES config (id_config) ON DELETE CASCADE;
ALTER TABLE reader ADD CONSTRAINT fk_reader_zone FOREIGN KEY (id_zone) REFERENCES zone (id_zone) ON DELETE CASCADE;

ALTER TABLE time_constraint ADD CONSTRAINT fk_time_constraint_time_rule FOREIGN KEY (id_time_rule, id_zone) REFERENCES time_rule (id_time_rule, id_zone) ON DELETE CASCADE;

ALTER TABLE time_rule ADD CONSTRAINT fk_time_rule_zone FOREIGN KEY (id_zone) REFERENCES zone (id_zone) ON DELETE CASCADE;

ALTER TABLE card_zone ADD CONSTRAINT fk_card_zone_card FOREIGN KEY (id_card) REFERENCES card (id_card) ON DELETE CASCADE;
ALTER TABLE card_zone ADD CONSTRAINT fk_card_zone_zone FOREIGN KEY (id_zone) REFERENCES zone (id_zone) ON DELETE CASCADE;

ALTER TABLE card_time_rule ADD CONSTRAINT fk_card_time_rule_card FOREIGN KEY (id_card) REFERENCES card (id_card) ON DELETE CASCADE;
ALTER TABLE card_time_rule ADD CONSTRAINT fk_card_time_rule_time_rule FOREIGN KEY (id_time_rule, id_zone) REFERENCES time_rule (id_time_rule, id_zone) ON DELETE CASCADE;


---- TRIGGERS ----
-- Check that a registrator is assigned to register this card
CREATE OR REPLACE FUNCTION card_registrated_by_registrator_check()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM reader 
        WHERE id_reader = NEW.id_reader AND registrator = TRUE
    ) THEN
        RAISE EXCEPTION 'Card has to be registered by a registrator';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER card_registrated_by_registrator_trigger
BEFORE INSERT ON card
FOR EACH ROW EXECUTE FUNCTION card_registrated_by_registrator_check();


