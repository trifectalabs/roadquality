package db.dao

import java.util.UUID

import com.trifectalabs.roadquality.v0.models.{ Rating, SurfaceType, PathType }

import scala.concurrent.Future

trait RatingsDao {
  def getAll(): Future[Seq[Rating]]
  def getBySegmentId(segmentId: UUID): Future[Seq[Rating]]
  def getByWayId(wayId: Long): Future[Rating]
  def delete(wayId: Long, userId: UUID): Future[Unit]
  def insert(rating: Rating): Future[Rating]
  def updateBySegmentId(segmentId: UUID, tR: Int, sR: Int, s: SurfaceType, p: PathType): Future[Seq[Rating]]
}
