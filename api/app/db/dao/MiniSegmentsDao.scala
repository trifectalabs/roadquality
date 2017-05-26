package db.dao

import com.vividsolutions.jts.geom.Geometry
import models._
import java.util.UUID

import com.trifectalabs.roadquality.v0.models.{Point, Segment, SegmentCreateForm}

import scala.concurrent.Future

trait MiniSegmentsDao {
  def getAll(): Future[Seq[MiniSegmentToSegment]]
  def getById(miniSegmentId: UUID): Future[MiniSegmentToSegment]
  def miniSegmentSplitsFromPoint(endPoint: Point, intermediatePoint: Point): Future[Option[MiniSegmentSplit]]
  def overlappingMiniSegmentsFromPolyline(polyline: String): Future[Seq[MiniSegmentToSegment]]
  def insert(miniSegmentToSegment: MiniSegmentToSegment): Future[MiniSegmentToSegment]
  def update(miniSegmentId: UUID, geometry: Geometry): Future[Unit]
}
