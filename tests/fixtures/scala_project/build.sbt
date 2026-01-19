scalaVersion := "2.13.12"

name := "scala-example"
organization := "com.example"
version := "1.0.0"

libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.17" % Test

scalacOptions ++= Seq(
  "-target:jvm-1.8",
  "-deprecation",
  "-feature"
)
