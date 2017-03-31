package db

import java.util.UUID

import com.trifectalabs.road.quality.v0.models.{Point, Segment, Surface, PathType}
import com.vividsolutions.jts.geom.{Coordinate, GeometryFactory, Point => JTSPoint}

object Tables {
  import MyPostgresDriver.api._

  private val geometryFactory: GeometryFactory = new GeometryFactory()

  private[this] def pts2Point(jtsPoint: JTSPoint): Point = Point(jtsPoint.getX, jtsPoint.getY)
  private[this] def point2Pts(point: Point): JTSPoint = geometryFactory.createPoint(new Coordinate(point.lng, point.lat))

  implicit val SurfaceColumeType = MappedColumnType.base[Surface, String](
    { t => t.value.toString }, { s => Surface.apply(s) }
  )

  implicit val PathTypeColumeType = MappedColumnType.base[PathType, String](
    { t => t.value.toString }, { s => PathType.apply(s) }
  )


   private[this] def segmentTupled: ((UUID, Option[String], Option[String], JTSPoint, JTSPoint, String, Double, Double, Double, Surface, PathType)) => Segment = {
      case (id: UUID, name: Option[String], description: Option[String], start: JTSPoint, end: JTSPoint, polyline: String, overallRating: Double, surfaceRating: Double, trafficRating: Double, surface: Surface, pathType: PathType) =>
        Segment(id, name, description, pts2Point(start), pts2Point(end), polyline, overallRating, surfaceRating, trafficRating, surface, pathType)
    }
   private[this] def segmentUnapply(seg: Segment) = Some(seg.id, seg.name, seg.description, point2Pts(seg.start), point2Pts(seg.end), seg.polyline, seg.overallRating, seg.surfaceRating, seg.trafficRating, seg.surface, seg.pathType)

  class Segments(tag: Tag) extends Table[Segment](tag, "segments") {
    def id = column[UUID]("id", O.PrimaryKey)
    def name = column[Option[String]]("name")
    def description = column[Option[String]]("description")
    def startPoint = column[JTSPoint]("start_point")
    def endPoint = column[JTSPoint]("end_point")
    def polyline = column[String]("polyline")
    def overallRating = column[Double]("overall_rating")
    def surfaceRating = column[Double]("surface_rating")
    def trafficRating = column[Double]("traffic_rating")
    def surface = column[Surface]("surface")
    def pathType = column[PathType]("path_type")

    override def * = (id, name, description, startPoint, endPoint, polyline, overallRating, surfaceRating, trafficRating, surface, pathType) <> (segmentTupled, segmentUnapply)
  }

  val segments = TableQuery[Segments]

}
