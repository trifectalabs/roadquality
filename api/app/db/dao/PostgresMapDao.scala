package db.dao
import javax.inject.{Inject, Singleton}
import com.vividsolutions.jts.geom.{ Geometry, LineString, Coordinate }
import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult
import models.Exceptions._
import util.Metrics

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresMapDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends MapDao with HasDatabaseConfigProvider[MyPostgresDriver] with Metrics {
  import profile.api._

  implicit val getRouteResult = GetResult(r => MapRoute(r.nextString(), r.nextDouble()))
  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))
  implicit val mapRouteResult = GetResult(r => MapRouteResult(r.nextInt(), r.nextGeometry(), r.nextDouble()))

  case class MapRouteResult(seq: Integer, geom: Geometry, distance: Double)

  override def route(startPoint: Point, endPoint: Point): Future[MapRoute] = {
    val BOUNDING_BOX_RADIUS = 3000 // Number of meters to include the routing ways in the query
    val NEARBY_WAY_LIMIT = 30000 // Number of ways to include in query for routing

    val sql = sql"""SELECT seq, path, distance from shortest_distance_route(${startPoint.lng}, ${startPoint.lat},
      ${endPoint.lng}, ${endPoint.lat}, ${BOUNDING_BOX_RADIUS}, ${NEARBY_WAY_LIMIT});""".as[MapRouteResult]
    dbMetrics.timer("route").timeFuture { db.run(sql) }.map { mapRouteResultList =>
      if (mapRouteResultList.size == 0)
        throw new NoRouteFoundException
      val sortedResultList: List[List[LatLng]] = mapRouteResultList.toList.sortBy(m => m.seq).map(d => lineString2Pts(d.geom))

      val startPointOnLine = closest(
        sortedResultList.head.map(l => new Coordinate(l.lng, l.lat)),
        new Coordinate(startPoint.lng, startPoint.lat)).getOrElse(new Coordinate(0,0))
      val endPointOnLine = closest(
        sortedResultList.last.map(l => new Coordinate(l.lng, l.lat)),
        new Coordinate(endPoint.lng, endPoint.lat)).getOrElse(new Coordinate(0,0))

      // Handle base case - routing on same edge
      val fixedPoints = if (sortedResultList.size == 1) {
        val edge = sortedResultList.head
        val alignedEdge = if (edge.indexWhere(_ == LatLng(startPointOnLine.y,startPointOnLine.x)) >
            edge.indexWhere(_ == LatLng(endPointOnLine.y,endPointOnLine.x))) { edge.reverse } else edge
        alignedEdge.size match {
          case 2 => List(LatLng(startPoint.lat,startPoint.lng), LatLng(endPoint.lat, endPoint.lng))
          case size => {
            val startTrimmed = alignedEdge
              .splitAt(alignedEdge.indexWhere(_ == LatLng(startPointOnLine.y,startPointOnLine.x)))._2
              .updated(0, LatLng(startPoint.lat, startPoint.lng))
            val endTrimmed = startTrimmed.splitAt(startTrimmed.indexWhere(_ == LatLng(endPointOnLine.y,endPointOnLine.x)) + 1)._1
            endTrimmed.updated(endTrimmed.size-1, LatLng(endPoint.lat, endPoint.lng))
          }
        }
      } else {
        val fixedStart: List[List[LatLng]] = {
            val ordered = if (sortedResultList.head.head == sortedResultList(1).head
             || sortedResultList.head.head == sortedResultList(1).last) {
              sortedResultList.head.reverse
            } else sortedResultList.head
            val updatedStart = ordered.size match {
              case 2 => List(LatLng(startPoint.lat, startPoint.lng), ordered.last)
              case size => ordered
                .splitAt(ordered.indexWhere(_ == LatLng(startPointOnLine.y,startPointOnLine.x)))._2
                .updated(0, LatLng(startPoint.lat, startPoint.lng))
            }
            updatedStart +: sortedResultList.tail
          }

        val fixedMiddle: List[List[LatLng]] = fixedStart.tail.init.foldLeft(List[List[LatLng]](fixedStart.head)) { (acc, edge) =>
          acc :+ (if (acc.last.last != edge.head) { edge.reverse } else edge)
        }
        val fixedEnd: List[List[LatLng]] = {
          val pts = sortedResultList.last
          val ordered = if (fixedMiddle.last.last != pts.head) { pts.reverse } else pts
          ordered.size match {
            case 1 => fixedMiddle :+ List(LatLng(endPoint.lat, endPoint.lng))
            case 2 => fixedMiddle :+ List(ordered.head, LatLng(endPoint.lat, endPoint.lng))
            case size => {
              val trimmed = ordered.splitAt(ordered.indexWhere(_ == LatLng(endPointOnLine.y,endPointOnLine.x)) + 1)._1
              fixedMiddle :+ trimmed.updated(trimmed.size-1, LatLng(endPoint.lat, endPoint.lng))
            }
          }
        }
        fixedEnd.flatten
      }

      val pl = Polyline.encode(fixedPoints)
      val distance = mapRouteResultList.toList.map(_.distance).sum
      MapRoute(pl, distance)
    }
  }

  override def snapPoint(point: Point): Future[Point] = {
    val BOUNDING_BOX_RADIUS = 1000 // Distance to snap to nearest road within (meters)
    val sql = sql"""SELECT * from closest_point_on_road(${point.lng}, ${point.lat}, ${BOUNDING_BOX_RADIUS});""".as[Point]
    dbMetrics.timer("snapPoint").timeFuture { db.run(sql) }.map { r =>
      // This is stupid. It should be an empty list, but its a list with 1 element with lat/lng = 0,0
      if (r.head.lat == 0 && r.head.lng == 0)
        throw new NoSnapFoundException
      else
        r.head
    }
  }

  override def intersectionsSplitsFromSegment(segment_polyline: String): Future[Seq[Geometry]] = {
		// Segment snap buffer = 0.00008
		// Nearby vertices limit = 10000
    val sql = sql"""SELECT * FROM intersection_splits_from_segment(${segment_polyline}, 0.00008, 10000)""".as[Geometry]
    dbMetrics.timer("intersectionSplitsFromSegment").timeFuture { db.run(sql) }
  }

  private[this] def lineString2Pts(geom: Geometry): List[LatLng] =
    geom.asInstanceOf[LineString].getCoordinates().toList.map(c => LatLng(c.y, c.x))
  private[this] def closest(xs: List[Coordinate], point: Coordinate): Option[Coordinate] = xs match {
    case Nil => None
    case List(x: Coordinate) => Some(x)
    case x :: y :: rest => closest( (if (x.distance(point) < y.distance(point)) x else y) :: rest, point )
  }

}
