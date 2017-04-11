package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}

import com.trifectalabs.roadquality.v0.models._
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresSegmentsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends SegmentsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import driver.api._

  override def getAll: Future[Seq[Segment]] = {
    db.run(segments.result)
  }

  override def getById(id: UUID): Future[Segment] = {
    db.run(segments.filter(_.id === id).result.head)
  }

  override def getByBoundingBox(xmin: Double, ymin: Double, xmax: Double, ymax: Double): Future[Seq[Segment]] = {
   // @&& - intersection
   db.run(segments.filter(_.startPoint @&& makeEnvelope(xmin, ymin, xmax, ymax, Some(4326))).result)
  }

  override def delete(id: UUID): Future[Unit] = {
    db.run(segments.filter(_.id === id).delete.map(_ => ()))
  }

  override def create(segmentForm: SegmentCreateForm): Future[Segment] = {
    val polyline = Polyline.encode(segmentForm.points.map { point =>
      LatLng(lat = point.lat, lng = point.lng)
    }.toList)

    val id = UUID.randomUUID()
    val segment = Segment(
      id = UUID.randomUUID(),
      name = segmentForm.name,
      description = segmentForm.description,
      start = segmentForm.points.head,
      end = segmentForm.points.last,
      polyline = polyline,
      overallRating = (segmentForm.surfaceRating + segmentForm.trafficRating)/2,
      surfaceRating = segmentForm.surfaceRating,
      trafficRating = segmentForm.trafficRating,
      surface = segmentForm.surface,
      pathType = segmentForm.pathType)

    db.run((segments += segment).map(_ => segment))
  }

  override def update(segment: Segment): Future[Segment] = {
    val query = for { s <- segments if s.id === segment.id } yield (s.name, s.description, s.surfaceRating, s.trafficRating, s.surface, s.pathType)
    db.run(query.update(segment.name, segment.description, segment.surfaceRating, segment.trafficRating, segment.surface, segment.pathType)).map(_ => segment)
  }

}
