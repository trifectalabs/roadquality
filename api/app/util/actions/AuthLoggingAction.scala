package util.actions

import javax.inject.Inject

import org.slf4j.LoggerFactory
import play.api.mvc._
import scala.concurrent.Future
import util.JwtUtil

import com.trifectalabs.roadquality.v0.models.User

class AuthLoggingAction @Inject() (jwt: JwtUtil) {
  object AuthLoggingAction extends ActionBuilder[Request] {
    val logger = LoggerFactory.getLogger("requests")

    def invokeBlock[A](request: Request[A], block: (Request[A]) => Future[Result]) = {
      val user = request.headers.get("Authorization").flatMap { authHeader =>
        val token = authHeader.replace("Bearer", "").trim
        jwt.decodeToken(token)
      }

      logger.info(s"User ID: ${user.map(f => f.id).getOrElse("")}, URI: ${request.path}, Method: ${request.method}, Params: ${request.queryString}, Body: ${request.body.toString}")
      block(request)
    }
  }
}
