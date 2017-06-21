# Update user model to include location

# --- !Ups
ALTER TABLE users ADD COLUMN city text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN province text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN country text NOT NULL DEFAULT '';

# --- !Downs

ALTER TABLE users DROP COLUMN city;
ALTER TABLE users DROP COLUMN province;
ALTER TABLE users DROP COLUMN country;
