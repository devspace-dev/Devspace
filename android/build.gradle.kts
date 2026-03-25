import org.gradle.api.tasks.Delete

buildscript {
  repositories {
    google()
    mavenCentral()
  }
  dependencies {
    classpath("com.google.gms:google-services:4.4.4")
  }
}

allprojects {
  repositories {
    google()
    mavenCentral()
  }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
  val newSubprojectBuildDir = newBuildDir.dir(project.name)
  project.layout.buildDirectory.set(newSubprojectBuildDir)
  evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
  delete(rootProject.layout.buildDirectory)
}
