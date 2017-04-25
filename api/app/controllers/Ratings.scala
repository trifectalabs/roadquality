package controllers

import models.{ FormValidator, FormError }

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.{ Rating }
import com.trifectalabs.roadquality.v0.models.json._
import db.dao.RatingsDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.AuthLoggingAction

import scala.concurrent.{ExecutionContext, Future}

class Ratings @Inject() (ratingsDao: RatingsDao, authLoggingAction:AuthLoggingAction)(implicit ec: ExecutionContext) extends Controller {
  import authLoggingAction._

  def get(wayId: Long) = AuthLoggingAction.async {
    ratingsDao.getByWayId(wayId).map(s => Ok(Json.toJson(s)))
  }

  def delete(userId: UUID, wayId: Long) = AuthLoggingAction.async {
    ratingsDao.delete(wayId, userId).map(_ => Accepted(Json.toJson(true)))
  }
}
