name := "road_quality"

version := "git describe --dirty --tags --always".!!.stripPrefix("v").trim

scalaVersion := "2.11.8"

buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion)

buildInfoPackage := "buildInfo"

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(BuildInfoPlugin)
  .settings(dockerSettings: _*)

resolvers += "Sonatype releases" at "https://oss.sonatype.org/content/repositories/releases"

libraryDependencies ++= Seq(
  "com.vividsolutions" % "jts" % "1.13",
  "com.github.trifectalabs" %% "polyline-scala" % "1.2.0",
  "com.typesafe.play" %% "play-slick" % "2.0.2",
  "com.typesafe.play" %% "play-slick-evolutions" % "2.0.2",
  "org.postgresql" % "postgresql" % "9.4-1201-jdbc41",
  "com.github.tminglei" %% "slick-pg" % "0.14.6",
  "com.github.tminglei" %% "slick-pg_joda-time" % "0.14.6",
  "com.github.tminglei" %% "slick-pg_play-json" % "0.14.6",
  "com.github.tminglei" %% "slick-pg_jts" % "0.14.6",
  "io.megl" %% "play-json-extra" % "2.4.3",
  ws,
  filters
)

lazy val dockerSettings: Seq[Setting[_]] = Seq(
  dockerRepository := Some("kiambogo"),
  maintainer in Docker := "Christopher Poenaru <kiambogo@gmail.com>",
  dockerBaseImage := "openjdk",
  dockerExposedPorts := Seq(9000),
  dockerExposedVolumes := Seq("/opt/docker/logs"),
  version in Docker := version.value
)
