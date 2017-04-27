package controllers

import db.dao.{ SegmentsDao, RatingsDao }
import util.TestHelpers._
import com.trifectalabs.roadquality.v0.models.{ Point, SurfaceType, PathType }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{ Await, Future }
import scala.concurrent.duration.Duration

class InfoSpec extends BaseSpec {
    "/GET info" must {
      "return information about the service" in {
        whenReady(testClient.info.get()) { info =>
          info.name must be ("roadquality_api")
        }
      }
    }
}
