name := "cerebro"
organization := "cerebro"
version := "0.11.0"
scalaVersion := "2.13.18"

maintainer := "Cerebro image maintainers"

val jacksonVersion = "2.18.11"

libraryDependencies ++= Seq(
  guice,
  ws,
  filters,
  "org.playframework" %% "play-slick" % "6.2.0",
  "org.playframework" %% "play-slick-evolutions" % "6.2.0",
  "org.xerial" % "sqlite-jdbc" % "3.54.1.0",
  "org.specs2" %% "specs2-core" % "4.20.9" % Test,
  "org.specs2" %% "specs2-junit" % "4.20.9" % Test,
  "org.specs2" %% "specs2-mock" % "4.20.9" % Test
)

// Play 3.0.12 still pulls Jackson 2.14 and an older Guava; bump the fixed lines for Trivy.
dependencyOverrides ++= Seq(
  "com.fasterxml.jackson.core" % "jackson-core" % jacksonVersion,
  "com.fasterxml.jackson.core" % "jackson-databind" % jacksonVersion,
  "com.fasterxml.jackson.core" % "jackson-annotations" % jacksonVersion,
  "com.fasterxml.jackson.datatype" % "jackson-datatype-jdk8" % jacksonVersion,
  "com.fasterxml.jackson.datatype" % "jackson-datatype-jsr310" % jacksonVersion,
  "com.fasterxml.jackson.dataformat" % "jackson-dataformat-cbor" % jacksonVersion,
  "com.fasterxml.jackson.module" % "jackson-module-parameter-names" % jacksonVersion,
  "com.fasterxml.jackson.module" % "jackson-module-paranamer" % jacksonVersion,
  "com.fasterxml.jackson.module" %% "jackson-module-scala" % jacksonVersion,
  "com.google.guava" % "guava" % "33.7.2-jre"
)

lazy val root = (project in file("."))
  .enablePlugins(PlayScala, BuildInfoPlugin, JavaAppPackaging, LauncherJarPlugin)
  .settings(
    buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion),
    buildInfoPackage := "models",
    Compile / doc / sources := Seq.empty,
    Compile / packageDoc / publishArtifact := false,
    pipelineStages := Seq(digest, gzip)
  )
