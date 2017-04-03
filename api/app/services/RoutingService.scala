package services

import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}

import com.trifectalabs.road.quality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.dao.RoutesDao


trait RoutingService {
  def generateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double): Future[MapRoute]
  def generateRoute(points: Seq[Point]): Future[MapRoute]
  def snapPoint(point: Point): Future[Point]
}


class RoutingServiceImpl @Inject()(routesDao: RoutesDao)(implicit ec: ExecutionContext) extends RoutingService {

  def generateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double): Future[MapRoute] = {
    routesDao.route(
      Point(startLat, startLng),
      Point(endLat, endLng)
    )
  }

  def generateRoute(points: Seq[Point]): Future[MapRoute] = {
      println(s"Points: $points")
    Future.sequence {
      (points.init zip points.tail).map { case (p1, p2) =>
        println(s"Generating polyline between $p1 and $p2")
        routesDao.route(p1, p2).map(r => Polyline.decode(r.polyline))
      }
    } map { b =>
      println(b)
      val pl = Polyline.encode(b.flatten.toList)
      println(pl)
      MapRoute(polyline = pl, distance = 0) }
  }

  def snapPoint(point: Point): Future[Point] = {
    routesDao.snapPoint(point)
  }

}
