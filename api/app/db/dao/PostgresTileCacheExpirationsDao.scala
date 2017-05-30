package db.dao

import javax.inject.{Inject, Singleton}

import models.TileCacheExpiration
import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresTileCacheExpirationsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends TileCacheExpirationsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import driver.api._

  override def insert(tileCacheExpiration: TileCacheExpiration): Future[TileCacheExpiration] = {
    db.run((tileCacheExpirations += tileCacheExpiration).map(_ => tileCacheExpiration))
  }

}
