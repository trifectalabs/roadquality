package controllers

import java.util.UUID
import javax.inject.Inject

import com.trifectalabs.roadquality.v0.models.{ User, UserUpdateForm }
import com.trifectalabs.roadquality.v0.models.json._
import com.trifectalabs.roadquality.v0.Bindables
import db.dao.UsersDao
import play.api.libs.json.Json
import play.api.mvc.{Action, Controller}
import util.actions.Authenticated

import scala.concurrent.{ ExecutionContext, Future }

class Users @Inject() (usersDao: UsersDao)(implicit ec: ExecutionContext) extends Controller {

  def get = Authenticated.async { req =>
    Future(Ok(Json.toJson(req.user)))
  }

  def delete(user_id: _root_.java.util.UUID) = Authenticated.async { req =>
    usersDao.softDelete(req.user.id).map(s => Ok(Json.toJson(s)))
	}

  def put(userId: _root_.java.util.UUID) = Authenticated.async(parse.json[UserUpdateForm]) { req =>
    val userUpdateForm = req.body
    usersDao.getById(userId).flatMap { existingUser =>
      val updatedUser = existingUser.copy(
        sex = if (!userUpdateForm.sex.isDefined) existingUser.sex else Some(userUpdateForm.sex.get),
        birthdate = if (!userUpdateForm.birthdate.isDefined) existingUser.birthdate else Some(userUpdateForm.birthdate.get)
      )

      usersDao.update(updatedUser).map(s => Ok(Json.toJson(s)))
    }
  }
}
