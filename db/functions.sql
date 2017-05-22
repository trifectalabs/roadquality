CREATE OR REPLACE FUNCTION vertex_from_point(lo double precision, la double precision)
RETURNS integer AS $$
DECLARE
	node integer;
BEGIN
	SELECT n.id INTO node
	FROM ways_vertices_pgr n
	ORDER BY n.the_geom <-> ST_GeometryFromText('POINT('||lo||' '||la||')', 4326)
	LIMIT 1;
	RETURN node;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION closest_point_on_road(lon double precision, lat double precision)
RETURNS TABLE (x double precision, y double precision) AS $$
DECLARE
	w closest_point;
BEGIN
  RETURN QUERY
  SELECT ST_X(p) as x, ST_Y(p) as y
  FROM ST_ClosestPoint(
    (SELECT road from closest_road_to_point(lon, lat)),
    (SELECT ST_GeometryFromText('POINT('||lon||' '||lat||')',4326))
  ) AS p
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION closest_road_to_point(lon double precision, lat double precision)
RETURNS TABLE (id bigint, road geometry) AS $$
DECLARE
  road closest_road;
BEGIN
  RETURN QUERY
  SELECT planet_osm_line_noded.id, way as road
  FROM planet_osm_line_noded
  ORDER BY way <-> ST_GeomFromText('POINT('||lon||' '||lat||')',4326) ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ways_from_segment(polyline text)
RETURNS TABLE (way_id bigint) AS $$
BEGIN
  RETURN QUERY
    WITH
      intersection_points AS (SELECT id, name, (st_intersection(planet_osm_line_noded.way, (st_linefromencodedpolyline(polyline)))) intersection
        FROM planet_osm_line_noded
        WHERE st_intersects(st_linefromencodedpolyline(polyline),
          planet_osm_line_noded.way))
    SELECT intersection_points.id FROM intersection_points
    LEFT JOIN planet_osm_line_noded_vertices_pgr ON st_distance(intersection, the_geom) < 0.000005
    WHERE planet_osm_line_noded_vertices_pgr.id is null;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION shortest_distance_route(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision)
RETURNS TABLE (x double precision, y double precision) AS $$
DECLARE
	route text;
BEGIN
  RETURN QUERY
  WITH start_road      AS (SELECT * from closest_road_to_point(start_lon, start_lat)),
       end_road        AS (SELECT * from closest_road_to_point(end_lon, end_lat)),
       start_point     AS (SELECT ST_GeometryFromText('POINT('||start_lon||' '||start_lat||')',4326)),
       end_point       AS (SELECT ST_GeometryFromText('POINT('||end_lon||' '||end_lat||')',4326)),
       route           AS (SELECT * from pgr_trsp('SELECT id::integer, source::integer, target::integer, distance::float8 as cost FROM planet_osm_line_noded',
                          (SELECT id from start_road)::integer,
                          (SELECT ST_LineLocatePoint((SELECT road from start_road), (SELECT * FROM start_point))),
                          (SELECT id from end_road)::integer,
                          (SELECT ST_LineLocatePoint((SELECT road from end_road), (SELECT * FROM end_point))),
                          false, false) AS r INNER JOIN planet_osm_line_noded as ways on ways.id = r.id2
                          where r.seq <> 1 and r.id2 <> ((SELECT id from end_road)::integer)),
       corrected_start AS (SELECT ST_SetPoint((SELECT ST_MakeLine(result.way) FROM route AS result), 0,
                          (ST_LineInterpolatePoint(
                          (SELECT way from planet_osm_line_noded where id = (SELECT id from start_road)),
                          (SELECT ST_LineLocatePoint((SELECT road from start_road), (SELECT * FROM start_point))))))),
       corrected_path  AS (SELECT ST_SetPoint((SELECT * FROM corrected_start), -1, (ST_LineInterpolatePoint(
                          (SELECT way from planet_osm_line_noded where id = (SELECT id from end_road)),
                          (SELECT ST_LineLocatePoint((SELECT road from end_road), (SELECT * FROM end_point))))))),
       result          AS (SELECT ST_X((ST_dumppoints((SELECT * FROM corrected_path))).geom), ST_Y((ST_dumppoints((SELECT * FROM corrected_path))).geom))
  SELECT * from result;
END;
$$ LANGUAGE plpgsql;
