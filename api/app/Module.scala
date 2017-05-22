import com.google.inject.AbstractModule
import db.dao._
import services._
import play.api.{Configuration, Environment}

class Module(environment: Environment, configuration: Configuration) extends AbstractModule {
  override def configure(): Unit = {
    bind(classOf[SegmentsDao]).to(classOf[PostgresSegmentsDao])
    bind(classOf[MapsDao]).to(classOf[PostgresMapsDao])
    bind(classOf[RatingsDao]).to(classOf[PostgresRatingsDao])
    bind(classOf[UsersDao]).to(classOf[PostgresUsersDao])
    bind(classOf[RoutingService]).to(classOf[RoutingServiceImpl])
    bind(classOf[SegmentService]).to(classOf[SegmentServiceImpl])
  }
}
