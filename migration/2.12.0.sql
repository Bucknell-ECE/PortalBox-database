-- Add support for logging training

INSERT INTO event_types(id, name) VALUES (6, "Training");

ALTER TABLE log ADD COLUMN trainee_card_id BIGINT(20) UNSIGNED DEFAULT NULL;
ALTER TABLE log ADD FOREIGN KEY log_trainee_card_id (trainee_card_id) REFERENCES cards (id);

INSERT INTO schema_versioning(version, comment) VALUES ("2.12.0", "Migration Complete");
