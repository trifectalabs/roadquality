# Segments changes

# --- !Ups

ALTER TABLE segments ADD rating double precision;

# --- !Downs

ALTER TABLE segments DROP COLUMN rating;
