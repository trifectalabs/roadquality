package db.dao

import com.trifectalabs.roadquality.v0.models.{ MapRoute, Point }

import scala.concurrent.Future

trait RoutesDao {
  def route(startPoint: Point, endPoint: Point): Future[MapRoute]
  def snapPoint(point: Point): Future[Point]
  def waysFromSegment(segmentPolyline: String): Future[Seq[Long]]
}
