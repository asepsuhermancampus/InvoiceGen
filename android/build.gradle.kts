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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext != null) {
            try {
                val androidExt = ext as org.gradle.api.plugins.ExtensionAware
                val namespace = androidExt.extensions.extraProperties.properties["namespace"]
                if (namespace == null) {
                    val namespaceMethod = ext.javaClass.getMethod("setNamespace", String::class.java)
                    namespaceMethod.invoke(ext, project.group.toString())
                }
            } catch (e: Exception) {
                // Ignore if method not found
            }
        }
    }
}
