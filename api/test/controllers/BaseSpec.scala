package controllers

import org.scalatest.BeforeAndAfterEach
import org.scalatest.concurrent.ScalaFutures
import org.scalatest.time.{Milliseconds, Seconds, Span}
import org.scalatestplus.play.PlaySpec
import org.scalatestplus.play.guice.GuiceOneServerPerSuite
import play.api.Application
import play.api.db.slick.DatabaseConfigProvider
import play.api.inject.guice.GuiceApplicationBuilder
import play.api.libs.ws.WSClient
import slick.driver.JdbcProfile

import scala.concurrent.Await
import scala.concurrent.duration.Duration

trait BaseSpec extends PlaySpec with GuiceOneServerPerSuite with BeforeAndAfterEach with ScalaFutures {

  override lazy val port: Int = 9010
  override def fakeApplication(): Application = new GuiceApplicationBuilder()
    .configure(
      "slick.dbs.default.db.url" -> "jdbc:postgresql://localhost:5432/roadquality_test",
      "slick.dbs.default.db.user" -> "docker",
      "slick.dbs.default.db.password" -> "docker"
    )
    .build()

  lazy val wsClient = app.injector.instanceOf[WSClient]
  lazy val testClient = new com.trifectalabs.roadquality.v0.Client(wsClient, "http://localhost:9010")

  implicit val defaultPatienceConfig = PatienceConfig(timeout = Span(5, Seconds), interval = Span(50, Milliseconds))

  val dbConfig = DatabaseConfigProvider.get[JdbcProfile](app)
  val db = dbConfig.db
  val profile = dbConfig.driver

  override def beforeEach() {
    wipeDb
  }

  private[this] def wipeDb = {
    import profile.api._

    Await.result(db.run(sqlu"TRUNCATE TABLE segments, ratings, users RESTART IDENTITY;"), Duration.Inf)
  }

}
