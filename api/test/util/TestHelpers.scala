package util

import java.util.UUID

import com.trifectalabs.roadquality.v0.models._
import db.dao.SegmentsDao

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.language.postfixOps
import scala.util.Random

object TestHelpers {

  def populateTestSegments(count: Int = 1, segmentsDao: SegmentsDao): Future[Seq[Segment]] = {
    Future.sequence {
      createTestSegmentCreateForms(count).map { form =>
        val id = UUID.randomUUID()
        segmentsDao.create(id, form)
      }
    }
  }

  def createTestSegmentCreateForms(count: Int = 1): Seq[SegmentCreateForm] = {
    (1 to count) map { _ =>
      SegmentCreateForm(polyline = Random.alphanumeric take 10 mkString,
        surfaceRating = Random.nextInt(5) + 1,
        trafficRating = Random.nextInt(5) + 1,
        surface = SurfaceType("asphalt"),
        pathType = PathType("shared"))
    }
  }
  def createTestSegments(count: Int = 1): Seq[Segment] = {
    (1 to count) map { _ =>
      Segment(id = UUID.randomUUID(), polyline = Random.alphanumeric take 10 mkString)
    }
  }

}
