package controllers

import play.api.mvc.{Action, Controller}
import play.api.libs.json.Json
import buildInfo.BuildInfo

import com.trifectalabs.road.quality.v0.models.json._
import com.trifectalabs.road.quality.v0.models.VersionInfo

class Info extends Controller {
  def get() = Action {
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
