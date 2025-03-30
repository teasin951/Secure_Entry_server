-- Remove conflicting tables
DROP TABLE IF EXISTS card CASCADE;
DROP TABLE IF EXISTS card_identifier CASCADE;
DROP TABLE IF EXISTS config CASCADE;
DROP TABLE IF EXISTS pacs_object CASCADE;
DROP TABLE IF EXISTS device CASCADE;
DROP TABLE IF EXISTS registrator CASCADE;
DROP TABLE IF EXISTS reader CASCADE;
DROP TABLE IF EXISTS time_constraint CASCADE;
DROP TABLE IF EXISTS time_rule CASCADE;
DROP TABLE IF EXISTS zone CASCADE;
DROP TABLE IF EXISTS card_zone CASCADE;
DROP TABLE IF EXISTS card_time_rule CASCADE;
-- End of removing


-- no            - default, not to be removed
-- depersonalize - send depersonalize command first, when successful, DELETE
-- delete_app    - send delete last app command first, when successful, DELETE
-- clear         - just remove the card from the system
DROP TYPE IF EXISTS card_removal CASCADE;
CREATE TYPE card_removal AS ENUM ('no', 'depersonalize', 'delete_app', 'clear');


CREATE TABLE card_identifier (
    id_card_identifier SERIAL PRIMARY KEY,
    manufacturer TEXT NOT NULL CHECK (
		octet_length(manufacturer) < 17
	),
    mutual_auth BYTEA NOT NULL CHECK (octet_length(mutual_auth) = 2),
    comm_enc BYTEA NOT NULL CHECK (octet_length(comm_enc) = 1),
    key_version SMALLINT NOT NULL CHECK (key_version < 256)
);


CREATE TABLE pacs_object (
    id_pacs_object SERIAL PRIMARY KEY,
    version_major SMALLINT NOT NULL CHECK (version_major < 256),
    version_minor SMALLINT NOT NULL CHECK (version_minor < 256),
    site_code BYTEA NOT NULL CHECK (octet_length(site_code) < 6),
    reissue_code SMALLINT NOT NULL CHECK (reissue_code < 256),
    customer_specific BYTEA NOT NULL CHECK (octet_length(customer_specific) < 21)
);


CREATE TABLE config (
    id_config SERIAL PRIMARY KEY,
    
    -- RESTRICT deletion to prevent accedentaly deleting keys from config table with CardID or PACSO
    id_card_identifier INTEGER NOT NULL REFERENCES card_identifier(id_card_identifier)
        ON DELETE RESTRICT,
    id_pacs_object INTEGER NOT NULL REFERENCES pacs_object(id_pacs_object)
        ON DELETE RESTRICT,

    appmok BYTEA NOT NULL CHECK (octet_length(appmok) = 16),
    appvok BYTEA NOT NULL CHECK (octet_length(appvok) = 16),
    ocpsk BYTEA NOT NULL CHECK (octet_length(ocpsk) = 16),
    name VARCHAR(256) NOT NULL,
    notes TEXT
);


CREATE TABLE zone (
    id_zone SERIAL PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    notes TEXT
);


CREATE TABLE device (
    id_device SERIAL PRIMARY KEY,
    id_config INTEGER NOT NULL REFERENCES config(id_config)
        ON DELETE RESTRICT,                                   -- RESTRICT as devices shouldn't go with config 

    name VARCHAR(256) NOT NULL,
    mqtt_username VARCHAR(20) NOT NULL UNIQUE,
    mqtt_password VARCHAR(256) NOT NULL,
    mqtt_client_id VARCHAR(256) UNIQUE,
    location VARCHAR(256),
    notes TEXT
);


CREATE TABLE reader (
    id_device INTEGER PRIMARY KEY REFERENCES device(id_device)
        ON DELETE CASCADE,
    id_zone INTEGER NOT NULL REFERENCES zone(id_zone)
        ON DELETE RESTRICT,                                  -- RESTRICT as readers must have a zone

    max_time_rules SMALLINT NOT NULL     -- TODO currently not checked, just here as an indicator
);


CREATE TABLE registrator (
    id_device INTEGER NOT NULL UNIQUE REFERENCES device(id_device)
        ON DELETE CASCADE
);


CREATE TABLE card (
    id_card SERIAL PRIMARY KEY,
    id_device INTEGER REFERENCES registrator(id_device)
        ON DELETE SET NULL,                               -- SET NULL to keep the card in the system

    name VARCHAR(256) NOT NULL,
    uid BYTEA CHECK (octet_length(uid) = 4 OR octet_length(uid) = 7),
	erase card_removal NOT NULL DEFAULT 'no',
    external_user_id INTEGER,
    pin_code BYTEA CHECK (octet_length(pin_code) = 4),
    notes TEXT
);


CREATE TABLE time_rule (
    id_time_rule SERIAL NOT NULL,
    id_zone INTEGER NOT NULL REFERENCES zone(id_zone)
        ON DELETE CASCADE,

    name VARCHAR(256) NOT NULL,
    note TEXT,

    CONSTRAINT pk_time_rule PRIMARY KEY (id_time_rule, id_zone)
);


CREATE TABLE time_constraint (
    id_time_constraint SERIAL PRIMARY KEY,
    id_time_rule INTEGER NOT NULL,
    id_zone INTEGER NOT NULL,
    FOREIGN KEY(id_time_rule, id_zone) REFERENCES time_rule(id_time_rule, id_zone),

    allow_from TIME NOT NULL,
    allow_to TIME NOT NULL,
    week_days BYTEA NOT NULL CHECK (octet_length(week_days) = 1)
);


CREATE TABLE card_zone (
    id_card INTEGER NOT NULL REFERENCES card(id_card)
        ON DELETE CASCADE,
    id_zone INTEGER NOT NULL REFERENCES zone(id_zone)
        ON DELETE CASCADE,
    
    CONSTRAINT pk_card_zone PRIMARY KEY (id_card, id_zone)
);


CREATE TABLE card_time_rule (
    id_card INTEGER NOT NULL REFERENCES card(id_card)
        ON DELETE CASCADE,
    id_time_rule INTEGER NOT NULL,
    id_zone INTEGER NOT NULL,

    FOREIGN KEY(id_time_rule, id_zone) REFERENCES time_rule(id_time_rule, id_zone),
    CONSTRAINT pk_card_time_rule PRIMARY KEY (id_card, id_time_rule, id_zone)
);


