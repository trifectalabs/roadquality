package util.actions

import org.slf4j.LoggerFactory
import play.api.mvc._
import scala.concurrent.Future


object LoggingAction extends ActionBuilder[Request] {
  val logger = LoggerFactory.getLogger("requests")

  def invokeBlock[A](request: Request[A], block: (Request[A]) => Future[Result]) = {
    logger.info(s"URI: ${request.path}, Method: ${request.method}, Params: ${request.queryString}, Body: ${request.body.toString}")
    block(request)
  }
}
