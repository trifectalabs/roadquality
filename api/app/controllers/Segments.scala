package controllers

import models.{ FormValidator, FormError }

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.{ SegmentCreateForm, SegmentUpdateForm }
import com.trifectalabs.roadquality.v0.models.json._
import db.dao.SegmentsDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.AuthLoggingAction
import services.SegmentService

import scala.concurrent.{ExecutionContext, Future}

class Segments @Inject() (segmentsDao: SegmentsDao, segmentService: SegmentService, authLoggingAction:AuthLoggingAction)(implicit ec: ExecutionContext) extends Controller {
  import authLoggingAction._
  implicit def formErrorFormat = Json.writes[FormError]

  def get(segment_id: Option[UUID]) = AuthLoggingAction.async {
    segment_id.map(id => segmentsDao.getById(id).map(s => Ok(Json.toJson(Seq(s)))))
      .getOrElse(segmentsDao.getAll.map(s => Ok(Json.toJson(s))))
  }

  def getBoundingbox(xmin: Option[Double], ymin: Option[Double], xmax: Option[Double], ymax: Option[Double]) = AuthLoggingAction.async {
    (for {
      x_min <- xmin
      y_min <- ymin
      x_max <- xmax
      y_max <- ymax
      } yield {
        segmentsDao.getByBoundingBox(x_min, y_min, x_max, y_max).map(s => Ok(Json.toJson(s)))
      }).getOrElse(Future(BadRequest))
	}

  def getBoundingbox(xmin: Double, ymin: Double, xmax: Double, ymax: Double) = AuthLoggingAction.async {
    segmentsDao.getByBoundingBox(xmin, ymin, xmax, ymax).map(s => Ok(Json.toJson(s)))
	}

  def post() = AuthLoggingAction.async(parse.json[SegmentCreateForm]) { implicit request =>
    val segForm = request.body
    FormValidator.validateSegmentCreateForm(segForm) match {
      // TODO fix the user uuid
      case Nil => segmentService.createSegment(segForm, UUID.fromString("e34f4f39-edcb-4d65-9969-264db37681eb")).map(s => Ok(Json.toJson(s)))
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
	}

  def put(segmentId: UUID) = AuthLoggingAction.async(parse.json[SegmentUpdateForm]) { implicit request =>
    val segmentUpdateForm = request.body
    FormValidator.validateSegmentUpdateForm(segmentUpdateForm) match {
      case Nil =>
        segmentsDao.getById(segmentId).flatMap { existingSegment =>
          val updatedSegment = existingSegment.copy(
            name = if (!segmentUpdateForm.name.isDefined) existingSegment.name else Some(segmentUpdateForm.name.get),
            description = if (!segmentUpdateForm.description.isDefined) existingSegment.description else Some(segmentUpdateForm.description.get)
          )

          segmentsDao.update(updatedSegment).map(s => Ok(Json.toJson(s)))
        }
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
  }

}
