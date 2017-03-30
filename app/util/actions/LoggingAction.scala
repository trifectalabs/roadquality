package util.actions

import org.slf4j.LoggerFactory
import play.api.mvc._
import scala.concurrent.Future


object LoggingAction extends ActionBuilder[Request] {
  val logger = LoggerFactory.getLogger("requests")
  println(logger)

  def invokeBlock[A](request: Request[A], block: (Request[A]) => Future[Result]) = {
    println("Logging shit")
    logger.info(s"URI: ${request.path}, Params: ${request.queryString}, Body: ${request.body.toString}")
    block(request)
  }
}
