# Segment ratings changes
# Adds surface and traffic ratings

# --- !Ups

ALTER TABLE segments ADD surface_rating double precision;
ALTER TABLE segments ADD traffic_rating double precision;
ALTER TABLE segments RENAME rating TO overall_rating;

UPDATE segments SET surface_rating = 3.0;
UPDATE segments SET traffic_rating = 3.0;

ALTER TABLE segments ALTER COLUMN surface_rating SET NOT NULL;
ALTER TABLE segments ALTER COLUMN traffic_rating SET NOT NULL;

# --- !Downs

ALTER TABLE segments DROP COLUMN surface_rating double precision;
ALTER TABLE segments DROP COLUMN traffic_rating double precision;
ALTER TABLE segments RENAME overall_rating TO rating;
