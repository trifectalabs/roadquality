package controllers

import db.dao.{ SegmentsDao, RatingsDao }
import util.TestHelpers._
import com.trifectalabs.roadquality.v0.models.Point

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{ Await, Future }
import scala.concurrent.duration.Duration

class SegmentsSpec extends BaseSpec {

  val segmentsDao = app.injector.instanceOf[SegmentsDao]
  val ratingsDao = app.injector.instanceOf[RatingsDao]

    "/GET segments" must {
      "return a list of all segments" in {
        Await.result(
          populateTestSegments(count = 3, segmentsDao = segmentsDao),
          Duration.Inf
        )

        whenReady(testClient.segments.get()) { segments =>
          segments.size must be (3)
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
          segments.size must be (1)
          segments.head.id must be (id)
        }
      }
    }

    "/GET segments/boundingbox" must {
      "return segments whose polyline intersects the corresponding bounding box" in {
        // Waterloo region
        val xmin = Some(-80.648790)
        val ymin = Some(43.503148)
        val xmax = Some(-80.399167)
        val ymax = Some(43.442304)
        val waterlooPoints = Seq( Point(43.464150, -80.549123), Point(43.465886, -80.550400) )

        Await.result(
          populateTestSegments(count = 1, points = waterlooPoints, segmentsDao = segmentsDao),
          Duration.Inf
        ).head.id

        whenReady(
          testClient.segments.getBoundingbox(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax)
        ) { segments =>
          segments.size must be (1)
        }
      }
    }

    "/POST segments" must {
      "create a new segment based off a segment create form" in {
        val forms = createTestSegmentCreateForms(count = 3)

        whenReady(
          Future.sequence(forms.map(f => testClient.segments.post(f)))
        ) { segments =>
          segments.size must be (3)
        }
      }

      "create ratings for the underlying ways" in {
        val waterlooPoints = Seq( Point(43.464150, -80.549123), Point(43.465886, -80.550400) )
        val forms = createTestSegmentCreateForms(count = 3, points = waterlooPoints)

        Await.result(
          Future.sequence(forms.map(f => testClient.segments.post(f))),
          Duration.Inf
        )

        // Wait for asynchronous rating generation to complete
        Await.result(
          Future.successful(Thread.sleep(1000)),
          Duration.Inf
        )

        whenReady(
          ratingsDao.getAll()
        ) { ratings =>
          ratings.size must be > 3
        }
      }
    }
}
