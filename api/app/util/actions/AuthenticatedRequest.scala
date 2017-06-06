package util.actions

import javax.inject.Inject

import org.slf4j.LoggerFactory
import play.api.mvc._
import play.api.mvc.Results._
import scala.concurrent.{ ExecutionContext, Future }
import util.JwtUtil
import play.api.mvc.Security._
import scala.concurrent.ExecutionContext.Implicits.global

import com.trifectalabs.roadquality.v0.models.{ User, UserRole }

case class UnauthorizedException(msg: String) extends Exception
case class UnauthenticatedException(msg: String) extends Exception

private[this] object RequestHelper {

  private[this] def jwt = play.api.Play.current.injector.instanceOf[JwtUtil]

  val AuthorizationHeader = "Authorization"

  def userAuth(requestHeaders: Headers): Option[User]= {
    requestHeaders.get(AuthorizationHeader).flatMap(extractToken).flatMap(parseUser)
  }

  def extractToken(authHeader: String): Option[String] = {
    authHeader.split("Bearer ") match {
      case Array(_, token) => Some(token)
      case _               => None
    }
  }

  def parseUser(token: String): Option[User] = jwt.decodeToken(token)
}


class AuthenticatedRequest[A](val user: User, request: Request[A]) extends WrappedRequest[A](request) {
  def requireAdmin {
    if (user.role != UserRole.Admin) {
      throw new UnauthorizedException("Action requires admin role.")
    }
  }
}

object Authenticated extends ActionBuilder[AuthenticatedRequest] {

  def invokeBlock[A](request: Request[A], block: (AuthenticatedRequest[A]) => Future[Result]) = {
    RequestHelper.userAuth(request.headers) match {
      case None => {
        Future.successful(Unauthorized)
      }

      case Some(user) => {
        try {
          block(new AuthenticatedRequest(user, request))
        } catch {
          case e: UnauthenticatedException => Future(Unauthorized(e.msg))
          case e: UnauthorizedException => Future(Forbidden(e.msg))
        }
      }
    }
  }

}
