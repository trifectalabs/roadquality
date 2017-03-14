import com.google.inject.AbstractModule
import db.dao._
import play.api.{Configuration, Environment}

class Module(environment: Environment, configuration: Configuration) extends AbstractModule {
  override def configure(): Unit = {
    bind(classOf[SegmentsDao]).to(classOf[PostgresSegmentsDao])
    bind(classOf[RoutesDao]).to(classOf[PostgresRoutesDao])
  }
}
