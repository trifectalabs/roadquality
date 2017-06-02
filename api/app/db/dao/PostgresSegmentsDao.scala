package db.dao

import java.util.UUID
import javax.inject.{Inject, Singleton}

import com.trifectalabs.roadquality.v0.models._
import com.trifectalabs.polyline.{LatLng, Polyline}
import com.vividsolutions.jts.geom.Geometry
import db.MyPostgresDriver
import db.Tables._
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresSegmentsDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends SegmentsDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import _root_.db.TablesHelper._
  import profile.api._

  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))

  override def getAll: Future[Seq[Segment]] = {
    db.run(segments.result)
  }

  override def getById(id: UUID): Future[Segment] = {
    db.run(segments.filter(_.id === id).result.head)
  }

  override def getByBoundingBox(xmin: Double, ymin: Double, xmax: Double, ymax: Double): Future[Seq[Segment]] = {
   // @&& - intersection
   // Once the release of slick-pg 0.15.0 is out, we can use lineFromEncodedPolyline(s.polyline)
   //db.run(segments.filter(s => lineFromEncodedPolyline(s.polyline) @&& makeEnvelope(xmin, ymin, xmax, ymax, Some(4326))).result)
   db.run(segments.result)
  }

  override def delete(id: UUID): Future[Unit] = {
    db.run(segments.filter(_.id === id).delete.map(_ => ()))
  }

  override def create(id: UUID, segmentForm: SegmentCreateForm, userId: UUID): Future[Segment] = {
    val segment = Segment(
      id = id,
      name = segmentForm.name,
      description = segmentForm.description,
      polyline = segmentForm.polyline,
      createdBy = userId)

    db.run((segments += segment).map(_ => segment))
  }

  override def update(segment: Segment): Future[Segment] = {
    val query = for { s <- segments if s.id === segment.id } yield (s.name, s.description)
    db.run(query.update(segment.name, segment.description)).map(_ => segment)
  }

}
