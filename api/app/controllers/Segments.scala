package controllers

import models.{ FormValidator, FormError }

import java.util.UUID
import javax.inject.Inject
import play.json.extra.Jsonx

import com.trifectalabs.roadquality.v0.models.SegmentForm
import com.trifectalabs.roadquality.v0.models.json._
import db.dao.SegmentsDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.AuthLoggingAction

import scala.concurrent.{ExecutionContext, Future}

class Segments @Inject() (segmentsDao: SegmentsDao, authLoggingAction:AuthLoggingAction)(implicit ec: ExecutionContext) extends Controller {
  import authLoggingAction._
  implicit def jsonFormat = Jsonx.formatCaseClass[SegmentForm]
  implicit def formErrorFormat = Json.writes[FormError]

  def get(segment_id: Option[UUID]) = AuthLoggingAction.async {
    segment_id.map(id => segmentsDao.getSegment(id).map(s => Ok(Json.toJson(s))))
              .getOrElse(segmentsDao.getAllSegments.map(s => Ok(Json.toJson(s))))
  }

  def getBoundingbox(xmin: Option[Double], ymin: Option[Double], xmax: Option[Double], ymax: Option[Double]) = AuthLoggingAction.async {
    (for {
      x_min <- xmin
      y_min <- ymin
      x_max <- xmax
      y_max <- ymax
      } yield {
        segmentsDao.getSegmentsBoundingBox(x_min, y_min, x_max, y_max).map(s => Ok(Json.toJson(s)))
      }).getOrElse(Future(BadRequest))
	}

  def getBoundingbox(xmin: Double, ymin: Double, xmax: Double, ymax: Double) = AuthLoggingAction.async {
    segmentsDao.getSegmentsBoundingBox(xmin, ymin, xmax, ymax).map(s => Ok(Json.toJson(s)))
	}

  def post() = AuthLoggingAction.async(parse.json[SegmentForm]) { implicit request =>
    val segForm = request.body
    FormValidator.validateSegmentForm(segForm) match {
      case Nil => segmentsDao.upsert(segForm).map(s => Ok(Json.toJson(s)))
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
	}

  def patchRatingAndTrafficBySegmentIdAndRating(segment_id: _root_.java.util.UUID, rating: Double) = AuthLoggingAction.async { implicit request =>
    FormValidator.validateRatingUpdate(rating) match {
      case Nil => segmentsDao.updateTrafficRating(segment_id, rating).map(s => Ok(Json.toJson(s)))
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
  }

  def patchRatingAndSurfaceBySegmentIdAndRating(segment_id: _root_.java.util.UUID, rating: Double) = AuthLoggingAction.async { implicit request =>
    FormValidator.validateRatingUpdate(rating) match {
      case Nil => segmentsDao.updateSurfaceRating(segment_id, rating).map(s => Ok(Json.toJson(s)))
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
	}

}
