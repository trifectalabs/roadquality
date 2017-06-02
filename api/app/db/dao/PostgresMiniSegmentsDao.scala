package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}

import com.trifectalabs.roadquality.v0.models._
import com.trifectalabs.polyline.{LatLng, Polyline}
import com.vividsolutions.jts.geom.Geometry
import db.MyPostgresDriver
import db.Tables._
import models._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresMiniSegmentsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends MiniSegmentsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import profile.api._

  implicit val getMiniSegmentSplitResult = GetResult(r =>
      MiniSegmentSplit(r.nextUUID, r.nextGeometry(), r.nextGeometry(), r.nextDouble(), r.nextGeometry(), r.nextDouble()))
  implicit val getMiniSegmentToSegmentResult = GetResult(r => MiniSegmentToSegment(r.nextUUID, r.nextGeometry(), r.nextUUID))

  override def getAll(): Future[Seq[MiniSegmentToSegment]] = {
    db.run(miniSegmentsToSegments.result)
  }

  override def getById(uuid: UUID): Future[MiniSegmentToSegment] = {
    db.run(miniSegmentsToSegments.filter(m => m.miniSegmentId === uuid).result.head)
  }

  override def miniSegmentSplitsFromPoint(endPoint: Point, intermediatePoint: Point): Future[Option[MiniSegmentSplit]] = {
    val sql = sql"""SELECT * FROM mini_segment_splits_from_point(${endPoint.lng}, ${endPoint.lat}, ${intermediatePoint.lng}, ${intermediatePoint.lat});""".as[MiniSegmentSplit]
      db.run(sql.map(s => s.headOption))
  }

  override def insert(miniSegmentToSegment: MiniSegmentToSegment): Future[MiniSegmentToSegment] = {
		db.run((miniSegmentsToSegments += miniSegmentToSegment).map(_ => miniSegmentToSegment))
  }

  override def update(miniSegmentId: UUID, geometry: Geometry): Future[Unit] = {
    val query = for { s <- miniSegmentsToSegments if s.miniSegmentId === miniSegmentId } yield (s.miniSegmentPolyline)
    db.run(query.update(geometry)).map(_ => ())
  }

  override def overlappingMiniSegmentsFromPolyline(polyline: String): Future[Seq[MiniSegmentToSegment]] = {
    // Retrieve biggest MiniSegment that overlaps the polyline by 95% or more
    val sql = sql"""
      WITH
        polyline_bound AS (SELECT st_buffer(st_linefromencodedpolyline(${polyline}),0.00001,'endcap=round join=round'))
      SELECT *
      FROM mini_segments_to_segments
      WHERE (st_length(st_intersection(mini_segment_polyline, (SELECT * FROM polyline_bound)))/(st_length(mini_segment_polyline))) > 0.95
      ORDER BY ST_Length(mini_segment_polyline) DESC
      LIMIT 1;
    """.as[MiniSegmentToSegment]
      db.run(sql)
  }

}
