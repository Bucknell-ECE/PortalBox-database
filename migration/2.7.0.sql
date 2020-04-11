-- Update the Database schema from 2.6.0 to 2.7.0
-- New flexible role based access system for website

-- List of roles
CREATE TABLE roles (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	name TEXT NOT NULL,
	is_system_role INT(1) UNSIGNED NOT NULL DEFAULT 0,
	description TEXT,
	PRIMARY KEY (id)
);

-- Create the default roles
INSERT INTO roles(name, is_system_role, description) VALUES
	('unauthenticated', 1, 'Role of users who have not authenticated'),
	('user', 1, 'Role of authenticated users who have not be granted additional permissions. This role is the default for users created in the web interface.'),
	('admin', 1, 'Role for users who administer the system.'),
	('trainer', 0, 'Role for trainers created for backward compatibility with student designed system');


-- List of Permissions assigned to a role.
-- Permissions play a special role in the code and are therefore constants in
-- in code. See Entity/Permissions.php As such they do not have a backing table
CREATE TABLE roles_x_permissions (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	role_id INT UNSIGNED NOT NULL,
	permission INT NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY roles_x_permissions_role_id (role_id) REFERENCES roles (id)
);

-- Assign default permissions to roles
-- Assign permissions for an unauthenticated user
SET @unauthenticated_role_id = (SELECT id FROM roles WHERE name = 'unauthenticated');
INSERT INTO roles_x_permissions(role_id, permission) VALUES
	(@unauthenticated_role_id, 704);	-- list equipment

-- Assign permissions for a default authenticated user
SET @user_role_id = (SELECT id FROM roles WHERE name = 'user');
INSERT INTO roles_x_permissions(role_id, permission) VALUES
	(@user_role_id, 105),	-- list own authorizations
	(@user_role_id, 305),	-- list own cards
	(@user_role_id, 505),	-- read own charges
	(@user_role_id, 604),	-- list equipment types
	(@user_role_id, 704),	-- list equipment
	(@user_role_id, 1005),	-- read own payments
	(@user_role_id, 1205);	-- read own user record

-- Assign permissions for administrators ie. all permissions
SET @admin_role_id = (SELECT id FROM roles WHERE name = 'admin');
INSERT INTO roles_x_permissions(role_id, permission) VALUES
	(@admin_role_id, 0),
	(@admin_role_id, 1),
	(@admin_role_id, 2),
	(@admin_role_id, 3),
	(@admin_role_id, 4),
	(@admin_role_id, 100),
	(@admin_role_id, 101),
	(@admin_role_id, 102),
	(@admin_role_id, 103),
	(@admin_role_id, 104),
	(@admin_role_id, 105),
	(@admin_role_id, 200),
	(@admin_role_id, 201),
	(@admin_role_id, 202),
	(@admin_role_id, 203),
	(@admin_role_id, 204),
	(@admin_role_id, 300),
	(@admin_role_id, 301),
	(@admin_role_id, 302),
	(@admin_role_id, 303),
	(@admin_role_id, 304),
	(@admin_role_id, 305),
	(@admin_role_id, 400),
	(@admin_role_id, 401),
	(@admin_role_id, 402),
	(@admin_role_id, 403),
	(@admin_role_id, 404),
	(@admin_role_id, 500),
	(@admin_role_id, 501),
	(@admin_role_id, 502),
	(@admin_role_id, 503),
	(@admin_role_id, 504),
	(@admin_role_id, 505),
	(@admin_role_id, 600),
	(@admin_role_id, 601),
	(@admin_role_id, 602),
	(@admin_role_id, 603),
	(@admin_role_id, 604),
	(@admin_role_id, 700),
	(@admin_role_id, 701),
	(@admin_role_id, 702),
	(@admin_role_id, 703),
	(@admin_role_id, 704),
	(@admin_role_id, 800),
	(@admin_role_id, 801),
	(@admin_role_id, 802),
	(@admin_role_id, 803),
	(@admin_role_id, 804),
	(@admin_role_id, 900),
	(@admin_role_id, 901),
	(@admin_role_id, 902),
	(@admin_role_id, 903),
	(@admin_role_id, 904),
	(@admin_role_id, 1000),
	(@admin_role_id, 1001),
	(@admin_role_id, 1002),
	(@admin_role_id, 1003),
	(@admin_role_id, 1004),
	(@admin_role_id, 1005),
	(@admin_role_id, 1100),
	(@admin_role_id, 1101),
	(@admin_role_id, 1102),
	(@admin_role_id, 1103),
	(@admin_role_id, 1104),
	(@admin_role_id, 1200),
	(@admin_role_id, 1201),
	(@admin_role_id, 1202),
	(@admin_role_id, 1203),
	(@admin_role_id, 1204),
	(@admin_role_id, 1205);

-- Trainer was part of the 1.x design but a full fledged RBA means ends users
-- can design their own roles. Future revisions will not reference this role.
SET @trainer_role_id = (SELECT id FROM roles WHERE name = 'trainer');
INSERT INTO roles_x_permissions(role_id, permission) VALUES
	(@trainer_role_id, 100),	-- create authorizations
	(@trainer_role_id, 103),	-- delete authorizations
	(@trainer_role_id, 104),	-- list authorizations
	(@trainer_role_id, 105),	-- list own authorizations
	(@trainer_role_id, 305),	-- list own cards
	(@trainer_role_id, 505),	-- read own charges
	(@trainer_role_id, 601),	-- read eqipment type
	(@trainer_role_id, 604),	-- list equipment types
	(@trainer_role_id, 701),	-- read equipment
	(@trainer_role_id, 704),	-- list equipment
	(@trainer_role_id, 1201),	-- read user
	(@trainer_role_id, 1204),	-- list users
	(@trainer_role_id, 1205);	-- read own user record


-- ALTER USER add role_id, foreign key to roles
ALTER TABLE users ADD role_id INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE users ADD CONSTRAINT users_role_id FOREIGN KEY (role_id) REFERENCES roles(id);

-- Update users setting role_id appropriate to management portal access level
UPDATE users SET role_id = @user_role_id WHERE management_portal_access_level_id = 1;
UPDATE users SET role_id = @trainer_role_id WHERE management_portal_access_level_id = 2;
UPDATE users SET role_id = @admin_role_id WHERE management_portal_access_level_id = 3;

-- DROP the management_portal Access Foreign Key
ALTER TABLE users DROP FOREIGN KEY users_management_portal_access_level_id;
ALTER TABLE users DROP COLUMN management_portal_access_level_id;

-- we no longer use the management portal access level design
-- therefore we don't require the backing table
DROP TABLE management_portal_access_levels;