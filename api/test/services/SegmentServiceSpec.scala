package services

import javax.inject.Inject
import java.util.UUID
import com.vividsolutions.jts.geom.{ Coordinate, LineString }
import com.trifectalabs.roadquality.v0.models._
import com.trifectalabs.polyline._

import models.MiniSegmentSplit
import db.dao.{ MiniSegmentsDao, SegmentsDao }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{ Await, Future }
import scala.concurrent.duration.Duration
import scala.util.Random

import test.BaseSpec
import util.TestHelpers._

class SegmentServiceSpec extends BaseSpec {
  lazy val segmentService = app.injector.instanceOf[SegmentService]
  lazy val segmentsDao = app.injector.instanceOf[SegmentsDao]
  lazy val miniSegmentsDao = app.injector.instanceOf[MiniSegmentsDao]

  "createSegment" must {
    "compute new MiniSegments successfully when no existing MiniSegments" in {
      val segForm = createTestSegmentCreateForms(1,
        Polyline.decode("eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB").map(l => Point(l.lat, l.lng))).head

      whenReady(segmentService.newOverlappingMiniSegments("eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB",
        testUserGuid)) { newMiniSegments =>
        newMiniSegments.size must be(3)
      }
    }

    "compute new MiniSegments successfully when there are existing MiniSegments" in {
      val segForm = createTestSegmentCreateForms(1,
        Polyline.decode("eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB").map(l => Point(l.lat, l.lng))).head
      val miniSegmentId1 = UUID.randomUUID()
      val miniSegmentId2 = UUID.randomUUID()
      val miniSegmentId3 = UUID.randomUUID()
      val newSegmentId = UUID.randomUUID()
      val segmentId = Await.result(populateTestSegments(segmentsDao = segmentsDao), Duration.Inf).head.id
      val miniSegment1 = Await.result(
        populateTestMiniSegment(miniSegmentId1, segmentId, "}tkhGhgpjNjJeHrCoB", miniSegmentsDao),
        Duration.Inf
      )
      val miniSegment2 = Await.result(
        populateTestMiniSegment(miniSegmentId2, segmentId, "eflhGjpqjNqCkK[o@?UDW`AqADClBeC", miniSegmentsDao),
        Duration.Inf
      )
      val miniSegment3 = Await.result(
        populateTestMiniSegment(miniSegmentId3, segmentId, "welhGdzpjNlHoIrBiCJG|@mAl@k@", miniSegmentsDao),
        Duration.Inf
      )

      whenReady(segmentService.newOverlappingMiniSegments("eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB",
        testUserGuid)) { newMiniSegments =>
        // Must have made 3 new segments (copies)
        newMiniSegments.size must be(3)
      }
    }

    "handle the case when there are no overlapping MiniSegments" in {
      val segForm = createTestSegmentCreateForms(1,
        Polyline.decode("eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB").map(l => Point(l.lat, l.lng))).head

      Await.result(segmentService.createSegment(segForm, testUserGuid), Duration.Inf)

      whenReady(miniSegmentsDao.getAll) { allMiniSegments =>
        allMiniSegments.size must be(3)
      }
      // TODO make sure we have a segment rating
    }

    "handle the case when there are overlapping MiniSegments" in {
      val segForm = createTestSegmentCreateForms(1,
        Polyline.decode("eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB").map(l => Point(l.lat, l.lng))).head

      val miniSegmentId1 = UUID.randomUUID()
      val miniSegmentId2 = UUID.randomUUID()
      val miniSegmentId3 = UUID.randomUUID()
      val newSegmentId = UUID.randomUUID()
      val segmentId = Await.result(populateTestSegments(segmentsDao = segmentsDao), Duration.Inf).head.id
      val miniSegment1 = Await.result(
        populateTestMiniSegment(miniSegmentId1, segmentId, "}tkhGhgpjNjJeHrCoB", miniSegmentsDao),
        Duration.Inf
      )
      val miniSegment2 = Await.result(
        populateTestMiniSegment(miniSegmentId2, segmentId, "eflhGjpqjNqCkK[o@?UDW`AqADClBeC", miniSegmentsDao),
        Duration.Inf
      )
      val miniSegment3 = Await.result(
        populateTestMiniSegment(miniSegmentId3, segmentId, "welhGdzpjNlHoIrBiCJG|@mAl@k@", miniSegmentsDao),
        Duration.Inf
      )

      Await.result(segmentService.createSegment(segForm, testUserGuid), Duration.Inf)

      // TODO make sure we have a segment rating
      whenReady(miniSegmentsDao.getAll) { allMiniSegments =>
        allMiniSegments.size must be(6)
        allMiniSegments.filter { s => s.miniSegmentId == miniSegmentId1 }.size must be (2)
        allMiniSegments.filter { s => s.miniSegmentId == miniSegmentId2 }.size must be (2)
        allMiniSegments.filter { s => s.miniSegmentId == miniSegmentId3 }.size must be (2)
      }
    }
  }

