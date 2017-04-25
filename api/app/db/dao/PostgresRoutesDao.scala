package db.dao

import javax.inject.{Inject, Singleton}

import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
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
    val sql = sql"""SELECT * from closest_point_on_road(${point.lng}, ${point.lat});""".as[Point]
    db.run(sql).map(r => r.head)
  }

  override def waysFromSegment(segment_polyline: String): Future[Seq[Long]] = {
    val sql = sql"""SELECT * from ways_from_segment(${segment_polyline});""".as[Long]
    db.run(sql)
  }
}
