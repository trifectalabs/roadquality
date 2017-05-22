package db.dao

import java.util.UUID
import com.trifectalabs.roadquality.v0.models.{ Segment, SegmentCreateForm }

import scala.concurrent.Future

trait SegmentsDao {
  def getAll: Future[Seq[Segment]]
  def getById(id: UUID): Future[Segment]
  def getByBoundingBox(tr: Double, tl: Double, br: Double, bl: Double): Future[Seq[Segment]]
  def delete(id: UUID): Future[Unit]
  def create(id:UUID, segmentForm: SegmentCreateForm): Future[Segment]
  def update(segment: Segment): Future[Segment]
}
