package db

import java.util.UUID
import com.trifectalabs.road.quality.v0.models._
import com.vividsolutions.jts.geom.{Coordinate, GeometryFactory, Point => JTSPoint}
import MyPostgresDriver.api._

object TablesHelper {

  implicit val SurfaceColumeType = MappedColumnType.base[Surface, String](
    { t => t.value.toString }, { s => Surface.apply(s) }
  )

  implicit val PathTypeColumeType = MappedColumnType.base[PathType, String](
    { t => t.value.toString }, { s => PathType.apply(s) }
  )

  implicit val UserRoleColumeType = MappedColumnType.base[UserRole, String](
    { t => t.value.toString }, { s => UserRole.apply(s) }
  )


  private[this] val geometryFactory: GeometryFactory = new GeometryFactory()

  private[db] def pts2Point(jtsPoint: JTSPoint): Point = Point(jtsPoint.getX, jtsPoint.getY)
  private[db] def point2Pts(point: Point): JTSPoint = geometryFactory.createPoint(new Coordinate(point.lng, point.lat))




   private[db] def segmentTupled: ((UUID, Option[String], Option[String], JTSPoint, JTSPoint, String, Double, Surface, PathType)) => Segment = {
      case (id: UUID, name: Option[String], description: Option[String], start: JTSPoint, end: JTSPoint, polyline: String, rating: Double, surface: Surface, pathType: PathType) =>
        Segment(id, name, description, pts2Point(start), pts2Point(end), polyline, rating, surface, pathType)
    }
   private[db] def segmentUnapply(seg: Segment) = Some(seg.id, seg.name, seg.description, point2Pts(seg.start), point2Pts(seg.end), seg.polyline, seg.rating, seg.surface, seg.pathType)


}
