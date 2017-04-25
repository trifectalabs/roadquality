package controllers

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.{ User, UserUpdateForm }
import com.trifectalabs.roadquality.v0.models.json._
import com.trifectalabs.roadquality.v0.Bindables
import db.dao.UsersDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.AuthLoggingAction

import scala.concurrent.{ ExecutionContext, Future }

class Users @Inject() (usersDao: UsersDao, authLoggingAction: AuthLoggingAction)(implicit ec: ExecutionContext) extends Controller {
  import authLoggingAction._

  def get(userId: Option[UUID], userEmail: Option[String]) = AuthLoggingAction.async {
    (userId, userEmail) match {
      case (Some(id), None) => usersDao.getById(id).map(s => Ok(Json.toJson(s)))
      case (None, Some(email)) => usersDao.findByEmail(email).map(s => Ok(Json.toJson(s)))
      case (None, None) => Future(BadRequest("User ID or email must be specified"))
      case (Some(_), Some(_)) => Future(BadRequest("User ID and email cannot both be specified"))
      case _ => Future(BadRequest)
    }
	}

  def delete(user_id: _root_.java.util.UUID) = AuthLoggingAction.async { implicit request =>
    usersDao.softDelete(user_id).map(s => Ok(Json.toJson(s)))
	}

  def put(userId: _root_.java.util.UUID) = AuthLoggingAction.async(parse.json[UserUpdateForm]) { implicit request =>
    val userUpdateForm = request.body
    usersDao.getById(userId).flatMap { existingUser =>
      val updatedUser = existingUser.copy(
        sex = if (!userUpdateForm.sex.isDefined) existingUser.sex else Some(userUpdateForm.sex.get),
        birthdate = if (!userUpdateForm.birthdate.isDefined) existingUser.birthdate else Some(userUpdateForm.birthdate.get)
      )

      usersDao.update(updatedUser).map(s => Ok(Json.toJson(s)))
    }
  }
}
