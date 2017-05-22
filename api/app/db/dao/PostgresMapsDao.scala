package db.dao

import javax.inject.{Inject, Singleton}

import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresMapsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends MapsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import driver.api._

  implicit val getRouteResult = GetResult(r => MapRoute(r.nextString(), r.nextDouble()))
  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))

  override def route(startPoint: Point, endPoint: Point): Future[MapRoute] = {
    val strSql = s"""SELECT x, y from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat});"""
    val sql = sql"""SELECT y, x from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat});""".as[Point]
    println(strSql)
    db.run(sql).map { t =>
      val points = t.toList.map(p => LatLng(p.lat, p.lng))
      val pl = Polyline.encode(points)
      MapRoute(pl, 0)
    }
  }

  override def snapPoint(point: Point): Future[Point] = {
    // TODO Lat and lng are backwards
    val sql = sql"""
      WITH closest_road AS (
        SELECT way as road
        FROM planet_osm_line_noded
        ORDER BY way <-> ST_GeomFromText('POINT(${point.lng} ${point.lat})',4326) ASC
        LIMIT 1)
      SELECT ST_X(p) as x, ST_Y(p) as y
      FROM ST_ClosestPoint(
        (SELECT * FROM closest_road),
        (SELECT ST_GeometryFromText('POINT(${point.lng} ${point.lat})',4326))
      ) AS p
      LIMIT 1;
    """.as[Point]
    db.run(sql).map(r => r.head)
  }

  override def waysFromSegment(segmentPolyline: String): Future[Seq[Long]] = {
    val sql = sql"""
      WITH
        intersection_points AS (
          SELECT osm_id id, name,
            (st_intersection(planet_osm_line.way, (st_linefromencodedpolyline(${segmentPolyline})))) intersection
          FROM planet_osm_line
          WHERE st_intersects(st_linefromencodedpolyline(${segmentPolyline}),
            planet_osm_line.way))
      SELECT intersection_points.id FROM intersection_points
      LEFT JOIN planet_osm_line_noded_vertices_pgr ON st_distance(intersection, the_geom) < 0.000005
      WHERE planet_osm_line_noded_vertices_pgr.id is null;
    """.as[Long]
    db.run(sql)
  }
}
