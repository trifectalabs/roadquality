package controllers

import db.dao.SegmentsDao
import scala.concurrent.ExecutionContext.Implicits.global
import util.TestHelpers._
import scala.concurrent.Await
import scala.concurrent.duration.Duration

class SegmentsSpec extends BaseSpec {

  val segmentsDao = app.injector.instanceOf[SegmentsDao]

    "/GET segments" must {
      "return a list of all segments" in {
        Await.result(
          populateTestSegments(count = 3, segmentsDao = segmentsDao),
          Duration.Inf
        )

        whenReady(testClient.segments.get()) { segments =>
          segments.size must be(3)
        }
      }
    }

    "/GET segments(id)" must {
      "return a single segment with matching id" in {
        val id = Await.result(
          populateTestSegments(count = 3, segmentsDao = segmentsDao),
          Duration.Inf
        ).head.id

        whenReady(testClient.segments.get(Some(id))) { segments =>
          segments.size must be(1)
          segments.head.id must be(id)
        }
      }
    }

}
