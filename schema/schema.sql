-- Clear out the stored prcedures
DROP PROCEDURE IF EXISTS log_access_attempt;
DROP PROCEDURE IF EXISTS log_access_completion;

-- Clear out the tables we will build in reverse order to unwind FKeys
DROP TABLE IF EXISTS schema_versioning;
DROP TABLE IF EXISTS api_keys;
DROP TABLE IF EXISTS charges;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS log;
DROP TABLE IF EXISTS event_types;
DROP TABLE IF EXISTS authorizations;
DROP TABLE IF EXISTS in_use;
DROP TABLE IF EXISTS equipment_type_x_cards;
DROP TABLE IF EXISTS equipment;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS charge_policies;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS users_x_cards;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS management_portal_access_levels;
DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS card_types;


-- List of Card Types... We use four(4): admin, proxy, training, and user
--   Could be an enum but we don't want to worry about enum issues in future
CREATE TABLE card_types (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name VARCHAR(8) NOT NULL,
	PRIMARY KEY (id)
);

INSERT INTO card_types(name) VALUES
	("shutdown"),
	("proxy"),
	("training"),
	("user");


-- List of cards 
CREATE TABLE cards (
	id BIGINT(20) UNSIGNED NOT NULL,
	type_id INT UNSIGNED NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY cards_type_id (type_id) REFERENCES card_types (id)
);


-- List of Management access levels... We use three(3): none, trainer, admin
--   Could be an enum but we don't want to worry about enum issues in future
CREATE TABLE management_portal_access_levels (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name VARCHAR(8) NOT NULL,
	PRIMARY KEY (id)
);

INSERT INTO management_portal_access_levels(name) VALUES
	("none"),
	("trainer"),
	("admin");


-- List of users
CREATE TABLE users (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT NOT NULL,
	email VARCHAR(512) NOT NULL,
	comment TEXT,
	management_portal_access_level_id INT UNSIGNED NOT NULL DEFAULT 1, -- e.g. none
	is_active INT(1) UNSIGNED NOT NULL,
	PRIMARY KEY (id),
	UNIQUE KEY users_email (email),
	FOREIGN KEY users_management_portal_access_level_id (management_portal_access_level_id) REFERENCES management_portal_access_levels (id)
);


-- Associate a user to a card, form the User::cards relationship
CREATE TABLE users_x_cards (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	user_id INT UNSIGNED NOT NULL,
	card_id BIGINT(20) UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY users_x_cards_user_id (user_id) REFERENCES users (id),
	FOREIGN KEY users_x_cards_card_id (card_id) REFERENCES cards (id) ON UPDATE CASCADE
);


-- List of locations where Portal Boxes are deployed
CREATE TABLE locations (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT,
	PRIMARY KEY(id)
);


-- List of Charge Frequencies
CREATE TABLE charge_policies (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT,
	PRIMARY KEY(id)
);

INSERT INTO charge_policies(id, name)
	VALUES (1, 'Manually Adjusted'), (2, 'No Charge'), (3, 'Per Use'), (4, 'Per Minute');


-- List of Equipment Types
CREATE TABLE equipment_types (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT,
	requires_training BOOLEAN NOT NULL DEFAULT true,
	charge_rate DECIMAL(5,2) DEFAULT NULL,
	charge_policy_id INT UNSIGNED DEFAULT 1,
	PRIMARY KEY(id),
	FOREIGN KEY equipment_type_charge_policy_id (charge_policy_id) REFERENCES charge_policies (id)
);

INSERT INTO equipment_types(id, name) VALUES (0, 'Out of Service');


-- List of equipment connected to Portal Boxes
CREATE TABLE equipment (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT,
	type_id INT UNSIGNED NOT NULL,
	mac_address CHAR(12) NOT NULL,
	location_id INT UNSIGNED NOT NULL,
	timeout INT DEFAULT 0 NOT NULL,
	in_service INT(1) UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	UNIQUE mac_address_index (mac_address),
	FOREIGN KEY equipment_locations_id (location_id) REFERENCES locations (id),
	FOREIGN KEY equipment_equipment_types_id (type_id) REFERENCES equipment_types (id)
);


-- List of Training cards...
--   Associate a piece of equipment to a card, forming the
--   Equipment::training_cards relationship
CREATE TABLE equipment_type_x_cards (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	equipment_type_id INT UNSIGNED NOT NULL,
	card_id BIGINT(20) UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY equipment_type_x_cards_equipment_type_id (equipment_type_id) REFERENCES equipment_types (id),
	FOREIGN KEY equipment_type_x_cards_card_id (card_id) REFERENCES cards (id) ON UPDATE CASCADE
);


-- List of equipment that is in use
--   Easy to reset `DELETE FROM in_use;`
CREATE TABLE in_use (
	equipment_id INT UNSIGNED NOT NULL,
	start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY in_use_equipment_id (equipment_id) REFERENCES equipment (id)
);


-- List of Authorizations forms the User::authorizations
CREATE TABLE authorizations (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	user_id INT UNSIGNED NOT NULL,
	equipment_type_id INT UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY authorizations_equipment_type_id (equipment_type_id) REFERENCES equipment_types (id),
	FOREIGN KEY authorizations_user_id (user_id) REFERENCES users (id)
);


