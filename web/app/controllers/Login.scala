package controllers

import javax.inject.Inject
import java.util.UUID

import play.api.mvc.{Action, Controller}
import play.api.libs.json.Json

import util.OAuth2

class Login @Inject() (oauth2: OAuth2) extends Controller {
  def oauth() = Action {
    val randomState = UUID.randomUUID().toString
    val redirectUrl = oauth2.getAuthorizationUrl(randomState)
    Redirect(redirectUrl).withSession("oauth-state" -> randomState)
  }
}
