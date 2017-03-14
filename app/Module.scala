import com.google.inject.AbstractModule
import com.google.inject.name.Names
import play.api.{ Configuration, Environment }

import db.dao._

class Module(environment: Environment, configuration: Configuration) extends AbstractModule {
  override def configure(): Unit = {
    bind(classOf[SegmentsDao]).to(classOf[PostgresSegmentsDao])
  }
}
