package db.dao

import javax.inject.{Inject, Singleton}
import java.util.UUID

import org.joda.time.DateTime
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import slick.jdbc.GetResult
import scala.concurrent.{ExecutionContext, Future}

import com.trifectalabs.road.quality.v0.models.{ User, UserRole }
import db.MyPostgresDriver
import db.Tables._


@Singleton
class PostgresUsersDao @Inject() (protected val dbConfigProvider: DatabaseConfigProvider)(implicit ec: ExecutionContext)
extends UsersDao with HasDatabaseConfigProvider[MyPostgresDriver] {
	import driver.api._

	override def getById(id: UUID): Future[User] = {
		db.run(users.filter(_.id === id).result.head)
	}

	override def findByEmail(email: String): Future[Option[User]] = {
		db.run(users.filter(_.email === email.trim.toLowerCase).result.headOption)
	}

	override def insert(
		firstName: String,
		lastName: String,
		email: String,
		birthdate: _root_.scala.Option[_root_.org.joda.time.DateTime],
		sex: _root_.scala.Option[String],
		stravaToken: String
	): Future[User] = {
		val id = UUID.randomUUID()
		val user = User(
			id = id,
			firstName = firstName,
			lastName = lastName,
			email = email,
			birthdate = birthdate,
			sex = sex,
			stravaToken = stravaToken,
			createdAt = DateTime.now(),
			updatedAt = DateTime.now(),
			deletedAt = None,
			role = UserRole.User)

		db.run((users += user).map(_ => user))
	}

	override def update(user: User): Future[User] = {
		val query = for { u <- users if u.id === user.id } yield (u.firstName, u.lastName, u.email, u.stravaToken)
		db.run(query.update(user.firstName, user.lastName, user.email, user.stravaToken)).map(i => user)
	}

	override def upsert(
		firstName: String,
		lastName: String,
		email: String,
		birthdate: _root_.scala.Option[_root_.org.joda.time.DateTime],
		sex: _root_.scala.Option[String],
		stravaToken: String
	): Future[User] = {
		val isExistingUser = db.run(users.filter(_.email === email.trim.toLowerCase).result.headOption)

		isExistingUser.flatMap { isEu =>
			isEu match {
				case Some(eu) => update(eu)
				case None => insert(firstName, lastName, email, birthdate, sex, stravaToken)
			}
		}
	}

	override def delete(id: UUID): Future[Boolean] = {
		db.run(users.filter(_.id === id).delete.map(_ => true))
	}

	def updateSex(id: UUID, sex: String): Future[User] = {
		val query = for { s <- users if s.id === id } yield (s.sex)
		db.run(query.update(Some(sex))).flatMap(i => getById(id))
	}

	def updateBirthdate(id: UUID, birthdate: DateTime): Future[User] = {
		val query = for { s <- users if s.id === id } yield (s.birthdate)
		db.run(query.update(Some(birthdate))).flatMap(i => getById(id))
	}
}
