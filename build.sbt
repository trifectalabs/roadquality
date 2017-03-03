name := "road_quality"

version := "git describe --dirty --tags --always".!!.stripPrefix("v").trim

scalaVersion := "2.11.8"

buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion)

buildInfoPackage := "buildInfo"

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(BuildInfoPlugin)
  .settings(dockerSettings: _*)

libraryDependencies ++= Seq(
  "com.github.tminglei" %% "slick-pg" % "0.15.0-M4",
  "com.github.tminglei" %% "slick-pg_joda-time" % "0.15.0-M4",
  "com.github.tminglei" %% "slick-pg_jts" % "0.15.0-M4",
	ws
)

lazy val dockerSettings: Seq[Setting[_]] = Seq(
  dockerRepository := Some("kiambogo"),
  maintainer in Docker := "Christopher Poenaru <kiambogo@gmail.com>",
  dockerBaseImage := "openjdk",
  dockerExposedPorts := Seq(9000),
  dockerExposedVolumes := Seq("/opt/docker/logs")
)