  "handleEndpointOfSegment" must {
    "handle the case when both splits are greater than 50m in length" in {
      val miniSegmentUUID = UUID.randomUUID()
      val newSegmentId = UUID.randomUUID()

      // Store a test segment
      val segmentId = Await.result(
        populateTestSegments(segmentsDao = segmentsDao),
        Duration.Inf
      ).head.id

      // Store a test minisegment
      val miniSegment = Await.result(
        populateTestMiniSegment(miniSegmentUUID, segmentId, "ozkhGjlvjNfEbNxC`GxPpJxJhF`Dn@vCGtAC", miniSegmentsDao),
        Duration.Inf
      )

      // Create test polyline
      val samplePolyline = Polyline.decode("ozkhGjlvjNfEbNxC`GxPpJ").map(l => Point(l.lat, l.lng))

      // Store the new segment
      val segForm = SegmentCreateForm(
        polyline = Polyline.encode(samplePolyline.map(a => LatLng(lat=a.lat, lng=a.lng)).toList),
        surfaceRating = Random.nextInt(5) + 1,
        trafficRating = Random.nextInt(5) + 1,
        surface = SurfaceType("asphalt"),
        pathType = PathType("shared"))
      val newSegment = Await.result(
        segmentsDao.create(newSegmentId, segForm, testUserGuid),
        Duration.Inf
      )

      // Fetch the test MiniSegment splits
      val endSplits: MiniSegmentSplit = Await.result(
        miniSegmentsDao.miniSegmentSplitsFromPoint(samplePolyline.last, samplePolyline.init.last),
        Duration.Inf
      ).get

      Await.result(segmentService.handleEndpointOfSegment(endSplits, newSegmentId), Duration.Inf)

      whenReady(miniSegmentsDao.getAll) { allMiniSegments =>
        // We should have two mini segments in the db now - one new, one updated
        allMiniSegments.size must be (2)
        allMiniSegments.filter { s => s.segmentId == newSegmentId }.size must be (1)
        allMiniSegments.filter { s => s.segmentId == segmentId }.size must be (1)
        val newMiniSegment = allMiniSegments.filter { s => s.segmentId == newSegmentId }.head
        val updatedMiniSegment = allMiniSegments.filter { s => s.segmentId == segmentId }.head
        // Both mini segments should be shorter than the original minisegment
        newMiniSegment.miniSegmentPolyline.getLength must be < miniSegment.miniSegmentPolyline.getLength
        updatedMiniSegment.miniSegmentPolyline.getLength must be < miniSegment.miniSegmentPolyline.getLength
      }
    }

    "handle the case when the first split length >= 50m, second split length < 50m" in {
      val miniSegmentUUID = UUID.randomUUID()
      val newSegmentId = UUID.randomUUID()

      // Store a test segment
      val segmentId = Await.result(
        populateTestSegments(segmentsDao = segmentsDao),
        Duration.Inf
      ).head.id

      // Store a test minisegment
      val miniSegment = Await.result(
        populateTestMiniSegment(miniSegmentUUID, segmentId, "ozkhGjlvjNfEbNxC`GxPpJxJhF`Dn@vCGtAC", miniSegmentsDao),
        Duration.Inf
      )

      // Create test polyline
      val samplePolyline = Polyline.decode("ozkhGjlvjNfEbNxC`GxPpJxJhF`Dn@vCG").map(l => Point(l.lat, l.lng))

      // Store the new segment
      val segForm = SegmentCreateForm(
        polyline = Polyline.encode(samplePolyline.map(a => LatLng(lat=a.lat, lng=a.lng)).toList),
        surfaceRating = Random.nextInt(5) + 1,
        trafficRating = Random.nextInt(5) + 1,
        surface = SurfaceType("asphalt"),
        pathType = PathType("shared"))
      val newSegment = Await.result(
        segmentsDao.create(newSegmentId, segForm, testUserGuid),
        Duration.Inf
      )

      val endSplits: MiniSegmentSplit = Await.result(
        miniSegmentsDao.miniSegmentSplitsFromPoint(samplePolyline.last, samplePolyline.init.last),
        Duration.Inf
      ).get

      Await.result(segmentService.handleEndpointOfSegment(endSplits, newSegmentId), Duration.Inf)

      whenReady(miniSegmentsDao.getAll) { allMiniSegments =>
        // We should have two mini segments in the db now - one new, one existing (not modified)
        // Both will have the same miniSegmentId and geometry, but different segment IDs
        allMiniSegments.size must be (2)
        allMiniSegments.filter { s => s.segmentId == segmentId }.size must be (1)
        allMiniSegments.filter { s => s.segmentId == newSegmentId }.size must be (1)
        allMiniSegments.filter { s => s.segmentId == newSegmentId }.head.miniSegmentPolyline must be
          (allMiniSegments.filter { s => s.segmentId == segmentId }.head.miniSegmentPolyline)
      }
    }

    "handle the case when the first split length < 50m, second split length >= 50m" in {
      val miniSegmentUUID = UUID.randomUUID()
      val newSegmentId = UUID.randomUUID()

      // Store a test segment
      val segmentId = Await.result(
        populateTestSegments(segmentsDao = segmentsDao),
        Duration.Inf
      ).head.id

      // Store a test minisegment
      val miniSegment = Await.result(
        populateTestMiniSegment(miniSegmentUUID, segmentId, "ozkhGjlvjNfEbNxC`GxPpJxJhF`Dn@vCGtAC", miniSegmentsDao),
        Duration.Inf
      )

      // Create test polyline
      val samplePolyline = Polyline.decode("ozkhGjlvjNf@`B").map(l => Point(l.lat, l.lng))

      // Store the new segment
      val segForm = SegmentCreateForm(
        polyline = Polyline.encode(samplePolyline.map(a => LatLng(lat=a.lat, lng=a.lng)).toList),
        surfaceRating = Random.nextInt(5) + 1,
        trafficRating = Random.nextInt(5) + 1,
        surface = SurfaceType("asphalt"),
        pathType = PathType("shared"))
      val newSegment = Await.result(
        segmentsDao.create(newSegmentId, segForm, testUserGuid),
        Duration.Inf
      )

      // Fetch the test MiniSegment splits
      val endSplits: MiniSegmentSplit = Await.result(
        miniSegmentsDao.miniSegmentSplitsFromPoint(samplePolyline.last, samplePolyline.init.last),
        Duration.Inf
      ).get

      Await.result(segmentService.handleEndpointOfSegment(endSplits, newSegmentId), Duration.Inf)

      whenReady(miniSegmentsDao.getAll) { allMiniSegments =>
        // We should have one mini segments in the db now - the existing, and should not be modified
        allMiniSegments.size must be (1)
        allMiniSegments.filter { s => s.segmentId == segmentId }.size must be (1)
        allMiniSegments.filter { s => s.segmentId == segmentId }.head must be (miniSegment)
      }
    }

    "handle the case when the first split length < 50m, second split length < 50m, first > second" in {
      val miniSegmentUUID = UUID.randomUUID()
      val newSegmentId = UUID.randomUUID()

      // Store a test segment
      val segmentId = Await.result(
        populateTestSegments(segmentsDao = segmentsDao),
        Duration.Inf
      ).head.id

      // Store a test minisegment
      val miniSegment = Await.result(
        populateTestMiniSegment(miniSegmentUUID, segmentId, "ywkhGfsvjNz@xC", miniSegmentsDao),
        Duration.Inf
      )

      // Create test polyline
      val samplePolyline = Polyline.decode("wwkhGpsvjN`@pA").map(l => Point(l.lat, l.lng))

      // Store the new segment
      val segForm = SegmentCreateForm(
        polyline = Polyline.encode(samplePolyline.map(a => LatLng(lat=a.lat, lng=a.lng)).toList),
        surfaceRating = Random.nextInt(5) + 1,
        trafficRating = Random.nextInt(5) + 1,
        surface = SurfaceType("asphalt"),
        pathType = PathType("shared"))
      val newSegment = Await.result(
        segmentsDao.create(newSegmentId, segForm, testUserGuid),
        Duration.Inf
      )

      // Fetch the test MiniSegment splits
      val endSplits: MiniSegmentSplit = Await.result(
        miniSegmentsDao.miniSegmentSplitsFromPoint(samplePolyline.last, samplePolyline.init.last),
        Duration.Inf
      ).get

      Await.result(segmentService.handleEndpointOfSegment(endSplits, newSegmentId), Duration.Inf)

      whenReady(miniSegmentsDao.getAll) { allMiniSegments =>
        // We should have two mini segments in the db now - one new, one existing (not modified)
        // Both will have the same miniSegmentId and geometry, but different segment IDs
        allMiniSegments.size must be (2)
        allMiniSegments.filter { s => s.segmentId == segmentId }.size must be (1)
        allMiniSegments.filter { s => s.segmentId == newSegmentId }.size must be (1)
        allMiniSegments.filter { s => s.segmentId == newSegmentId }.head.miniSegmentPolyline must be
          (allMiniSegments.filter { s => s.segmentId == segmentId }.head.miniSegmentPolyline)
      }
    }
  }
}
