package controllers

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.road.quality.v0.models.SegmentForm
import com.trifectalabs.road.quality.v0.models.json._
import db.dao.SegmentsDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.LoggingAction

import scala.concurrent.ExecutionContext

class Segments @Inject() (segmentsDao: SegmentsDao)(implicit ec: ExecutionContext) extends Controller {

  def getAll() = LoggingAction.async {
    segmentsDao.getAllSegments.map(s => Ok(Json.toJson(s)))
  }

  def getBySegmentId(segment_id: UUID) = LoggingAction.async {
    segmentsDao.getSegment(segment_id).map(s => Ok(Json.toJson(s)))
	}

  def post() = LoggingAction.async(parse.json[SegmentForm]) { implicit request =>
    val segForm = request.body
    segmentsDao.upsert(segForm).map(s => Ok(Json.toJson(s)))
	}

  def patchRatingBySegmentIdAndRating(segment_id: _root_.java.util.UUID, rating: Double) = LoggingAction.async { implicit request =>
    segmentsDao.updateRating(segment_id, rating).map(s => Ok(Json.toJson(s)))
	}

}
