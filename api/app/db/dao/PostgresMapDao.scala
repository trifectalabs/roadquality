package db.dao

import javax.inject.{Inject, Singleton}

import com.vividsolutions.jts.geom.Geometry
import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresMapDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends MapDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import driver.api._

  implicit val getRouteResult = GetResult(r => MapRoute(r.nextString(), r.nextDouble()))
  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))

  override def route(startPoint: Point, endPoint: Point): Future[MapRoute] = {
    val strSql = s"""SELECT x, y from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat});"""
    val sql = sql"""SELECT y, x from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat});""".as[Point]
    db.run(sql).map { t =>
      val points = t.toList.map(p => LatLng(p.lat, p.lng))
      val pl = Polyline.encode(points)
      MapRoute(pl, 0)
    }
  }

  override def snapPoint(point: Point): Future[Point] = {
    val sql = sql"""SELECT * from closest_point_on_road(${point.lng}, ${point.lat});""".as[Point]
    db.run(sql).map(r => r.head)
  }

  override def intersectionsSplitsFromSegment(segment_polyline: String): Future[Seq[Geometry]] = {
    val sql = sql"""
      WITH
        polyline      AS (SELECT ST_LineFromEncodedPolyline(${segment_polyline})),
        intersections AS (SELECT the_geom as intersection FROM ways_vertices_pgr
          WHERE ST_DWithin(the_geom, (SELECT * FROM polyline), 5, false))
      SELECT ((ST_Dump(ST_Split(
        (SELECT * FROM polyline),
        (ST_Snap(ST_Union(intersection),(SELECT * FROM polyline), 0.001))))).geom) FROM intersections;
    """.as[Geometry]
    db.run(sql)
  }
}
