package services

import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}

import com.trifectalabs.road.quality.v0.models.{ Point, Route }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.dao.RoutesDao


trait RoutingService {
  def generateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double): Future[Route]
  def generateRoute(points: Seq[Point]): Route
}


class RoutingServiceImpl @Inject()(routesDao: RoutesDao) extends RoutingService {

  def generateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double): Future[Route] = {
    routesDao.get(startLat, startLng, endLat, endLng)
  }

  def generateRoute(points: Seq[Point]): Route = {
  // TODO: Use PGRouting instead of this naive implmentation
    val polyline = Polyline.encode(points.map { point =>
      LatLng(lat = BigDecimal(point.lat), lng = BigDecimal(point.lng))
    }.toList)

    Route(polyline = polyline, distance = 0)
  }
}
