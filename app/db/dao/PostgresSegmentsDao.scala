package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}

import com.trifectalabs.road.quality.v0.models.{Segment, SegmentForm}
import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresSegmentsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends SegmentsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import driver.api._

  override def getAllSegments: Future[Seq[Segment]] = {
    db.run(segments.result)
  }

  override def getSegment(id: UUID): Future[Option[Segment]] = {
    db.run(segments.filter(_.id === id).result.headOption)
  }

  override def delete(id: UUID): Future[Unit] = {
    db.run(segments.filter(_.id === id).delete.map(_ => ()))
  }

  override def upsert(segmentForm: SegmentForm): Future[Segment] = {
    // TODO Generated polyline from passed points
    val segment = Segment(
      id = UUID.randomUUID(),
      name = segmentForm.name,
      description = segmentForm.description,
      start = segmentForm.points.head,
      end = segmentForm.points.last,
      polyline = "TODO",
      rating = 3)
    db.run(segments += segment).map(_ => segment)
  }
}
