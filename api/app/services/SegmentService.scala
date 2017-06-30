package services

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.polyline.{LatLng, Polyline}
import com.trifectalabs.roadquality.v0.models.{Point, Segment, SegmentCreateForm, SegmentRating}
import com.vividsolutions.jts.geom.{ GeometryFactory, Coordinate, PrecisionModel, LineString }
import db.dao.{MapDao, MiniSegmentsDao, SegmentRatingsDao, SegmentsDao}
import models._
import util.Metrics
import org.joda.time.DateTime
import com.trifectalabs.roadquality.v0.models.{Segment, SegmentCreateForm, SegmentRating}
import scala.language.postfixOps
import scala.collection.JavaConversions._
import com.vividsolutions.jts.geom.Geometry
import play.api.Logger
import play.api.libs.ws._
import play.api.libs.json._
import play.api.Configuration

import scala.concurrent.{ExecutionContext, Future}
import com.trifectalabs.roadquality.v0.models.{ SegmentCreateForm, SegmentRating, Segment }
import db.dao.{ SegmentsDao, MapDao, SegmentRatingsDao }


trait SegmentService {
  def createSegment(segmentCreateForm: SegmentCreateForm, userId: UUID, currentZoomLevel: Option[Int] = None): Future[Segment]
  def handleEndpointOfSegment(miniSegmentSplit: MiniSegmentSplit, segmentId: UUID): Future[Option[MiniSegmentToSegment]]
  def newOverlappingMiniSegments(polyline: String, segmentId: UUID): Future[Seq[MiniSegmentToSegment]]
}

