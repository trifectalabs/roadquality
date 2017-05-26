package controllers

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.json._
import db.dao.SegmentRatingsDao
import play.api.libs.json.Json
import play.api.mvc.Controller
import util.actions.AuthLoggingAction

import scala.concurrent.ExecutionContext

class SegmentRatings @Inject()(ratingsDao: SegmentRatingsDao, authLoggingAction:AuthLoggingAction)(implicit ec: ExecutionContext) extends Controller {
  import authLoggingAction._

  def get(id: UUID) = AuthLoggingAction.async {
    ratingsDao.getById(id).map(s => Ok(Json.toJson(s)))
  }

  def delete(id: UUID) = AuthLoggingAction.async {
    ratingsDao.delete(id).map(_ => Accepted(Json.toJson(true)))
  }
}
