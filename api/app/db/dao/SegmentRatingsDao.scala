package db.dao

import java.util.UUID

import com.trifectalabs.roadquality.v0.models.SegmentRating

import scala.concurrent.Future

trait SegmentRatingsDao {
  def getAll(): Future[Seq[SegmentRating]]
  def getById(id: UUID): Future[SegmentRating]
  def delete(id: UUID): Future[Unit]
  def insert(rating: SegmentRating): Future[SegmentRating]
}
