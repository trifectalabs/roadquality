package models

import java.util.UUID

import com.vividsolutions.jts.geom.Geometry
import com.trifectalabs.roadquality.v0.models.{PathType, SurfaceType}

case class MiniSegment(id: UUID, trafficRating: Double, surfaceRating: Double, surface: SurfaceType, pathType: PathType, path: String)

case class MiniSegmentToSegment(miniSegmentId: UUID, miniSegmentPolyline: Geometry, segmentId: UUID)

case class MiniSegmentSplit(miniSegmentId: UUID, miniSegmentGeom: Geometry, first: Geometry, firstLength: Double, second: Geometry, secondLength: Double)
