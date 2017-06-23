package controllers

import models.{ FormValidator, FormError }

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.{ SegmentCreateForm, SegmentUpdateForm }
import com.trifectalabs.roadquality.v0.models.json._
import db.dao.SegmentsDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.Authenticated
import services.SegmentService

import scala.concurrent.{ExecutionContext, Future}

class Segments @Inject() (segmentsDao: SegmentsDao, segmentService: SegmentService)(implicit ec: ExecutionContext) extends Controller {
  implicit def formErrorFormat = Json.writes[FormError]

  def get(segment_id: Option[UUID]) = Authenticated.async {
    segment_id.map(id => segmentsDao.getById(id).map(s => Ok(Json.toJson(Seq(s)))))
      .getOrElse(segmentsDao.getAll.map(s => Ok(Json.toJson(s))))
  }

  def getBoundingbox(xmin: Option[Double], ymin: Option[Double], xmax: Option[Double], ymax: Option[Double]) = Action.async {
    (for {
      x_min <- xmin
      y_min <- ymin
      x_max <- xmax
      y_max <- ymax
      } yield {
        segmentsDao.getByBoundingBox(x_min, y_min, x_max, y_max).map(s => Ok(Json.toJson(s)))
      }).getOrElse(Future(BadRequest))
	}

  def post() = Authenticated.async(parse.json[SegmentCreateForm]) { req =>
    val segForm = req.body

    FormValidator.validateSegmentCreateForm(segForm) match {
      case Nil => segmentService.createSegment(segForm, req.user.id).map(s => Created(Json.toJson(s)))
      case errors => Future(BadRequest(Json.toJson(errors)))
    }
	}

  def put(segmentId: UUID) = Authenticated.async(parse.json[SegmentUpdateForm]) { req =>
    val segmentUpdateForm = req.body
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
