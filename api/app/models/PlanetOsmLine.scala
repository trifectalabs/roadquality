package models

import com.vividsolutions.jts.geom.Geometry

case class PlanetOsmLine(osmId: Long, way: Geometry)
