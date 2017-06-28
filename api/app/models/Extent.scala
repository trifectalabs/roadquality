package models

import play.api.libs.json._

case class Extent(minx: Double, miny: Double, maxx: Double, maxy: Double)

object Extent {
  implicit val extentFormat = Json.format[Extent]
}
