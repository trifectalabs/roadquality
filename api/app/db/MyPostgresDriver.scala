package db

import java.util.UUID
import java.sql.JDBCType
import com.github.tminglei.slickpg._
import slick.jdbc.{PositionedResult, PositionedParameters, SetParameter}


trait MyPostgresDriver extends ExPostgresProfile
                          with PgArraySupport
                          with PgDateSupportJoda
                          with PgPlayJsonSupport
                          with PgNetSupport
                          with PgPostGISSupport
                          with PgLTreeSupport
                          with PgRangeSupport
                          with PgHStoreSupport
                          with PgSearchSupport {

  override val pgjson = "jsonb"
  override val api = new API with ArrayImplicits
                             with DateTimeImplicits
                             with PostGISImplicits
                             with PostGISPlainImplicits
                             with UUIDPlainImplicits
                             with PlayJsonImplicits
                             with NetImplicits
                             with LTreeImplicits
                             with RangeImplicits
                             with HStoreImplicits
                             with SearchImplicits
                             with SearchAssistants {}

  trait API extends super.API with PostGISImplicits with PostGISAssistants
}

object MyPostgresDriver extends MyPostgresDriver

trait UUIDPlainImplicits {
  implicit class PgPositionedResult(val r: PositionedResult) {
    def nextUUID: UUID = UUID.fromString(r.nextString)
    def nextUUIDOption: Option[UUID] = r.nextStringOption().map(UUID.fromString)
  }
}
