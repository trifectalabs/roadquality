# Migrate intersection splits from segment to evolutions

# --- !Ups
CREATE OR REPLACE FUNCTION intersection_splits_from_segment(polyline text, snap_distance float, buffer integer)
RETURNS TABLE (intersections geometry) AS $$
BEGIN
  RETURN QUERY
    WITH
      polyline       AS (SELECT ST_LineFromEncodedPolyline(polyline)),
      nearby_verices AS (SELECT the_geom FROM ways_vertices_pgr ORDER BY the_geom <-> (SELECT * FROM polyline) LIMIT buffer),
      intersections  AS (SELECT the_geom as intersection FROM nearby_verices WHERE ST_DWithin(the_geom, (SELECT * FROM polyline), 5, false))
      SELECT (st_dump(
        ST_Split(
          ST_Snap(
            (SELECT * FROM polyline),
            (SELECT ST_Collect(array_agg(intersection::geometry)) FROM intersections),
            snap_distance
          ),
          (SELECT ST_Collect(array_agg(intersection::geometry)) FROM intersections)
        )
    )).geom;;
END;;
$$ LANGUAGE plpgsql;


# --- !Downs

DROP FUNCTION IF EXISTS intersection_splits_from_segment(segment text, snap_distance float, buffer integer);

