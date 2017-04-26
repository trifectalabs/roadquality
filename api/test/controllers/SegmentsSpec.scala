package controllers

import db.dao.SegmentsDao
import scala.concurrent.ExecutionContext.Implicits.global
import util.TestHelpers._

class SegmentsSpec extends BaseSpec {

  val segmentsDao = app.injector.instanceOf[SegmentsDao]

    "/GET segments" must {
      "return a list of all segments" in {
        populateTestSegments(count = 3, segmentsDao = segmentsDao)

        whenReady(testClient.segments.get()) { segments =>
          segments.size must be(3)
        }
      }
    }
}
