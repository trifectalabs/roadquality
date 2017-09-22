package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models._
import db.MyPostgresDriver
import db.Tables._
import util.Metrics
import models.Extent
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult
import play.Environment

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresSegmentRatingsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider, override val env: Environment)(implicit ec: ExecutionContext)
  extends SegmentRatingsDao with HasDatabaseConfigProvider[MyPostgresDriver] with Metrics {
  import _root_.db.TablesHelper._
  import profile.api._

  implicit val getExtentResult = GetResult(r => Extent(r.nextDouble(), r.nextDouble(), r.nextDouble(), r.nextDouble()))

  override def getAll(): Future[Seq[SegmentRating]] = {
    db.run(segmentRatings.result)
  }

  override def getById(id: UUID): Future[SegmentRating] = {
    db.run(segmentRatings.filter(s => s.id === id).result.head)
  }

  override def delete(id: UUID): Future[Unit] = {
    db.run(segmentRatings.filter(s => s.id === id).delete.map(_ => ()))
  }

  override def insert(rating: SegmentRating): Future[SegmentRating] = {
    db.run((segmentRatings += rating).map(_ => rating))
  }

  override def getBoundsFromRatings(created_at: DateTime): Future[Extent] = {
    val sql = sql"""
      SELECT
        st_xmin((SELECT ST_Extent(ST_Transform(ST_LineFromEncodedPolyline(polyline), 3857))))::text,
        st_ymin((SELECT ST_Extent(ST_Transform(ST_LineFromEncodedPolyline(polyline), 3857))))::text,
        st_xmax((SELECT ST_Extent(ST_Transform(ST_LineFromEncodedPolyline(polyline), 3857))))::text,
        st_ymax((SELECT ST_Extent(ST_Transform(ST_LineFromEncodedPolyline(polyline), 3857))))::text
      FROM segment_ratings sr JOIN segments s ON sr.segment_id = s.id
      WHERE created_at = ${new java.sql.Timestamp(created_at.getMillis())}""".as[Extent]
    dbMetrics.timer("getBoundsFromRatings").timeFuture { db.run((sql).map{ d => d.head } ) }
  }

}
