package util

import javax.inject.Inject
import java.util.UUID
import java.util.NoSuchElementException

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.Try

import play.api.mvc._
import play.api.libs.ws._
import play.api.http.{MimeTypes, HeaderNames}
import play.api.Configuration

import com.trifectalabs.road.quality.v0.models.{ User, UserRole }
import db.dao.UsersDao

class OAuth2 @Inject() (configuration: Configuration, ws: WSClient, userDao: UsersDao, jwt: JwtUtil) extends Controller {
  lazy val stravaAuthUri = configuration.getString("strava.auth.uri").get
  lazy val stravaTokenUri = configuration.getString("strava.auth.token_uri").get
  lazy val stravaClientId = configuration.getString("strava.client.id").get
  lazy val stravaClientSecret = configuration.getString("strava.client.secret").get
  lazy val stravaClientRedirectUri = configuration.getString("strava.client.redirect_uri").get
  lazy val stravaClientScope = configuration.getString("strava.client.scope").get

  def callback(codeOpt: Option[String] = None, stateOpt: Option[String] = None) = Action.async { implicit request =>
    (for {
      code <- codeOpt
      state <- stateOpt
      oauthState <- request.session.get("oauth-state")
    } yield {
      if (state == oauthState) {
        getStravaUserData(code).flatMap { userData =>
          userDao.upsert(
            userData.firstName,
            userData.lastName,
            userData.email,
            None,
						userData.sex,
						userData.stravaToken).map { user =>
							val jwtToken = jwt.createToken(user)
							Redirect(s"/#dashboard?token=$jwtToken")
						}
        }.recover {
          case ex: IllegalStateException => Unauthorized(ex.getMessage)
        }
      }
      else {
        Future.successful(BadRequest("Invalid OAuth state"))
      }
    }).getOrElse(Future.successful(BadRequest("No parameters supplied")))
  }

  def getAuthorizationUrl(state: String): String = {
    stravaAuthUri.format(stravaClientId, stravaClientRedirectUri, stravaClientScope, state)
  }

  private[this] def getStravaUserData(code: String): Future[StravaUserData] = {
    val tokenResponse = ws.url(stravaTokenUri).
      withQueryString("client_id" -> stravaClientId,
        "client_secret" -> stravaClientSecret,
        "code" -> code).
      post(Results.EmptyContent())

      tokenResponse.map { response =>
        val accessToken = (response.json \ "access_token").as[String]
        val firstName = (response.json \ "athlete" \ "firstname").as[String]
        val lastName = (response.json \ "athlete" \ "lastname").as[String]
        val email = (response.json \ "athlete" \ "email").as[String]
        val sex = (response.json \ "athlete" \ "sex").asOpt[String]

        StravaUserData(
          firstName = firstName,
          lastName = lastName,
          email = email,
          stravaToken = accessToken,
          sex = sex)
      }
  }
}

case class StravaUserData(
  firstName: String,
  lastName: String,
  email: String,
  stravaToken: String,
  sex: Option[String])
