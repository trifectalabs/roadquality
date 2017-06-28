package db.dao

import java.util.UUID
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models.SegmentRating
import models.Extent

import scala.concurrent.Future

trait SegmentRatingsDao {
  def getAll(): Future[Seq[SegmentRating]]
  def getById(id: UUID): Future[SegmentRating]
  def delete(id: UUID): Future[Unit]
  def insert(rating: SegmentRating): Future[SegmentRating]
  def getBoundsFromRatings(createdAt: DateTime): Future[Extent]
}
