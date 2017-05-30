package db.dao

import models.TileCacheExpiration
import scala.concurrent.Future

trait TileCacheExpirationsDao {
  def insert(tileCacheExpiration: TileCacheExpiration): Future[TileCacheExpiration]
}