class SegmentServiceImpl @Inject()
  (segmentsDao: SegmentsDao, miniSegmentsDao: MiniSegmentsDao, mapDao: MapDao, ratingsDao: SegmentRatingsDao, wsClient: WSClient, configuration: Configuration)
  (implicit ec: ExecutionContext) extends SegmentService with Metrics {
  implicit def latLng2Point(latLng: LatLng): Point = Point(lat = latLng.lat, lng = latLng.lng)
  lazy val ratingsTileserverUrl = configuration.getString("ratings.tileserver.url").get

  def createSegment(segmentCreateForm: SegmentCreateForm, userId: UUID, currentZoomLevel: Option[Int]): Future[Segment] = {
    val segmentId = UUID.randomUUID()
    val polyline = joinPolylines(segmentCreateForm.polylines)
    val segmentPoints: Seq[Point] = Polyline.decode(polyline).map(latLng2Point)

    val startSplitsFutOpt: Future[Option[MiniSegmentSplit]] =
			miniSegmentsDao.miniSegmentSplitsFromPoint(segmentPoints.head, segmentPoints.tail.head)
    val endSplitsFutOpt: Future[Option[MiniSegmentSplit]] =
			miniSegmentsDao.miniSegmentSplitsFromPoint(segmentPoints.last, segmentPoints.init.last)
    val newOverlapMiniSegmentsFut = newOverlappingMiniSegments(polyline, segmentId)

    (for {
      startSplitsOpt <- startSplitsFutOpt
      endSplitsOpt <- endSplitsFutOpt
			existingMiniSegments <- newOverlapMiniSegmentsFut
      segment <- segmentsDao.create(segmentId, segmentCreateForm.name,
        segmentCreateForm.description, polyline, userId)
      } yield {
        val savedMiniSegments: Future[Seq[MiniSegmentToSegment]] = {
          (startSplitsOpt, endSplitsOpt) match {
            case (None, None) => Future(Nil)
            case (Some(start), None) => handleEndpointOfSegment(start, segmentId).map(p => (if (p.isEmpty) Nil else Seq(p.get)))
            case (None, Some(end)) => handleEndpointOfSegment(end, segmentId).map(p => (if (p.isEmpty) Nil else Seq(p.get)))
            case (Some(start), Some(end)) =>
              for {
                   start <- handleEndpointOfSegment(start, segmentId)
                   end <- handleEndpointOfSegment(end, segmentId)
              } yield {
                (if (start.isEmpty) Nil else Seq(start.get)) ++: (if (end.isEmpty) Nil else Seq(end.get))
              }
          }
        }

        // Any isn't good here, but we only care about the Future
        val miniSegmentsFuture: Future[Seq[Any]] = {
          savedMiniSegments.flatMap { previouslySavedMiniSegments =>
            Future.sequence(existingMiniSegments.map { existingMiniSegment =>
              if (!previouslySavedMiniSegments.map(s => s.miniSegmentId).contains(existingMiniSegment.miniSegmentId)) {
                (miniSegmentsDao.insert(existingMiniSegment))
              } else {
                Future(())
              }
            })
          }
        }

        val ratingsFuture: Future[Any] = {
          val minZoom = applyZoomLimits(currentZoomLevel.getOrElse(10) - 2)
          val maxZoom = applyZoomLimits(currentZoomLevel.getOrElse(10) + 2)
          for {
            rating <- ratingsDao.insert(
              SegmentRating(
                UUID.randomUUID(), segmentId, userId, segmentCreateForm.trafficRating, segmentCreateForm.surfaceRating,
                segmentCreateForm.surface, segmentCreateForm.pathType, DateTime.now(), DateTime.now()))
            extent <- ratingsDao.getBoundsFromRatings(rating.createdAt)
            // Run this portion synchronously after async reqs have fired
            syncTiles <- apiMetrics.timer("synchronous-tile-rerendering").timeFuture {
              (wsClient.url(s"$ratingsTileserverUrl/refresh").post {
                Json.toJson(extent).as[JsObject] +
                ("minzoom" -> Json.toJson(minZoom)) +
                ("maxzoom" -> Json.toJson(maxZoom))
              }) }
          } yield {
            val asyncLevels = ((10 to 17).toList) diff (minZoom to maxZoom)
            // Run this portion asynchronously
            apiMetrics.timer("background-tile-rerendering").timeFuture {
              val asyncLevelsTuple = asyncLevels.tail.foldLeft((List[Int](asyncLevels.head), List[Int]())) { case ((l1, l2), zoom) =>
                if (zoom - l1.last == 1) (l1 :+ zoom, l2)
                else if (!l2.isEmpty) (l1, l2 :+ zoom)
                else (l1, l2 :+ zoom)
              }
              val minZoomAsync1 = asyncLevelsTuple._1.head
              val maxZoomAsync1 = asyncLevelsTuple._1.last
              Future.sequence {
                Seq((wsClient
                  .url(s"$ratingsTileserverUrl/refresh")
                  .post {
                    Json.toJson(extent).as[JsObject] +
                    ("minzoom" -> Json.toJson(minZoomAsync1)) +
                    ("maxzoom" -> Json.toJson(maxZoomAsync1))
                  }
                  ),
                if (!asyncLevelsTuple._2.isEmpty) {
                  val minZoomAsync2 = asyncLevelsTuple._2.head
                  val maxZoomAsync2 = asyncLevelsTuple._2.last
                  (wsClient
                    .url(s"$ratingsTileserverUrl/refresh")
                    .post {
                      Json.toJson(extent).as[JsObject] +
                      ("minzoom" -> Json.toJson(minZoomAsync2)) +
                      ("maxzoom" -> Json.toJson(maxZoomAsync2))
                    }
                    )
                } else Future((): Unit)
                )
              }
            }
          }
        }
        Future.sequence(Seq(miniSegmentsFuture, ratingsFuture)).map( p => segment)
    }) flatMap identity
  }

  def newOverlappingMiniSegments(polyline: String, segmentId: UUID): Future[Seq[MiniSegmentToSegment]] = {
    mapDao.intersectionsSplitsFromSegment(polyline).flatMap { intersectionSplits =>
      Future.sequence {
        intersectionSplits.map { intersectionSplit =>
          miniSegmentsDao.overlappingMiniSegmentsFromPolyline(geomToPolyline(intersectionSplit)).map { existingMiniSegments =>
            existingMiniSegments match {
              case Nil => Seq(MiniSegmentToSegment(UUID.randomUUID(), intersectionSplit, segmentId))
              case Seq(existingMiniSegment) => Seq(existingMiniSegment.copy(segmentId = segmentId))
              case existingMiniSegments =>
                // This happens in situations where there are tiny intersections splits
                Logger.debug(s"Multiple mini segments found to be overlapping for intersection split. MiniSegmentIds: ${existingMiniSegments.map(s => s.miniSegmentId)}")
                existingMiniSegments.map(e => e.copy(segmentId = segmentId))
            }
          }
        }
      }
    } map (d => d.flatten)
  }

  def handleEndpointOfSegment(miniSegmentSplit: MiniSegmentSplit, segmentId: UUID): Future[Option[MiniSegmentToSegment]] = {
    if (miniSegmentSplit.firstLength >= 50.0 && miniSegmentSplit.secondLength >= 50.0) {
      val newMiniSegment = MiniSegmentToSegment(UUID.randomUUID(), miniSegmentSplit.first, segmentId)
			miniSegmentsDao.update(miniSegmentSplit.miniSegmentId, miniSegmentSplit.second)
      miniSegmentsDao.insert(newMiniSegment).map(p => Some(p))
    } else if (miniSegmentSplit.firstLength >= 50.0 && miniSegmentSplit.secondLength < 50.0) {
      val newMiniSegment = MiniSegmentToSegment(miniSegmentSplit.miniSegmentId, miniSegmentSplit.miniSegmentGeom, segmentId)
      miniSegmentsDao.insert(newMiniSegment).map(p => Some(p))
    } else if (miniSegmentSplit.firstLength < 50.0 && miniSegmentSplit.secondLength >= 50.0) {
      Future(None)
    } else {
      if (miniSegmentSplit.firstLength >= miniSegmentSplit.secondLength) {
        val newMiniSegment = MiniSegmentToSegment(miniSegmentSplit.miniSegmentId, miniSegmentSplit.miniSegmentGeom, segmentId)
        miniSegmentsDao.insert(newMiniSegment).map(p => Some(p))
      } else {
        Future(None)
      }
    }
  }

  def joinPolylines(polylines: Seq[String]): String = {
    Polyline.encode {
      polylines.foldLeft(List[LatLng]()) { (acc, polyline) =>
        acc ++ Polyline.decode(polyline)
      }
    }
  }

  private[this] def geomToPolyline(geom: Geometry): String = {
    Polyline.encode(geom.asInstanceOf[LineString].getCoordinates().toList.map(c => LatLng(c.y, c.x)))
  }

  private[this] def applyZoomLimits(zoomLevel: Int): Int = {
    zoomLevel match {
      case i if (i < 10) => 10
      case i if (i > 17) => 17
      case i => i
    }
  }

}
