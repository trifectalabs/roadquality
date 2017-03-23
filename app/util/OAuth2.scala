package util

import javax.inject.Inject
import java.util.UUID

import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import play.api.mvc._
import play.api.libs.ws._
import play.api.http.{MimeTypes, HeaderNames}
import play.api.Configuration

class OAuth2 @Inject() (configuration: Configuration, ws: WSClient) extends Controller {
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
        getToken(code).map { accessToken =>
          Redirect(util.routes.OAuth2.success()).withSession("oauth-token" -> accessToken)
        }.recover {
          case ex: IllegalStateException => Unauthorized(ex.getMessage)
        }
      }
      else {
        Future.successful(BadRequest("Invalid OAuth state"))
      }
    }).getOrElse(Future.successful(BadRequest("No parameters supplied")))
  }

  def success() = Action.async { request =>
    request.session.get("oauth-token").fold(Future.successful(Unauthorized("Not authorized. Please login."))) { authToken =>
      ws.url("https://www.strava.com/api/v3/athlete").
        withHeaders(HeaderNames.AUTHORIZATION -> s"Bearer $authToken").
        get().map { response =>
          Ok(response.json)
        }
    }
  }

  def getAuthorizationUrl(state: String): String = {
    stravaAuthUri.format(stravaClientId, stravaClientRedirectUri, stravaClientScope, state)
  }

  private[this] def getToken(code: String): Future[String] = {
    val tokenResponse = ws.url(stravaTokenUri).
      withQueryString("client_id" -> stravaClientId,
        "client_secret" -> stravaClientSecret,
        "code" -> code).
      post(Results.EmptyContent())

    tokenResponse.flatMap { response =>
      (response.json \ "access_token").asOpt[String].fold {
        Future.failed[String](new IllegalStateException("Failed to parse access token")) } { accessToken =>
        Future.successful(accessToken)
      }
    }
  }
}
