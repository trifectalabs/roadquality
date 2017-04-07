package controllers

import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.Point
import com.trifectalabs.roadquality.v0.models.json._
import services.RoutingService
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.AuthLoggingAction

import scala.concurrent.ExecutionContext

class MapRoutes @Inject() (routingService: RoutingService, authLoggingAction: AuthLoggingAction)(implicit ec: ExecutionContext) extends Controller {
  import authLoggingAction._

  def get(start_lat: Double, start_lng: Double, end_lat: Double, end_lng: Double) = AuthLoggingAction.async  {
    routingService.generateRoute(start_lat, start_lng, end_lat, end_lng).map { r =>
        println(s"Polyline: $r")
        Ok(Json.toJson(r))
    }
  }

  def getSnap(lat: Double, lng: Double) = AuthLoggingAction.async {
    routingService.snapPoint(Point(lat, lng)).map(p => Ok(Json.toJson(p)))
    }
  }

  def post() = AuthLoggingAction.async(parse.json[Seq[Point]]) { implicit request =>
    val points = request.body
    routingService.generateRoute(points).map { r =>
      Ok(Json.toJson(r))
    }
  }
}

