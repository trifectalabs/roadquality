package db.dao

import java.util.UUID

import com.trifectalabs.road.quality.v0.models.{ User, UserForm }

import scala.concurrent.Future


trait UsersDao {
  def getById(id: UUID): Future[User]
  def findByEmail(email: String): Future[Option[User]]
  def insert(userForm: UserForm): Future[User]
  def update(user: User): Future[User]
}
