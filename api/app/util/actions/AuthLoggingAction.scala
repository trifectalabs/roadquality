package util.actions

import javax.inject.Inject

import org.slf4j.LoggerFactory
import play.api.mvc._
import play.api.mvc.Results._
import scala.concurrent.{ ExecutionContext, Future }
import util.JwtUtil

import com.trifectalabs.roadquality.v0.models.User

class AuthLoggingAction @Inject() (jwt: JwtUtil)(implicit ec: ExecutionContext) {
  object AuthLoggingAction extends ActionBuilder[Request] {
    val logger = LoggerFactory.getLogger("requests")

    def invokeBlock[A](request: Request[A], block: (Request[A]) => Future[Result]) = {
      val tokenOpt = request.headers.get("Authorization").map { _.replace("Bearer", "").trim }
      val userOpt = tokenOpt.flatMap(jwt.decodeToken(_))

      userOpt match {
        case Some(user) =>
          logger.info(s"User ID: ${user.id}, URI: ${request.path}, Method: ${request.method}, Params: ${request.queryString}, Body: ${request.body.toString}")
          block {
            new WrappedRequest[A](request) {
              override def queryString = request.queryString + ("userId" -> Seq(user.id.toString))
            }
          }
        case None =>
          val message = tokenOpt match {
            case Some(token) =>
              logger.info(s"Invalid/expired JWT token received: ${token}")
              "Invalid/expired JWT token"
            case None =>
              logger.info(s"No JWT token present in request")
              "No JWT present in request"
          }
          Future(Unauthorized(message))
      }
    }
  }
}
