package services

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models.{ SegmentCreateForm, SegmentUpdateForm, Rating, Segment }
import db.dao.{ SegmentsDao, RoutesDao, RatingsDao }


trait SegmentService {
  def createSegment(segmentCreateForm: SegmentCreateForm, userId: UUID): Future[Segment]
  def updateSegment(updatedSegment: Segment, segmentUpdateForm: SegmentUpdateForm): Future[Segment]
}

class SegmentServiceImpl @Inject()(segmentsDao: SegmentsDao, routesDao: RoutesDao, ratingsDao: RatingsDao)(implicit ec: ExecutionContext) extends SegmentService {

  def createSegment(segmentCreateForm: SegmentCreateForm, userId: UUID): Future[Segment] = {
    // Create and store the segment, then create and store the rating. Return the segment
    val segmentId = UUID.randomUUID()
    segmentsDao.create(segmentId, segmentCreateForm) map { segment =>
      val waysFut = routesDao.waysFromSegmentPolyline(segmentCreateForm.polyline)
      waysFut.map { _ foreach { id =>
        val r = Rating(
          id, segmentId, userId, segmentCreateForm.trafficRating, segmentCreateForm.surfaceRating,
          segmentCreateForm.surface, segmentCreateForm.pathType, DateTime.now(), DateTime.now()
        )
        // TODO log warning about no created ratings for a segment
        ratingsDao.insert(r)
      } }
      segment
    }
  }

  def updateSegment(updatedSegment: Segment, segmentUpdateForm: SegmentUpdateForm): Future[Segment] = {
    // Update the segment, then update the corresponding ratings. Return the updated segment
    for {
      segment <- segmentsDao.update(updatedSegment)
      ratings <- ratingsDao.getBySegmentId(updatedSegment.id)
    } yield {
      // Since the segment id is specific for a user, we know that all ratings for that segment id
      // will have the same rating
      if (ratings.size > 0) {
        val tR = if (!segmentUpdateForm.trafficRating.isDefined) ratings.head.trafficRating
                 else segmentUpdateForm.trafficRating.get
        val sR = if (!segmentUpdateForm.surfaceRating.isDefined) ratings.head.surfaceRating
                 else segmentUpdateForm.surfaceRating.get
        val s = if (!segmentUpdateForm.surface.isDefined) ratings.head.surface
                else segmentUpdateForm.surface.get
        val p = if (!segmentUpdateForm.pathType.isDefined) ratings.head.pathType
                else segmentUpdateForm.pathType.get
        ratingsDao.updateBySegmentId(segment.id, tR, sR, s, p)
      }
      segment
    }
  }

}
