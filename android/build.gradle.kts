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
    if (name == "geolocator_android") {
        afterEvaluate {
            extensions.findByName("android")?.let { androidExtension ->
                val lint = androidExtension.javaClass.methods
                    .firstOrNull { it.name == "getLint" && it.parameterCount == 0 }
                    ?.invoke(androidExtension)
                lint?.javaClass?.methods
                    ?.firstOrNull {
                        it.name == "getDisable" && it.parameterCount == 0
                    }
                    ?.invoke(lint)
                    ?.let { disable ->
                        @Suppress("UNCHECKED_CAST")
                        (disable as MutableSet<String>).add("MissingPermission")
                    }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
