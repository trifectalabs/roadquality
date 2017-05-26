package util

import java.util.UUID

import com.vividsolutions.jts.geom.{ GeometryFactory, Coordinate, PrecisionModel }
import com.trifectalabs.roadquality.v0.models._
import db.dao.{ SegmentsDao, MiniSegmentsDao }
import models.MiniSegmentToSegment
import com.trifectalabs.polyline.{ Polyline, LatLng }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.language.postfixOps
import scala.util.Random

object TestHelpers {

  val testUserGuid = UUID.fromString("e34f4f39-edcb-4d65-9969-264db37681eb")
  val gf = new GeometryFactory(new PrecisionModel(), 4326)

  def populateTestSegments(count: Int = 1, points: Seq[Point] = Seq(), segmentsDao: SegmentsDao): Future[Seq[Segment]] = {
    Future.sequence {
      createTestSegmentCreateForms(count, points).map { form =>
        val id = UUID.randomUUID()
        segmentsDao.create(id, form, testUserGuid)
      }
    }
  }

  def populateTestMiniSegment(uuid: UUID, segmentId: UUID, polyline: String, miniSegmentsDao: MiniSegmentsDao): Future[MiniSegmentToSegment] = {
    val points = Polyline.decode(polyline).toArray.map(p => new Coordinate(p.lng, p.lat))
    val geom = gf.createLineString(points)
    val ms = MiniSegmentToSegment(uuid, geom, segmentId)
    miniSegmentsDao.insert(ms)
  }

  def createTestSegmentCreateForms(count: Int = 1, points: Seq[Point] = Seq()): Seq[SegmentCreateForm] = {
    (1 to count) map { _ =>
      SegmentCreateForm(
        polyline = points match {
          case Nil => randomPolylineGenerator
          case p => Polyline.encode(p.map(a => LatLng(lat=a.lat, lng=a.lng)).toList)
        },
        surfaceRating = Random.nextInt(5) + 1,
        trafficRating = Random.nextInt(5) + 1,
        surface = SurfaceType("asphalt"),
        pathType = PathType("shared"))
    }
  }
  def createTestSegments(count: Int = 1): Seq[Segment] = {
    (1 to count) map { _ =>
      //Segment(id = UUID.randomUUID(), polyline = Random.alphanumeric take 10 mkString, createdBy = testUserGuid)
      Segment(id = UUID.randomUUID(), polyline = "eflhGjpqjNqCkK[o@?UDW`AqADClBeClHoIrBiCJG|@mAl@k@jJeHrCoB", createdBy = testUserGuid)
    }
  }

  private[this] def randomPolylineGenerator: String = {
    val points = (1 to Random.nextInt(10)) map { _ =>
      LatLng((Random.nextDouble() * 360) - 180, (Random.nextDouble() * 360) - 180)
    } toList

    Polyline.encode(points)
  }

}
