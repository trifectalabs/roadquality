package controllers

import javax.inject.Inject
import java.util.UUID

import play.twirl.api.Html
import play.api.mvc.{Action, Controller}
import play.api.libs.ws._
import play.api.libs.json.{ Json, JsObject }
import play.api.Configuration
import scala.concurrent.{ ExecutionContext, Future }
import db.dao.UsersDao
import com.trifectalabs.roadquality.v0.models.json._

import util.actions.Authenticated
import util._
import models.EmailSignup

class Main @Inject() (jwtUtil: JwtUtil, wsClient: WSClient, config: Configuration)(implicit ec: ExecutionContext) extends Controller with Metrics {

  def app(tokenOpt: Option[String]) = Action { request =>
    tokenOpt flatMap { token =>
      jwtUtil.decodeToken(token) map { user =>
        Ok(views.html.index((Json.toJson(user).as[JsObject] + ("token" -> Json.toJson(token))).toString))
      }
    } getOrElse(Ok(views.html.index("")))
  }

  def notFound(path: String) = Action { request =>
    NotFound(views.html.notFound())
  }

  def addEmail = Action.async(parse.json[EmailSignup]) { request =>
    lazy val mailchimpToken = config.getString("mailchimp.token").get
    val signup = request.body

    (wsClient
      .url("https://us12.api.mailchimp.com/lists/8271d03ba2/members")
      .withAuth("", mailchimpToken, WSAuthScheme.BASIC)
      .post(Json.toJson(signup))) map { resp =>
        if (resp.status == 200) {
          webMetrics.counter("email_signups") += 1
          Accepted("")
        }
        else
          InternalServerError("")
      }
  }

}
