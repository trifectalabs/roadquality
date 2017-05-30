package models

import org.joda.time.DateTime

case class TileCacheExpiration(
  bounds: String,
  createdAt: DateTime,
  processedAt: Option[DateTime]
)
