package db.dao

import com.trifectalabs.road.quality.v0.models.{ Route, Point }

import scala.concurrent.Future


trait RoutesDao {
  def route(startPoint: Point, endPoint: Point): Future[Route]
  def snapPoint(point: Point): Future[Point]
}
