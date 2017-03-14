package db.dao

import com.trifectalabs.road.quality.v0.models.Route

import scala.concurrent.Future


trait RoutesDao {
  def get(start_lat: Double, start_lng: Double, end_lat: Double, end_lng: Double): Future[Route]
}
