package db

import java.util.UUID
import org.joda.time.DateTime

import com.trifectalabs.road.quality.v0.models._
import com.vividsolutions.jts.geom.{Coordinate, GeometryFactory, Point => JTSPoint}

object Tables {
  import MyPostgresDriver.api._
  import TablesHelper._

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

class Users(tag: Tag) extends Table[User](tag, "users") {
    def id = column[UUID]("id", O.PrimaryKey)
    def firstName = column[String]("first_name")
    def lastName = column[String]("last_name")
    def email = column[String]("email")
    def birthdate = column[Option[DateTime]]("birthdate")
    def sex = column[Option[String]]("sex")
    def role = column[UserRole]("role")
    def stravaToken = column[String]("strava_token")
    def createdAt = column[DateTime]("created_at")
    def updatedAt = column[DateTime]("updated_at")
    def deletedAt = column[Option[DateTime]]("deleted_at")

    override def * = (id, firstName, lastName, email, birthdate, sex, role, stravaToken, createdAt, updatedAt, deletedAt) <> (User.tupled, User.unapply)
  }

  val users = TableQuery[Users]

}
