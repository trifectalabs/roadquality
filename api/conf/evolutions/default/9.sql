# Only snap to road if road is within buffer (meters)

# --- !Ups
CREATE OR REPLACE FUNCTION closest_road_to_point(lon double precision, lat double precision, buffer integer)
RETURNS TABLE (id bigint, road geometry) AS $$
BEGIN
  RETURN QUERY
  SELECT gid, the_geom as road
  FROM (SELECT * FROM ways ORDER BY the_geom <-> ST_SetSRID(ST_Point(lon, lat),4326) ASC) as nearby_ways
  WHERE the_geom && ST_Buffer(CAST(ST_SetSRID(ST_Point(lon, lat),4326) AS geography), buffer)
  LIMIT 1;;
END;;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION closest_point_on_road(lon double precision, lat double precision, buffer integer)
RETURNS TABLE (x double precision, y double precision) AS $$
BEGIN
  RETURN QUERY
  SELECT ST_X(p) as x, ST_Y(p) as y
  FROM ST_ClosestPoint(
    (SELECT road from closest_road_to_point(lon, lat, buffer)),
    (SELECT ST_GeometryFromText('POINT('||lon||' '||lat||')',4326))
  ) AS p
  LIMIT 1;;
END;;
$$ LANGUAGE plpgsql;

# --- !Downs

DROP FUNCTION IF EXISTS closest_road_to_point(lon double precision, lat double precision, buffer integer);

