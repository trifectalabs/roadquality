package db

import java.util.UUID

import com.trifectalabs.road.quality.v0.models.{Point, Segment}
import com.vividsolutions.jts.geom.{Coordinate, GeometryFactory, Point => JTSPoint}

object Tables {
  import MyPostgresDriver.api._

  private val geometryFactory: GeometryFactory = new GeometryFactory()

  private[this] def pts2Point(jtsPoint: JTSPoint): Point = Point(jtsPoint.getX, jtsPoint.getY)
  private[this] def point2Pts(point: Point): JTSPoint = geometryFactory.createPoint(new Coordinate(point.lng, point.lat))


   private[this] def segmentTupled: ((UUID, Option[String], Option[String], JTSPoint, JTSPoint, String, Double)) => Segment = {
      case (id: UUID, name: Option[String], description: Option[String], start: JTSPoint, end: JTSPoint, polyline: String, rating: Double) =>
        Segment(id, name, description, pts2Point(start), pts2Point(end), polyline, rating)
    }
   private[this] def segmentUnapply(seg: Segment) = Some(seg.id, seg.name, seg.description, point2Pts(seg.start), point2Pts(seg.end), seg.polyline, seg.rating)

  class Segments(tag: Tag) extends Table[Segment](tag, "segments") {
    def id = column[UUID]("id", O.PrimaryKey)
    def name = column[Option[String]]("name")
    def description = column[Option[String]]("description")
    def startPoint = column[JTSPoint]("start_point")
    def endPoint = column[JTSPoint]("end_point")
    def polyline = column[String]("polyline")
    def rating = column[Double]("rating")

    override def * = (id, name, description, startPoint, endPoint, polyline, rating) <> (segmentTupled, segmentUnapply)
  }

  val segments = TableQuery[Segments]

}
