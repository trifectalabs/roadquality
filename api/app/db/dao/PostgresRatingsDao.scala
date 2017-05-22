package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}

import com.trifectalabs.roadquality.v0.models._
import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresRatingsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends RatingsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import driver.api._

  override def getAll(): Future[Seq[Rating]] = {
    db.run(ratings.result)
  }

  override def getBySegmentId(segmentId: UUID): Future[Seq[Rating]] = {
    db.run(ratings.filter(_.segmentId === segmentId).result)
  }

  override def getByWayId(wayId: Long): Future[Rating] = {
    db.run(ratings.filter(_.wayId === wayId).result.head)
  }

  override def delete(wayId: Long, userId: UUID): Future[Unit] = {
    db.run(ratings.filter(s => s.wayId === wayId && s.userId === userId).delete.map(_ => ()))
  }

  override def insert(rating: Rating): Future[Rating] = {
    db.run((ratings += rating).map(_ => rating))
  }

  override def updateBySegmentId(
    segmentId: UUID,
    tR: Int,
    sR: Int,
    s: SurfaceType,
    p: PathType
  ): Future[Seq[Rating]] = {
    val query = for { r <- ratings if r.segmentId === segmentId }
      yield (r.trafficRating, r.surfaceRating, r.surface, r.pathType)
    db.run(query.update(tR, sR, s, p)).flatMap(_ => getBySegmentId(segmentId).map(s => s))
  }

}
