package db.dao

import javax.inject.{Inject, Singleton}

import com.trifectalabs.road.quality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresRoutesDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends RoutesDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import driver.api._

  implicit val getRouteResult = GetResult(r => MapRoute(r.nextString(), r.nextDouble()))
  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))

  override def route(startPoint: Point, endPoint: Point): Future[MapRoute] = {
    val sql = sql"""
      SELECT ST_AsEncodedPolyline(r.the_geom), r.distance
      FROM tri_route_1(
        (SELECT * from tri_nearest(${startPoint.lat}, ${startPoint.lng}))
      , (SELECT * FROM tri_nearest(${endPoint.lat},${endPoint.lng}))) r""".as[String]
    val a = db.run(sql).map(r => r.head)
    a.map(r => MapRoute(r, 0))
  }

  override def snapPoint(point: Point): Future[Point] = {
    val sql = sql"""
      SELECT lat, lon
      FROM ways_vertices_pgr
      WHERE id = (
        SELECT * from tri_nearest(${point.lat}, ${point.lng})
      );
    """.as[Point]
    db.run(sql).map(r => r.head)
  }

}
