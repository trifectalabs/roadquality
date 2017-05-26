package controllers

import test.BaseSpec
import db.dao.{ MapDao }
import util.TestHelpers._
import com.trifectalabs.roadquality.v0.models.{ Point, SurfaceType, PathType }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{ Await, Future }
import scala.concurrent.duration.Duration

class MapRoutesSpec extends BaseSpec {

  "/GET mapRoutes" must {
    "return a polyline of a route between two points" in {
      val startPoint = Point(43.472263, -80.611827)
      val endPoint = Point(43.474543, -80.600169)
      whenReady(
        testClient.mapRoutes.get(
          startLat = startPoint.lat,
          startLng = startPoint.lng,
          endLat = endPoint.lat,
          endLng = endPoint.lng
        )
      ) { route =>
        // TODO verify the distance exists and is logical
        route.polyline must be ("qtihGzn_kNXdC|CtScJcs@Fl@Hp@_@cDLbAs@cGd@~Du@sGNrA]cDLnAy@{Hj@jFs@qGFd@g@gF^`E_@eE?BCQBLcBeNOmA")
        }
      }
    }

    "/GET mapRoutes/snap" must {
      "return a point on the nearest road to the specified point" in {
        val point = Point(43.479211, -80.615170)
        whenReady(
          testClient.mapRoutes.getSnap(
            lat = point.lat,
            lng = point.lng
          )
        ) { shiftedPoint =>
          // TODO fix the return order from the postgis functions
          shiftedPoint must be (Point(-80.61509537630674,43.478694151699756))
        }
      }
    }

    "/POST mapRoutes" must {
      "returns a polyline of a route between multiple points" in {
        val points = Seq(
          Point(43.465299, -80.610043),
          Point(43.470923, -80.616310),
          Point(43.472495, -80.610693)
        )
        whenReady(testClient.mapRoutes.post(points)) { route =>
          // TODO verify the distance exists and is logical
          route.polyline must be ("cihhGvc_kNq@x@uAdBwD`EaCpCsAzAoQtS??sHcb@")
        }
      }
    }
  }
