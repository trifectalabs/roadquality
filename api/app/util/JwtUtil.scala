package util

import javax.inject.Inject

import play.api.Configuration
import play.api.libs.json.Json._
import scala.util._

import pdi.jwt.{Jwt, JwtAlgorithm, JwtHeader, JwtClaim, JwtOptions}
import com.trifectalabs.roadquality.v0.models.{ User, UserRole }
import com.trifectalabs.roadquality.v0.models.json._

class JwtUtil @Inject() (configuration: Configuration) {
  lazy val secret = configuration.getString("play.crypto.secret").get

  def isTokenValid(token: String): Boolean = {
    Jwt.isValid(token, secret, Seq(JwtAlgorithm.HS256))
  }

  def decodeToken(token: String): Option[User] = {
    Jwt.decode(token, secret, Seq(JwtAlgorithm.HS256)) match {
      case Success(t) => parse(t).asOpt[User]
      case Failure(e) => None
    }
  }

	def createToken(user: User, durationSec: Long = 2629746000l): String = {
    Jwt.encode(JwtClaim({stringify(toJson(user))}).issuedNow.expiresIn(durationSec), secret, JwtAlgorithm.HS256)
	}

}
