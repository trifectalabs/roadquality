# Bounding box included in routing function

# --- !Ups
DROP function shortest_distance_route ( double precision, double precision, double precision, double precision, bounding_box integer) ;

CREATE OR REPLACE FUNCTION shortest_distance_route(start_lon double precision, start_lat double precision, end_lon double precision, end_lat double precision, bounding_box integer, nearby_ways_limit integer)
RETURNS TABLE (seq integer, path geometry, distance double precision) AS $$
BEGIN
  RETURN QUERY
  WITH start_road      AS (SELECT * from closest_road_to_point(start_lon, start_lat)),
       end_road        AS (SELECT * from closest_road_to_point(end_lon, end_lat)),
       start_point     AS (SELECT ST_GeometryFromText('POINT('||start_lon||' '||start_lat||')',4326)),
       end_point       AS (SELECT ST_GeometryFromText('POINT('||end_lon||' '||end_lat||')',4326)),
        route           AS (SELECT r.seq, r.cost, ways.the_geom from pgr_trsp('
                          SELECT gid::integer as id, source::int4, target::int4, length_m::float8 as cost
                          FROM (SELECT * from ways order by the_geom <-> (SELECT ST_SetSRID(ST_Point('||start_lon||', '||start_lat||'),4326)) LIMIT '||nearby_ways_limit||') as nearby_ways
                          WHERE the_geom && ST_Buffer(CAST(ST_SetSRID(ST_Point('||start_lon||', '||start_lat||'),4326) AS geography),'||bounding_box||')
                          AND the_geom && ST_Buffer(CAST(ST_SetSRID(ST_Point('||end_lon||', '||end_lat||'),4326) AS geography),'||bounding_box||')',
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


# --- !Downs

DROP function shortest_distance_route ( double precision, double precision, double precision, double precision, bounding_box integer, nearby_ways_limit integer ) ;
