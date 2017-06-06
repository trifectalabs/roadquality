package controllers

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.json._
import db.dao.SegmentRatingsDao
import play.api.libs.json.Json
import play.api.mvc.Controller
import util.actions.Authenticated

import scala.concurrent.ExecutionContext

class SegmentRatings @Inject()(ratingsDao: SegmentRatingsDao)(implicit ec: ExecutionContext) extends Controller {

  def get(id: UUID) = Authenticated.async { req =>
    ratingsDao.getById(id).map(s => Ok(Json.toJson(s)))
  }

  def delete(id: UUID) = Authenticated.async { req =>
    ratingsDao.delete(id).map(_ => Accepted(Json.toJson(true)))
  }
}
