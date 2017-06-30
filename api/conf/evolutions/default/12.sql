# Update user model with non-required locations

# --- !Ups
ALTER TABLE users ALTER COLUMN city DROP NOT NULL;
ALTER TABLE users ALTER COLUMN province DROP NOT NULL;
ALTER TABLE users ALTER COLUMN country DROP NOT NULL;
