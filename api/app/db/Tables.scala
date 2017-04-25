package db

import java.util.UUID
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models._
import com.vividsolutions.jts.geom.{Coordinate, GeometryFactory, Point => JTSPoint}

object Tables {
  import MyPostgresDriver.api._
  import TablesHelper._

  class Segments(tag: Tag) extends Table[Segment](tag, "segments") {
    def id = column[UUID]("id", O.PrimaryKey)
    def name = column[Option[String]]("name")
    def description = column[Option[String]]("description")
    def polyline = column[String]("polyline")

    override def * = (id, name, description, polyline) <> (Segment.tupled, Segment.unapply)
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

  class Ratings(tag: Tag) extends Table[Rating](tag, "ratings") {
    def wayId = column[Long]("way_id")
    def segmentId = column[UUID]("segment_id")
    def userId = column[UUID]("user_id")
    def trafficRating  = column[Int]("traffic_rating")
    def surfaceRating  = column[Int]("surface_rating")
    def surface = column[SurfaceType]("surface")
    def pathType = column[PathType]("path_type")
    def createdAt = column[DateTime]("created_at")
    def updatedAt = column[DateTime]("updated_at")
    def deletedAt = column[Option[DateTime]]("deleted_at")

    override def * = (wayId, segmentId, userId, trafficRating, surfaceRating, surface, pathType, createdAt, updatedAt, deletedAt) <> (Rating.tupled, Rating.unapply)
  }

  val ratings = TableQuery[Ratings]

}
