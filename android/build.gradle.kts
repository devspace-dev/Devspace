import org.gradle.api.tasks.Delete

rootProject.layout.buildDirectory.set(file("${projectDir}/../build"))

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))
}

subprojects {
    if (project.name != "app") {
        evaluationDependsOn(":app")
    }
}

subprojects {
    val fixNamespace: Project.() -> Unit = {
        extensions.findByName("android")?.let { android ->
            if (android is com.android.build.gradle.BaseExtension && android.namespace == null) {
                android.namespace = "com.example.${project.name.replace("-", "_")}"
            }
        }
    }

    if (state.executed) {
        fixNamespace()
    } else {
        afterEvaluate { fixNamespace() }
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
