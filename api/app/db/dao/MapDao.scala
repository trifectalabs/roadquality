package db.dao

import com.trifectalabs.roadquality.v0.models.{ MapRoute, Point }

import com.vividsolutions.jts.geom.Geometry
import scala.concurrent.Future

trait MapDao {
  def route(startPoint: Point, endPoint: Point): Future[MapRoute]
  def snapPoint(point: Point): Future[Point]
  def intersectionsSplitsFromSegment(segmentPolyline: String): Future[Seq[Geometry]]
}
