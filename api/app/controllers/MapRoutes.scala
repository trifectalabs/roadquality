package controllers

import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.Point
import com.trifectalabs.roadquality.v0.models.json._
import services.RoutingService
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.Authenticated

import scala.concurrent.{ExecutionContext, Future}

class MapRoutes @Inject() (routingService: RoutingService)(implicit ec: ExecutionContext) extends Controller {

  def getByPoints(points: String) = Authenticated.async { req =>
    routingService.generateRoute(points)
      .map(r => Ok(Json.toJson(r)))
      .fallbackTo(Future(ServiceUnavailable))
  }

  def getSnap(lat: Double, lng: Double) = Authenticated.async { req =>
    routingService.snapPoint(Point(lat, lng))
      .map(p => Ok(Json.toJson(p)))
      .fallbackTo(Future(ServiceUnavailable))
  }
}

