package db

import java.util.UUID

import models.TileCacheExpiration
import com.trifectalabs.roadquality.v0.models._
import models.{MiniSegment, MiniSegmentToSegment}
import org.joda.time.DateTime
import com.vividsolutions.jts.geom.Geometry

object Tables {
  import MyPostgresDriver.api._
  import TablesHelper._

  class Segments(tag: Tag) extends Table[Segment](tag, "segments") {
    def id = column[UUID]("id", O.PrimaryKey)
    def name = column[Option[String]]("name")
    def description = column[Option[String]]("description")
    def polyline = column[String]("polyline")
    def createdBy = column[UUID]("created_by")

    override def * = (id, name, description, polyline, createdBy) <> (Segment.tupled, Segment.unapply)
  }

  val segments = TableQuery[Segments]

class Users(tag: Tag) extends Table[User](tag, "users") {
    def id = column[UUID]("id", O.PrimaryKey)
    def firstName = column[String]("first_name")
    def lastName = column[String]("last_name")
    def email = column[String]("email")
    def city = column[String]("city")
    def province = column[String]("province")
    def country = column[String]("country")
    def birthdate = column[Option[DateTime]]("birthdate")
    def sex = column[Option[String]]("sex")
    def role = column[UserRole]("role")
    def stravaToken = column[String]("strava_token")
    def createdAt = column[DateTime]("created_at")
    def updatedAt = column[DateTime]("updated_at")
    def deletedAt = column[Option[DateTime]]("deleted_at")

    override def * = (id, firstName, lastName, email, city, province, country, birthdate, sex, role, stravaToken, createdAt, updatedAt, deletedAt) <> (User.tupled, User.unapply)
  }

  val users = TableQuery[Users]

  class SegmentRatings(tag: Tag) extends Table[SegmentRating](tag, "segment_ratings") {
    def id = column[UUID]("id")
    def segmentId = column[UUID]("segment_id")
    def userId = column[UUID]("user_id")
    def trafficRating  = column[Int]("traffic_rating")
    def surfaceRating  = column[Int]("surface_rating")
    def surface = column[SurfaceType]("surface")
    def pathType = column[PathType]("path_type")
    def createdAt = column[DateTime]("created_at")
    def updatedAt = column[DateTime]("updated_at")
    def deletedAt = column[Option[DateTime]]("deleted_at")

    override def * = (id, segmentId, userId, trafficRating, surfaceRating, surface, pathType, createdAt, updatedAt, deletedAt) <> (SegmentRating.tupled, SegmentRating.unapply)
  }

  val segmentRatings = TableQuery[SegmentRatings]


  class MiniSegments(tag: Tag) extends Table[MiniSegment](tag, "mini_segments") {
    def id = column[UUID]("id")
    def trafficRating  = column[Double]("traffic_rating")
    def surfaceRating  = column[Double]("surface_rating")
    def surface = column[SurfaceType]("surface")
    def pathType = column[PathType]("path_type")
    def polyline = column[String]("polyline")

    override def * = (id, trafficRating, surfaceRating, surface, pathType, polyline) <> (MiniSegment.tupled, MiniSegment.unapply)
  }

  val miniSegments = TableQuery[MiniSegments]

  class MiniSegmentsToSegments(tag: Tag) extends Table[MiniSegmentToSegment](tag, "mini_segments_to_segments") {
    def miniSegmentId = column[UUID]("mini_segment_id")
    def miniSegmentPolyline = column[Geometry]("mini_segment_polyline")
    def segmentId = column[UUID]("segment_id")

    override def * = (miniSegmentId, miniSegmentPolyline, segmentId) <> (MiniSegmentToSegment.tupled, MiniSegmentToSegment.unapply)
  }

  val miniSegmentsToSegments = TableQuery[MiniSegmentsToSegments]

  class TileCacheExpirations(tag: Tag) extends Table[TileCacheExpiration](tag, "tile_cache_expirations") {
    def bounds = column[String]("bounds")
    def createdAt = column[DateTime]("created_at")
    def processedAt = column[Option[DateTime]]("processed_at")

    override def * = (bounds, createdAt, processedAt) <> (TileCacheExpiration.tupled, TileCacheExpiration.unapply)
  }

  val tileCacheExpirations = TableQuery[TileCacheExpirations]

}
