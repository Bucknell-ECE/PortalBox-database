-- Add a field to store [hashed] user pins. We default to NULL indicating no pin
-- has been set.

ALTER TABLE users ADD COLUMN pin VARCHAR(255) NULL DEFAULT NULL;

INSERT INTO schema_versioning(version, comment) VALUES ("2.10.0", "Migration Complete");
