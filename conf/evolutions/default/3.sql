# Segments changes
# Adds surfaces and path types

# --- !Ups

ALTER TABLE segments ADD surface text;
ALTER TABLE segments ADD path_type text;

UPDATE segments SET surface = 'asphalt';
UPDATE segments SET path_type = 'shared';

ALTER TABLE segments ALTER COLUMN surface SET NOT NULL;
ALTER TABLE segments ALTER COLUMN path_type SET NOT NULL;

# --- !Downs
