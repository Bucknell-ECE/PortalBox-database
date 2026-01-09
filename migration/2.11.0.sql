-- Add table to store badges
-- Add table to link badges to equipment_types

CREATE TABLE badges (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE badges_x_equipment_types (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	badge_id INT UNSIGNED NOT NULL,
	equipment_type_id INT UNSIGNED NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY badges_x_equipment_types_equipment_type_id (equipment_type_id) REFERENCES equipment_types (id),
	FOREIGN KEY badges_x_equipment_types_badge_id (badge_id) REFERENCES badges (id) ON DELETE CASCADE
);

INSERT INTO schema_versioning(version, comment) VALUES ("2.11.0", "Migration Complete");