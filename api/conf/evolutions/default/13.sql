# Update user model with non-required locations

# --- !Ups
ALTER TABLE segments ADD COLUMN hidden BOOLEAN NOT NULL DEFAULT FALSE;
