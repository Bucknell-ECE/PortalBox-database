-- Add table to store badge rules
-- Add table to link badge rules to equipment_types
-- Add permissions for managing badge rules and grant them to admins

-- Uncomment the below if you need to reset this migration. NOTE data may be lost
-- DELETE FROM roles_x_permissions WHERE permission_id IN (51, 52, 53, 54, 55);
-- DELETE FROM permissions WHERE id IN (51, 52, 53, 54, 55);
-- DROP TABLE IF EXISTS badge_rules_x_equipment_types;
-- DROP TABLE IF EXISTS badge_rule_levels;
-- DROP TABLE IF EXISTS badge_rules;

CREATE TABLE badge_rules (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE badge_rule_levels (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	badge_rule_id INT UNSIGNED NOT NULL,
	uses INT UNSIGNED NOT NULL,
	name TEXT NOT NULL,
	image TEXT NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY badge_rule_levels_x_badge_rules_id (badge_rule_id) REFERENCES badge_rules (id) ON DELETE CASCADE
);

CREATE TABLE badge_rules_x_equipment_types (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	badge_rule_id INT UNSIGNED NOT NULL,
	equipment_type_id INT UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY badge_rules_x_equipment_types_equipment_type_id (equipment_type_id) REFERENCES equipment_types (id),
	FOREIGN KEY badge_rules_x_equipment_types_badge_rule_id (badge_rule_id) REFERENCES badge_rules (id) ON DELETE CASCADE
);

INSERT INTO permissions(id, name) VALUES
	(51, 'CREATE_BADGE'),
	(52, 'READ_BADGE'),
	(53, 'MODIFY_BADGE'),
	(54, 'DELETE_BADGE'),
	(55, 'LIST_BADGES'),
	(57, 'REPORT_BADGES');

SET @admin_role_id = (SELECT id FROM roles WHERE name = 'admin');
INSERT INTO roles_x_permissions(role_id, permission_id) VALUES
	(@admin_role_id, 51),
	(@admin_role_id, 52),
	(@admin_role_id, 53),
	(@admin_role_id, 54),
	(@admin_role_id, 55),
	(@admin_role_id, 57);

INSERT INTO schema_versioning(version, comment) VALUES ("2.11.0", "Migration Complete");
