package controllers

import play.api.mvc.{Action, Controller}
import play.api.libs.json.Json
import buildInfo.BuildInfo

import util.Metrics
import com.trifectalabs.roadquality.v0.models.json._
import com.trifectalabs.roadquality.v0.models.VersionInfo

class Info extends Controller with Metrics {
  def get() = Action {
    response.time {
      Ok {
        Json.toJson(VersionInfo(
          name = BuildInfo.name,
          version = BuildInfo.version,
          scalaVersion = BuildInfo.scalaVersion,
          sbtVersion = BuildInfo.sbtVersion
        ))
      }
    }
  }
}
