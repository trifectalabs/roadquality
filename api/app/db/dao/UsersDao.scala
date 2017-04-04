package db.dao

import java.util.UUID
import org.joda.time.DateTime

import com.trifectalabs.roadquality.v0.models.User

import scala.concurrent.Future

trait UsersDao {
  def getById(id: UUID): Future[User]
  def findByEmail(email: String): Future[Option[User]]
  def update(user: User): Future[User]
  def insert(
    firstName: String,
    lastName: String,
    email: String,
    birthdate: _root_.scala.Option[_root_.org.joda.time.DateTime],
    sex: _root_.scala.Option[String],
    stravaToken: String): Future[User]
  def upsert(firstName: String,
    lastName: String,
    email: String,
    birthdate: _root_.scala.Option[_root_.org.joda.time.DateTime],
    sex: _root_.scala.Option[String],
    stravaToken: String): Future[User]
  def delete(id: UUID): Future[Boolean]
  def updateSex(id: UUID, sex: String): Future[User]
  def updateBirthdate(id: UUID, birthdate: DateTime): Future[User]
}
