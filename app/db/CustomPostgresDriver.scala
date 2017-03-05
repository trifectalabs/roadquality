package db

import com.github.tminglei.slickpg._
import play.api.libs.json._
import java.util.UUID
import play.api.libs.json._
import org.joda.time.LocalDateTime
import com.vividsolutions.jts.geom.{Geometry, Point}
import com.vividsolutions.jts.io.{WKTReader, WKTWriter}
import com.github.tminglei.slickpg.PgRangeSupportUtils

trait CustomPostgresDriver extends ExPostgresProfile
  with PgArraySupport
  with PgDate2Support
  with PgRangeSupport
  with PgHStoreSupport
  with PgPlayJsonSupport
  with PgSearchSupport
  with PgPostGISSupport
  with PgNetSupport
  with PgLTreeSupport {

  def pgjson = "jsonb"

  override val api = MyAPI

  object MyAPI extends API with ArrayImplicits
    with DateTimeImplicits
    with JsonImplicits
    with NetImplicits
    with LTreeImplicits
    with PostGISImplicits
    with RangeImplicits
    with HStoreImplicits
    with SearchImplicits {
      implicit val strListTypeMapper = new SimpleArrayJdbcType[String]("text").to(_.toList)
      implicit val playJsonArrayTypeMapper =
        new AdvancedArrayJdbcType[JsValue](pgjson,
          (s) => utils.SimpleArrayUtils.fromString[JsValue](Json.parse(_))(s).orNull,
          (v) => utils.SimpleArrayUtils.mkString[JsValue](_.toString())(v)
          ).to(_.toList)
    }

}


object CustomPostgresDriver extends CustomPostgresDriver
