package db.dao

import javax.inject.{Inject, Singleton}

import com.vividsolutions.jts.geom.{ Geometry, LineString, Coordinate }
import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult
import models.Exceptions._

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresMapDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends MapDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import profile.api._

  implicit val getRouteResult = GetResult(r => MapRoute(r.nextString(), r.nextDouble()))
  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))
  implicit val mapRouteResult = GetResult(r => MapRouteResult(r.nextInt(), r.nextGeometry(), r.nextDouble()))

  case class MapRouteResult(seq: Integer, geom: Geometry, distance: Double)

  override def route(startPoint: Point, endPoint: Point): Future[MapRoute] = {
    val BOUNDING_BOX_RADIUS = 3000 // Number of meters to include the routing ways in the query

    val strSql = s"""SELECT seq, path, distance from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat}, ${BOUNDING_BOX_RADIUS});"""
    println(strSql)
    val sql = sql"""SELECT seq, path, distance from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat}, ${BOUNDING_BOX_RADIUS});""".as[MapRouteResult]
    db.run(sql).map { mapRouteResultList =>
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
    val sql = sql"""SELECT * from closest_point_on_road(${point.lng}, ${point.lat});""".as[Point]
    db.run(sql).map(r => r.head)
  }

  override def intersectionsSplitsFromSegment(segment_polyline: String): Future[Seq[Geometry]] = {
    val sql = sql"""
      WITH
        polyline      AS (SELECT ST_LineFromEncodedPolyline(${segment_polyline})),
        intersections AS (SELECT the_geom as intersection FROM ways_vertices_pgr
          WHERE ST_DWithin(the_geom, (SELECT * FROM polyline), 5, false))
      SELECT (st_dump(
        st_split(
          st_snap(
            (SELECT * FROM polyline),
            (SELECT st_collect(array_agg(intersection::geometry)) FROM intersections),
            0.00008
          ),
          (SELECT st_collect(array_agg(intersection::geometry)) FROM intersections)
        )
      )).geom;
    """.as[Geometry]
    db.run(sql)
  }

  private[this] def lineString2Pts(geom: Geometry): List[LatLng] =
    geom.asInstanceOf[LineString].getCoordinates().toList.map(c => LatLng(c.y, c.x))
  private[this] def closest(xs: List[Coordinate], point: Coordinate): Option[Coordinate] = xs match {
    case Nil => None
    case List(x: Coordinate) => Some(x)
    case x :: y :: rest => closest( (if (x.distance(point) < y.distance(point)) x else y) :: rest, point )
  }

}
