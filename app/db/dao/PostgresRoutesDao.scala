package db.dao

import javax.inject.{Inject, Singleton}

import com.trifectalabs.road.quality.v0.models.Route
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresRoutesDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends RoutesDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import driver.api._

  override def get(start_lat: Double, start_lng: Double, end_lat: Double, end_lng: Double): Future[Route] = {
    implicit val getRouteResult = GetResult(r => Route(r.nextString(), r.nextDouble()))
    val sql = sql"""
      SELECT ST_AsEncodedPolyline(r.the_geom), r.distance
      FROM tri_route_1(
        (SELECT * from tri_nearest($start_lat, $start_lng))
      , (SELECT * FROM tri_nearest($end_lat,$end_lng))) r""".as[Route]
    db.run(sql).map(r => r.head)
  }

}
