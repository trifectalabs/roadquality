package db.dao

import javax.inject.{Inject, Singleton}

import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}

import scala.concurrent.{ExecutionContext, Future}

// TODO: Remove after beta
@Singleton
class PostgresBetaUserWhitelistDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends BetaUserWhitelistDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import profile.api._

  override def exists(email: String): Future[Boolean] = {
    db.run(betaUserWhitelist.filter(m => m.email === email.trim).exists.result)
  }

}
