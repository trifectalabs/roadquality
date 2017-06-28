import com.google.inject.AbstractModule
import db.dao._
import services._
import play.api.{Configuration, Environment}

class Module(environment: Environment, configuration: Configuration) extends AbstractModule {
  override def configure(): Unit = {
    // DAOs
    bind(classOf[MapDao]).to(classOf[PostgresMapDao])
    bind(classOf[UsersDao]).to(classOf[PostgresUsersDao])
    bind(classOf[SegmentsDao]).to(classOf[PostgresSegmentsDao])
    bind(classOf[MiniSegmentsDao]).to(classOf[PostgresMiniSegmentsDao])
    bind(classOf[SegmentRatingsDao]).to(classOf[PostgresSegmentRatingsDao])
    bind(classOf[BetaUserWhitelistDao]).to(classOf[PostgresBetaUserWhitelistDao])

    // Services
    bind(classOf[RoutingService]).to(classOf[RoutingServiceImpl])
    bind(classOf[SegmentService]).to(classOf[SegmentServiceImpl])
  }
}
