# Users schema
# Segments schema

# --- !Ups

CREATE TABLE IF NOT EXISTS users (
	id uuid NOT NULL PRIMARY KEY,
	first_name text NOT NULL,
	last_name text NOT NULL,
	email text NOT NULL UNIQUE,
	birthdate timestamp with time zone,
	sex varchar(1),
	role text NOT NULL,
	strava_token text NOT NULL,
	created_at timestamp with time zone NOT NULL,
	updated_at timestamp with time zone NOT NULL,
	deleted_at timestamp with time zone
);

CREATE INDEX ON users (id);
CREATE INDEX ON users (email);

CREATE TABLE IF NOT EXISTS segments (
  id uuid NOT NULL PRIMARY KEY,
  name varchar(255),
  description text,
  polyline text,
  created_by uuid NOT NULL REFERENCES users (id)
);

CREATE INDEX ON segments (id);

CREATE TABLE IF NOT EXISTS segment_ratings (
	id uuid NOT NULL PRIMARY KEY,
  segment_id uuid NOT NULL REFERENCES segments (id),
  user_id uuid REFERENCES users (id),
  traffic_rating integer NOT NULL,
  surface_rating integer NOT NULL,
  surface text NOT NULL,
  path_type text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  deleted_at timestamp with time zone
);

CREATE INDEX ON segment_ratings (segment_id);
CREATE INDEX ON segment_ratings (user_id);
CREATE INDEX ON segment_ratings (surface);
CREATE INDEX ON segment_ratings (path_type);

CREATE TABLE IF NOT EXISTS mini_segments_to_segments (
	mini_segment_id uuid NOT NULL,
  mini_segment_polyline geometry(LineString,4326) NOT NULL,
  segment_id uuid NOT NULL REFERENCES segments (id)
);

CREATE INDEX ON mini_segments_to_segments (mini_segment_id);
CREATE INDEX ON mini_segments_to_segments USING GIST (mini_segment_polyline);
CREATE INDEX ON mini_segments_to_segments (segment_id);

CREATE VIEW mini_segments AS
	SELECT
    mini_segment_id AS id,
    avg(traffic_rating) AS traffic_rating,
    avg(surface_rating) AS surface_rating,
    (SELECT surface FROM segment_ratings GROUP BY 1 ORDER BY count(*) DESC LIMIT 1) AS surface,
    (SELECT path_type FROM segment_ratings GROUP BY 1 ORDER BY count(*) DESC LIMIT 1) AS path_type,
    msts.mini_segment_polyline AS polyline,
    count(msts.mini_segment_id) AS weight
	FROM mini_segments_to_segments msts
  INNER JOIN segment_ratings sr ON sr.segment_id = msts.segment_id
  GROUP BY msts.mini_segment_id, msts.mini_segment_polyline;

# --- !Downs

DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS segments;
DROP TABLE IF EXISTS segment_ratings;
DROP TABLE IF EXISTS mini_segments_to_segments;
DROP VIEW IF  EXISTS mini_segments;
