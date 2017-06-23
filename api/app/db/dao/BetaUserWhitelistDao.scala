package db.dao

import java.util.UUID
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models.SegmentRating

import scala.concurrent.Future

// TODO: Remove after beta
trait BetaUserWhitelistDao {
  def exists(email: String): Future[Boolean]
}
