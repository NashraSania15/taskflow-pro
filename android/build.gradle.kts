// Required for Firebase + Google Services
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 🔥 Google Services plugin (required for FCM)
        classpath("com.google.gms:google-services:4.4.2")

        // 🔥 Firebase BOM for consistent versions
        classpath("com.google.firebase:firebase-bom:33.5.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
