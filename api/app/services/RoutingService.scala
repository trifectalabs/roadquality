package services

import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}

import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.dao.MapsDao


trait RoutingService {
  def generateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double): Future[MapRoute]
  def generateRoute(points: Seq[Point]): Future[MapRoute]
  def snapPoint(point: Point): Future[Point]
}


class RoutingServiceImpl @Inject()(mapsDao: MapsDao)(implicit ec: ExecutionContext) extends RoutingService {

  def generateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double): Future[MapRoute] = {
    mapsDao.route(
      Point(startLat, startLng),
      Point(endLat, endLng)
    )
  }

  def generateRoute(points: Seq[Point]): Future[MapRoute] = {
    Future.sequence {
      (points.init zip points.tail).map { case (p1, p2) =>
        mapsDao.route(p1, p2).map(r => Polyline.decode(r.polyline))
      }
    } map { b =>
      val pl = Polyline.encode(b.flatten.toList)
      println(pl)
      MapRoute(polyline = pl, distance = 0) }
  }

  def snapPoint(point: Point): Future[Point] = {
    mapsDao.snapPoint(point)
  }

}
