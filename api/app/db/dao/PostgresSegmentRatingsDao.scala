package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models._
import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresSegmentRatingsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends SegmentRatingsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import profile.api._

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

  override def getBoundsFromRatings(created_at: DateTime): Future[String] = {
    val sql = sql"""SELECT st_ymin(st_extent(st_linefromencodedpolyline(polyline)))::text || ' ' || st_xmin(st_extent(st_linefromencodedpolyline(polyline)))::text || ' ' || st_ymax(st_extent(st_linefromencodedpolyline(polyline)))::text || ' ' || st_xmax(st_extent(st_linefromencodedpolyline(polyline)))::text from segment_ratings sr join segments s on sr.segment_id = s.id where created_at = ${new java.sql.Timestamp(created_at.getMillis())}""".as[String]
    db.run((sql).map{ d => d.head } )
  }

}
