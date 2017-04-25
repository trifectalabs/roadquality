package db.dao

import java.util.UUID

import com.trifectalabs.roadquality.v0.models.{ Rating }

import scala.concurrent.Future

trait RatingsDao {
  def getByWayId(wayId: Long): Future[Rating]
  def delete(wayId: Long, userId: UUID): Future[Unit]
  def insert(rating: Rating): Future[Rating]
}
