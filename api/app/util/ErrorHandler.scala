package util

import javax.inject._

import play.api.http.DefaultHttpErrorHandler
import play.api._
import play.api.mvc._
import play.api.mvc.Results._
import play.api.routing.Router
import scala.concurrent.{ExecutionContext, Future}
import models.Exceptions._

@Singleton
class ErrorHandler @Inject() (
    env: Environment,
    config: Configuration,
    sourceMapper: OptionalSourceMapper,
    router: Provider[Router]
  )(implicit ec: ExecutionContext)
extends DefaultHttpErrorHandler(env, config, sourceMapper, router) {

  override def onServerError(request: RequestHeader, exception: Throwable) = {
    exception match {
      case e: NoRouteFoundException => Future(NoContent)
      case e: NoSnapFoundException => Future(NoContent)
    }
  }
}
