package db.dao

import java.util.UUID

import com.trifectalabs.roadquality.v0.models.{Segment, SegmentForm}

import scala.concurrent.Future

trait SegmentsDao {
  def getAllSegments: Future[Seq[Segment]]
  def getSegment(id: UUID): Future[Option[Segment]]
  def getSegmentsBoundingBox(tr: Double, tl: Double, br: Double, bl: Double): Future[Seq[Segment]]
  def delete(id: UUID): Future[Unit]
  def upsert(segmentForm: SegmentForm): Future[Segment]
  def updateTrafficRating(id: UUID, rating: Double): Future[Segment]
  def updateSurfaceRating(id: UUID, rating: Double): Future[Segment]
}
