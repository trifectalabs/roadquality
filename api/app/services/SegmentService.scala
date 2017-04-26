package services

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models.{ SegmentCreateForm, Rating, Segment }
import db.dao.{ SegmentsDao, RoutesDao, RatingsDao }


trait SegmentService {
  def createSegment(segmentCreateForm: SegmentCreateForm, userId: UUID): Future[Segment]
}

class SegmentServiceImpl @Inject()(segmentsDao: SegmentsDao, routesDao: RoutesDao, ratingsDao: RatingsDao)(implicit ec: ExecutionContext) extends SegmentService {

  def createSegment(segmentCreateForm: SegmentCreateForm, userId: UUID): Future[Segment] = {
    // Create and store the segment, then create and store the rating. Return the segment
    val segmentId = UUID.randomUUID()
    segmentsDao.create(segmentId, segmentCreateForm) map { segment =>
      val waysFut = routesDao.waysFromSegment(segmentCreateForm.polyline)
      waysFut.map { _ foreach { id =>
        val r = Rating(
          id, segmentId, userId, segmentCreateForm.trafficRating, segmentCreateForm.surfaceRating,
          segmentCreateForm.surface, segmentCreateForm.pathType, DateTime.now(), DateTime.now()
        )
        ratingsDao.insert(r)
      } }
      segment
    }
  }

}
