package db

import java.util.UUID
import org.joda.time.DateTime
import java.sql.Timestamp
import com.trifectalabs.roadquality.v0.models._
import com.vividsolutions.jts.geom.{Coordinate, GeometryFactory, Point => JTSPoint}
import MyPostgresDriver.api._
import slick.jdbc.SetParameter
import slick.jdbc.PositionedParameters

object TablesHelper {

  implicit val SurfaceColumnType = MappedColumnType.base[SurfaceType, String](
    { t => t.toString }, { s => SurfaceType.apply(s) }
  )

  implicit val PathTypeColumnType = MappedColumnType.base[PathType, String](
    { t => t.toString }, { s => PathType.apply(s) }
  )

  implicit val UserRoleColumnType = MappedColumnType.base[UserRole, String](
    { t => t.toString }, { s => UserRole.apply(s) }
  )

  private[this] val geometryFactory: GeometryFactory = new GeometryFactory()
}
