# New segment ratings
# Removes ratings from segments
# Creates new ratings relation

# --- !Ups

ALTER TABLE segments DROP COLUMN surface_rating;
ALTER TABLE segments DROP COLUMN traffic_rating;
ALTER TABLE segments DROP COLUMN overall_rating;
ALTER TABLE segments DROP COLUMN surface;
ALTER TABLE segments DROP COLUMN path_type;
ALTER TABLE segments DROP COLUMN start_point;
ALTER TABLE segments DROP COLUMN end_point;

CREATE TABLE IF NOT EXISTS ratings (
  segment_id uuid NOT NULL,
  way_id bigint NOT NULL,
  user_id uuid REFERENCES users (id),
  traffic_rating double precision NOT NULL,
  surface_rating double precision NOT NULL,
  surface text NOT NULL,
  path_type text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  deleted_at timestamp with time zone
  );

CREATE VIEW ratings_summary AS
  SELECT way_id,
  avg(traffic_rating) as traffic_rating,
  avg(surface_rating) as surface_rating,
  COALESCE (
    (SELECT surface FROM ratings GROUP BY 1 ORDER BY count(*) DESC LIMIT 1),
    (SELECT pol.surface FROM planet_osm_line pol WHERE osm_id = ratings.way_id GROUP BY 1 ORDER BY count(*) DESC LIMIT 1)
  ) surface_type,
  ( SELECT path_type FROM ratings GROUP BY 1 ORDER BY count(*) DESC LIMIT 1 ) path_type,
  COALESCE(
    (SELECT pol.name FROM planet_osm_line pol WHERE osm_id = ratings.way_id GROUP BY 1 ORDER BY count(*) DESC LIMIT 1),
    'Unknown'
  ) as street_name,
  count(way_id) as weight
  FROM ratings LEFT JOIN planet_osm_line pol on pol.osm_id = ratings.way_id
  GROUP BY way_id;

# --- !Downs

DROP TABLE ratings;
DROP VIEW ratings_summary;