-- List of Types of things we can log... We use three(3): Unsuccessful
--   Authentication, Successful Authentication, and Deauthenticate.
--   Could be an enum but we don't want to worry about enum issues in future
CREATE TABLE event_types (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name VARCHAR(32) NOT NULL,
	PRIMARY KEY(id)
);

INSERT INTO event_types(name) VALUES
	("Unsuccessful Authentication"),
	("Successful Authentication"),
	("Deauthentication"),
	("Startup Complete"),
	("Planned Shutdown");


-- List of events aka the access log
CREATE TABLE log (
	id BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
	event_type_id INT UNSIGNED NOT NULL,
	card_id BIGINT(20) UNSIGNED,
	equipment_id INT UNSIGNED NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (id),
	-- no foreign key for card_id because it may be an invalid card (failed auth)
	FOREIGN KEY log_equipment_id (equipment_id) REFERENCES equipment (id)
);


-- List of Payments
CREATE TABLE payments (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	user_id INT UNSIGNED NOT NULL,
	amount DECIMAL(5,2) NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (id),
	FOREIGN KEY payments_user_id (user_id) REFERENCES users (id)
);


-- List of Charges
CREATE TABLE charges (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	user_id INT UNSIGNED NOT NULL,
	equipment_id INT UNSIGNED NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	amount DECIMAL(5,2) NOT NULL,
	charge_policy_id INT UNSIGNED NOT NULL,
	charge_rate DECIMAL(5,2) DEFAULT NULL,
	charged_time INT UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY charges_user_id (user_id) REFERENCES users (id),
	FOREIGN KEY charges_equipment_id (equipment_id) REFERENCES equipment (id),
	FOREIGN KEY charges_charge_policy_id (charge_policy_id) REFERENCES charge_policies (id)
);


-- use a stored procedure to log a user begining a session with equipment
DELIMITER $
CREATE PROCEDURE log_access_attempt(p_success BOOL, p_card_id INT UNSIGNED, p_equipment_id INT UNSIGNED)
	MODIFIES SQL DATA
BEGIN
	IF p_success THEN
		INSERT INTO log(event_type_id, card_id, equipment_id, time) VALUES (2, p_card_id, p_equipment_id, CURRENT_TIMESTAMP);
		INSERT INTO in_use(equipment_id) VALUES (p_equipment_id);
	ELSE
		INSERT INTO log(event_type_id, card_id, equipment_id, time) VALUES (1, p_card_id, p_equipment_id, CURRENT_TIMESTAMP);
	END IF;
END$
DELIMITER ;


-- use a stored procedure to log a user releasing the equipment
DELIMITER $
CREATE PROCEDURE log_access_completion(p_card_id INT UNSIGNED, p_equipment_id INT UNSIGNED)
	MODIFIES SQL DATA
BEGIN
	DECLARE l_charge_policy_id INT UNSIGNED;
	DECLARE l_use_start_timestamp TIMESTAMP;
	DECLARE l_use_duration INT UNSIGNED;

	-- log in case all else fails
	INSERT INTO log(event_type_id, card_id, equipment_id, time)
		VALUES (3, p_card_id, p_equipment_id, CURRENT_TIMESTAMP);

	-- figure out charges if need be
	SET l_charge_policy_id = (SELECT et.charge_policy_id FROM equipment AS e
								INNER JOIN equipment_types AS et ON et.id = e.type_id
								WHERE e.id = p_equipment_id);
	SET l_use_start_timestamp = (SELECT start_time FROM in_use
								WHERE equipment_id = p_equipment_id LIMIT 1);
	SET l_use_duration = TIMESTAMPDIFF(MINUTE, l_use_start_timestamp, NOW());

	CASE l_charge_policy_id
		WHEN 3 THEN -- per use
			INSERT INTO charges(user_id, equipment_id, amount, charge_policy_id, charge_rate, charged_time)
				SELECT uxc.user_id, p_equipment_id, et.charge_rate, l_charge_policy_id, et.charge_rate, l_use_duration
					FROM equipment AS e
					INNER JOIN equipment_types AS et ON et.id = e.type_id
					INNER JOIN users_x_cards AS uxc
					WHERE e.id = p_equipment_id AND uxc.card_id = p_card_id;
		WHEN 4 THEN -- per minute
			INSERT INTO charges(user_id, equipment_id, amount, charge_policy_id, charge_rate, charged_time)
				SELECT uxc.user_id, p_equipment_id, et.charge_rate * l_use_duration, l_charge_policy_id, et.charge_rate, l_use_duration
					FROM equipment AS e
					INNER JOIN equipment_types AS et ON et.id = e.type_id
					INNER JOIN users_x_cards AS uxc
					WHERE e.id = p_equipment_id AND uxc.card_id = p_card_id;
		ELSE BEGIN END;
	END CASE;

	DELETE FROM in_use WHERE equipment_id = p_equipment_id;
END$
DELIMITER ;


-- List of API Keys
CREATE TABLE api_keys (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT NOT NULL,
	token CHAR(32) NOT NULL,
	PRIMARY KEY(id)
);


-- List to track what schema is installed; helpful when doing support
CREATE TABLE schema_versioning (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	version TEXT NOT NULL,
	comment TEXT,
	PRIMARY KEY(id)
);

INSERT INTO schema_versioning(version, comment) VALUES ("2.2.0", "Database created");