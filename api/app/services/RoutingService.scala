package services

import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}

import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.dao.MapDao
import scala.concurrent.{ExecutionContext, Future}
import play.api.libs.ws._
import play.api.libs.json._
import play.api.Configuration

trait RoutingService {
  def generateRoute(points: String): Future[MapRoute]
  def snapPoint(point: Point): Future[Point]
}

class RoutingServiceImpl @Inject()(configuration: Configuration, ws: WSClient)(implicit ec: ExecutionContext) extends RoutingService {
  lazy val osrmRoutingUri = configuration.getString("osrm.routing.uri").get
  lazy val osrmNearestUri = configuration.getString("osrm.nearest.uri").get

  def generateRoute(points: String): Future[MapRoute] = {
    val osrmUrl = s"$osrmRoutingUri/$points"
    ws.url(osrmUrl).get().map { res =>
      val routes = (res.json \ "routes").as[List[JsValue]]
      val polyline = (routes(0) \ "geometry").as[String]
      val distance = (routes(0) \ "distance").as[Double]

      MapRoute(
        polyline = polyline,
        distance = distance
      )
    }
  }

  def snapPoint(point: Point): Future[Point] = {
    val pointString = s"${point.lng},${point.lat}"
    val osrmUrl = s"$osrmNearestUri/$pointString"
    ws.url(osrmUrl).get().map { res =>
      val waypoints = (res.json \ "waypoints").as[List[JsValue]]
      val location = (waypoints(0) \ "location").as[List[Double]]
      Point(
        lng = location(1),
        lat = location(0)
      )
    }
  }

}
