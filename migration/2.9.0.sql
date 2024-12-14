-- Add a field to equipment ip address (IPv4 as ###.###.###.###)

ALTER TABLE equipment ADD COLUMN ip_address VARCHAR(15) NULL DEFAULT NULL;

INSERT INTO schema_versioning(version, comment) VALUES ("2.9.0", "Migration Complete");
