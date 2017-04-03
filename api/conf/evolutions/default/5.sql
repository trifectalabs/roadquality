# Users changes
# Adds users table

# --- !Ups

CREATE TABLE IF NOT EXISTS users (
	id uuid NOT NULL,
	first_name text NOT NULL,
	last_name text NOT NULL,
	email text NOT NULL,
	birthdate timestamp with time zone,
	sex varchar(1),
	role text,
	strava_token text NOT NULL,
	created_at timestamp with time zone NOT NULL,
	updated_at timestamp with time zone NOT NULL,
	deleted_at timestamp with time zone,
	PRIMARY KEY (id)
	);

	# --- !Downs

DROP TABLE users;
