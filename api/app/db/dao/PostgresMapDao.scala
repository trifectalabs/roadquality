package db.dao

import javax.inject.{Inject, Singleton}

import com.vividsolutions.jts.geom.{ Geometry, LineString, Coordinate }
import com.trifectalabs.roadquality.v0.models.{ Point, MapRoute }
import com.trifectalabs.polyline.{ Polyline, LatLng }
import db.MyPostgresDriver
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult

import scala.concurrent.{ExecutionContext, Future}

@Singleton
class PostgresMapDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
  extends MapDao with HasDatabaseConfigProvider[MyPostgresDriver] {
  import profile.api._

  implicit val getRouteResult = GetResult(r => MapRoute(r.nextString(), r.nextDouble()))
  implicit val getPointResult = GetResult(r => Point(r.nextDouble(), r.nextDouble()))
  implicit val mapRouteResult = GetResult(r => MapRouteResult(r.nextInt(), r.nextGeometry(), r.nextDouble()))

  case class MapRouteResult(seq: Integer, geom: Geometry, distance: Double)
  case class MapPolyline(points: List[LatLng], distance: Double)

  val MAX_SEGMENT_LENGTH = 3000

  override def route(startPoint: Point, endPoint: Point): Future[MapRoute] = {
    val strSql = s"""SELECT seq, path, distance from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat});"""
    println(strSql)
    val sql = sql"""SELECT seq, path, distance from shortest_distance_route(${startPoint.lng}, ${startPoint.lat}, ${endPoint.lng}, ${endPoint.lat});""".as[MapRouteResult]
    db.run(sql).map { mapRouteResultList =>
      val sortedResultList: List[MapPolyline] = mapRouteResultList.toList
        .sortBy(m => m.seq)
        .map(d => MapPolyline(lineString2Pts(d.geom), d.distance))

      val startPointOnLine = closest(
        sortedResultList.head.points.map(l => new Coordinate(l.lng, l.lat)),
        new Coordinate(startPoint.lng, startPoint.lat)).getOrElse(new Coordinate(0,0))
      val endPointOnLine = closest(
        sortedResultList.last.points.map(l => new Coordinate(l.lng, l.lat)),
        new Coordinate(endPoint.lng, endPoint.lat)).getOrElse(new Coordinate(0,0))

      // Handle base case - routing on same edge
      val fixedPoints: List[MapPolyline] = if (sortedResultList.size == 1) {
        val edge = sortedResultList.head
        val alignedEdge = if (edge.points.indexWhere(_ == LatLng(startPointOnLine.y,startPointOnLine.x)) >
            edge.points.indexWhere(_ == LatLng(endPointOnLine.y,endPointOnLine.x))) { edge.copy(points = edge.points.reverse) } else edge
        alignedEdge.points.size match {
          case 2 => List(sortedResultList.head.copy(points = List(LatLng(startPoint.lat,startPoint.lng), LatLng(endPoint.lat, endPoint.lng))))
          case size => {
            val startTrimmed = alignedEdge.copy(points = alignedEdge.points
              .splitAt(alignedEdge.points.indexWhere(_ == LatLng(startPointOnLine.y,startPointOnLine.x)))._2
              .updated(0, LatLng(startPoint.lat, startPoint.lng)))
            val endTrimmed = startTrimmed.copy(points = startTrimmed.points.splitAt(startTrimmed.points.indexWhere(_ == LatLng(endPointOnLine.y,endPointOnLine.x)) + 1)._1)
            List(endTrimmed.copy(points = endTrimmed.points.updated(endTrimmed.points.size-1, LatLng(endPoint.lat, endPoint.lng))))
          }
        }
      } else {
        val fixedStart: List[MapPolyline] = {
            val ordered: MapPolyline = if (sortedResultList.head.points.head == sortedResultList(1).points.head
             || sortedResultList.head.points.head == sortedResultList(1).points.last) {
              sortedResultList.head.copy(points = sortedResultList.head.points.reverse)
            } else sortedResultList.head
            val updatedStart: MapPolyline = ordered.points.size match {
              case 2 => ordered.copy(points = List(LatLng(startPoint.lat, startPoint.lng), ordered.points.last))
              case size => ordered.copy(points = ordered.points
                .splitAt(ordered.points.indexWhere(_ == LatLng(startPointOnLine.y,startPointOnLine.x)))._2
                .updated(0, LatLng(startPoint.lat, startPoint.lng)))
            }
            updatedStart +: sortedResultList.tail
          }

        val fixedMiddle: List[MapPolyline] = fixedStart.tail.init.foldLeft((List[MapPolyline](fixedStart.head), false)) { (acc, edge) =>
          // Accumulator is the list of adjusted MapPolylines. Also has a 'stop' flag used to stop processing
          // edges if we hit the max segment length
          if (acc._1.map(_.distance).sum + edge.distance >= MAX_SEGMENT_LENGTH || acc._2 == true) {
            (acc._1, true)
          }
          else {
            (acc._1 :+ (if (acc._1.last.points.last != edge.points.head) { edge.copy(points = edge.points.reverse) } else edge), false)
          }
        }._1

        val fixedEnd: List[MapPolyline] = {
          if (fixedMiddle.last != fixedStart.init.last) { fixedMiddle }
          else {
            val pts = sortedResultList.last
            val ordered = if (fixedMiddle.last.points.last != pts.points.head) { pts.copy(points = pts.points.reverse) } else pts
            ordered.points.size match {
              case 1 => fixedMiddle :+ MapPolyline(List(LatLng(endPoint.lat, endPoint.lng)), 0)
              case 2 => fixedMiddle :+ MapPolyline(List(ordered.points.head, LatLng(endPoint.lat, endPoint.lng)), ordered.distance)
              case size => {
                val trimmed = ordered.copy(points = ordered.points.splitAt(ordered.points.indexWhere(_ == LatLng(endPointOnLine.y,endPointOnLine.x)) + 1)._1)
                fixedMiddle :+ trimmed.copy(points = trimmed.points.updated(trimmed.points.size-1, LatLng(endPoint.lat, endPoint.lng)))
              }
            }
          }
        }
        fixedEnd
      }

      val pl = Polyline.encode(fixedPoints.flatMap(_.points))
      val distance = fixedPoints.map(_.distance).sum
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
