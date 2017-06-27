package controllers

import javax.inject.Inject
import java.util.UUID

import play.twirl.api.Html
import play.api.mvc.{Action, Controller}
import play.api.libs.json.{ Json, JsObject }
import scala.concurrent.{ ExecutionContext, Future }
import db.dao.UsersDao
import com.trifectalabs.roadquality.v0.models.json._

import util.actions.Authenticated
import util.OAuth2
import util.JwtUtil
import models.EmailSignup

class Main @Inject() (jwtUtil: JwtUtil)(implicit ec: ExecutionContext) extends Controller {

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

  def addEmail = Action(parse.json[EmailSignup]) { request =>
    val signup = req.body


  }

}
