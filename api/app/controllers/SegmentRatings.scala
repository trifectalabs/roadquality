package controllers

import models.{ FormValidator, FormError }

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.{ RatingCreateForm }
import com.trifectalabs.roadquality.v0.models.json._
import db.dao.SegmentRatingsDao
import play.api.libs.json.Json
import play.api.mvc.Controller
import util.actions.Authenticated
import services.SegmentService

import scala.concurrent.{ExecutionContext, Future}

class SegmentRatings @Inject()(ratingsDao: SegmentRatingsDao, segmentService: SegmentService)(implicit ec: ExecutionContext) extends Controller {
  implicit def formErrorFormat = Json.writes[FormError]

  def get(id: UUID) = Authenticated.async { req =>
    ratingsDao.getById(id).map(s => Ok(Json.toJson(s)))
  }

  def post(id: UUID, currentZoomLevel: Option[Int]) = Authenticated.async(parse.json[RatingCreateForm]) { req =>
    val ratingForm = req.body

    FormValidator.validateRatingCreateForm(ratingForm) match {
      case Nil => segmentService.createRating(ratingForm, id, req.user.id, currentZoomLevel).map(s => Created(Json.toJson(s)))
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
  }

  def delete(id: UUID) = Authenticated.async { req =>
    ratingsDao.delete(id).map(_ => Accepted(Json.toJson(true)))
  }
}
