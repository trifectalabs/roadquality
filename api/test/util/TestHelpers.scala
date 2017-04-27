package util

import java.util.UUID

import com.trifectalabs.roadquality.v0.models._
import db.dao.SegmentsDao
import com.trifectalabs.polyline.{ Polyline, LatLng }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.language.postfixOps
import scala.util.Random

object TestHelpers {

  def populateTestSegments(count: Int = 1, points: Seq[Point] = Seq(), segmentsDao: SegmentsDao): Future[Seq[Segment]] = {
    Future.sequence {
      createTestSegmentCreateForms(count, points).map { form =>
        val id = UUID.randomUUID()
        segmentsDao.create(id, form)
      }
    }
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

  def createTestSegmentUpdateForms(count: Int = 1,
    surfaceRating: Option[Int] = None,
    trafficRating: Option[Int] = None,
    surface: Option[SurfaceType] = None,
    pathType: Option[PathType] = None): Seq[SegmentUpdateForm] = {
    (1 to count) map { _ =>
      SegmentUpdateForm(
        name = Some(Random.alphanumeric take 10 mkString),
        description = Some(Random.alphanumeric take 10 mkString),
        surfaceRating = surfaceRating,
        trafficRating = trafficRating,
        surface = surface,
        pathType = pathType)
    }
  }

  def createTestSegments(count: Int = 1): Seq[Segment] = {
    (1 to count) map { _ =>
      Segment(id = UUID.randomUUID(), polyline = Random.alphanumeric take 10 mkString)
    }
  }

  private[this] def randomPolylineGenerator: String = {
    val points = (1 to Random.nextInt(10)) map { _ =>
      LatLng((Random.nextDouble() * 360) - 180, (Random.nextDouble() * 360) - 180)
    } toList

    Polyline.encode(points)
  }

}
