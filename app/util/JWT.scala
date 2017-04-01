package util

import javax.inject.Inject

import play.api.Configuration
import play.api.libs.json.Json._

import pdi.jwt.{Jwt, JwtAlgorithm, JwtHeader, JwtClaim, JwtOptions}
import com.trifectalabs.road.quality.v0.models.{ User, UserRole }
import com.trifectalabs.road.quality.v0.models.json._

class JWT @Inject() (configuration: Configuration) {
  lazy val secret = configuration.getString("play.crypto.secret").get

	def createToken(user: User): String = {
    Jwt.encode(stringify(toJson(user)), secret, JwtAlgorithm.HS256)
	}

}
