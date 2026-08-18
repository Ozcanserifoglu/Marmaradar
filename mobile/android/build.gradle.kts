allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun bumpPluginCompileSdk() {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            val current = compileSdkVersion?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (current < 36) {
                compileSdkVersion(36)
            }
        }
    }
    if (state.executed) {
        bumpPluginCompileSdk()
    } else {
        afterEvaluate { bumpPluginCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
