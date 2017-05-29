# Postgis/Pgrouting functions

# --- !Ups

CREATE OR REPLACE FUNCTION closest_point_on_road(lon double precision, lat double precision)
RETURNS TABLE (x double precision, y double precision) AS $$
BEGIN
  RETURN QUERY
  SELECT ST_X(p) as x, ST_Y(p) as y
  FROM ST_ClosestPoint(
    (SELECT road from closest_road_to_point(lon, lat)),
    (SELECT ST_GeometryFromText('POINT('||lon||' '||lat||')',4326))
  ) AS p
  LIMIT 1;;
END;;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION closest_road_to_point(lon double precision, lat double precision)
RETURNS TABLE (id bigint, road geometry) AS $$
BEGIN
  RETURN QUERY
  SELECT ways.gid, the_geom as road
  FROM ways
  ORDER BY the_geom <-> ST_GeomFromText('POINT('||lon||' '||lat||')',4326) ASC
  LIMIT 1;;
END;;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION shortest_distance_route(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision)
RETURNS TABLE (seq integer, path geometry, distance double precision) AS $$
BEGIN
  RETURN QUERY
  WITH start_road      AS (SELECT * from closest_road_to_point(start_lon, start_lat)),
       end_road        AS (SELECT * from closest_road_to_point(end_lon, end_lat)),
       start_point     AS (SELECT ST_GeometryFromText('POINT('||start_lon||' '||start_lat||')',4326)),
       end_point       AS (SELECT ST_GeometryFromText('POINT('||end_lon||' '||end_lat||')',4326)),
        route           AS (SELECT r.seq, r.cost, ways.the_geom from pgr_trsp('SELECT gid::integer as id, source::int4, target::int4, length_m::float8 as cost FROM ways',
                          (SELECT id from start_road)::integer,
                          (SELECT ST_LineLocatePoint((SELECT road from start_road), (SELECT * FROM start_point))),
                          (SELECT id from end_road)::integer,
                          (SELECT ST_LineLocatePoint((SELECT road from end_road), (SELECT * FROM end_point))),
                          false, false) AS r INNER JOIN ways on ways.gid = r.id2)
  SELECT
    route.seq as seq,
    the_geom as path,
    cost as distance
  FROM route;;
END;;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mini_segment_splits_from_point(end_lat double precision, end_lon double precision, intermediate_lat double precision, intermediate_lon double precision)
RETURNS TABLE (id uuid, mini_segment geometry, first geometry, start_length double precision, second geometry, end_length double precision) AS $$
BEGIN
  RETURN QUERY
  WITH end_point AS (SELECT ST_GeomFromText('POINT('||end_lat||' '||end_lon||')',4326)),
       intermediate_point AS (SELECT ST_GeomFromText('POINT('||intermediate_lat||' '||intermediate_lon||')',4326)),
       ratio AS (SELECT ST_LinelocatePoint(mini_segment_polyline, (SELECT * FROM end_point))
        FROM mini_segments_to_segments ORDER BY mini_segment_polyline <-> (SELECT * FROM end_point) LIMIT 1)
  SELECT
    mini_segment_id as id,
    mini_segment_polyline as geom,
    ST_LineSubstring(mini_segment_polyline,
      (SELECT CASE
      WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN 0 ELSE (SELECT * FROM ratio) END),
      (SELECT CASE
      WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN (SELECT * FROM ratio) ELSE 1 END)) as first,
    ST_Length(ST_LineSubstring(mini_segment_polyline,
      (SELECT CASE
      WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN 0 ELSE (SELECT * FROM ratio) END),
      (SELECT CASE
      WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN (SELECT * FROM ratio) ELSE 1 END)), false) as first_length,
    ST_LineSubstring(mini_segment_polyline,
    (SELECT CASE
    WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN (SELECT * FROM ratio) ELSE 0 END),
    (SELECT CASE
    WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN 1 ELSE (SELECT * FROM ratio) END)) as second,
    ST_Length(ST_LineSubstring(mini_segment_polyline,
    (SELECT CASE
    WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN (SELECT * FROM ratio) ELSE 0 END),
    (SELECT CASE
    WHEN ST_Distance((SELECT * FROM intermediate_point), ST_StartPoint(mini_segment_polyline)) < ST_Distance((SELECT * FROM end_point), ST_StartPoint(mini_segment_polyline)) THEN 1 ELSE (SELECT * FROM ratio) END)), false) as second_length
  FROM mini_segments_to_segments
  WHERE ST_DWithin(mini_segment_polyline, (SELECT * from end_point), 5, false)
  ORDER BY mini_segment_polyline <-> (SELECT * FROM end_point)
  LIMIT 1;;
END;;
$$ LANGUAGE plpgsql;

# --- !Downs

DROP FUNCTION closest_point_on_road(double precision, double precision);
DROP FUNCTION closest_road_to_point(double precision, double precision);
DROP FUNCTION shortest_distance_route(double precision, double precision, double precision, double precision);
DROP FUNCTION mini_segment_splits_from_point(lon double precision, lng double precision);
