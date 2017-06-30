package util

import javax.inject.Inject
import java.util.UUID
import java.util.NoSuchElementException

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.Try

import play.api.mvc._
import play.api.libs.ws._
import play.api.libs.json._
import play.api.http.{MimeTypes, HeaderNames}
import play.api.Configuration

import com.trifectalabs.roadquality.v0.models.{ User, UserRole }
import com.trifectalabs.roadquality.v0.models.json._
import db.dao.{ UsersDao, BetaUserWhitelistDao }

class OAuth2 @Inject() (configuration: Configuration, ws: WSClient, userDao: UsersDao, jwt: JwtUtil, betaList: BetaUserWhitelistDao) extends Controller {
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
          betaList.exists(userData.email).flatMap { isBetaUser =>
            if (isBetaUser) {
              userDao.upsert(
                userData.firstName,
                userData.lastName,
                userData.email,
                userData.city,
                userData.province,
                userData.country,
                None,
                userData.sex,
                userData.stravaToken).map { user =>
                  val jwtToken = jwt.createToken(user)
                  Redirect(s"/app?token=$jwtToken")
                }
            }
            else Future(Redirect("/"))
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
        val city = (response.json \ "athlete" \ "city").asOpt[String]
        val province = (response.json \ "athlete" \ "state").asOpt[String]
        val country = (response.json \ "athlete" \ "country").asOpt[String]
        val sex = (response.json \ "athlete" \ "sex").asOpt[String]

        StravaUserData(
          firstName = firstName,
          lastName = lastName,
          email = email,
          city = city,
          province = province,
          country = country,
          stravaToken = accessToken,
          sex = sex)
      }
  }
}

case class StravaUserData(
  firstName: String,
  lastName: String,
  email: String,
  city: Option[String],
  province: Option[String],
  country: Option[String],
  stravaToken: String,
  sex: Option[String])
