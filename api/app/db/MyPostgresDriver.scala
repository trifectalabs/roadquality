package db

import com.github.tminglei.slickpg._

trait MyPostgresDriver extends ExPostgresDriver
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
