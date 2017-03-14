package controllers

import javax.inject.Inject

import com.trifectalabs.road.quality.v0.models.json._
import db.dao.RoutesDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}

import scala.concurrent.ExecutionContext

class Routes @Inject() (routesDao: RoutesDao)(implicit ec: ExecutionContext) extends Controller {

  def get(start_lat: Double, start_lng: Double, end_lat: Double, end_lng: Double) = Action.async {
    routesDao.get(start_lat, start_lng, end_lat, end_lng).map(r => Ok(Json.toJson(r)))
  }
}

