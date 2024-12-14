-- Add a field to equipment types to track whether proxy cards are allowed

ALTER TABLE equipment_types ADD COLUMN allow_proxy BOOLEAN NOT NULL DEFAULT false;

INSERT INTO schema_versioning(version, comment) VALUES ("2.8.0", "Migration Complete");
