package controllers

import javax.inject.Inject

import play.api.mvc.{Action, Controller}
import play.api.libs.json.Json
import buildInfo.BuildInfo
import play.Environment

import util.Metrics
import com.trifectalabs.roadquality.v0.models.json._
import com.trifectalabs.roadquality.v0.models.VersionInfo

class Info @Inject()(override val env: Environment) extends Controller with Metrics {

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
