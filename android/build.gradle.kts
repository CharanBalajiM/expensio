allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val rootBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.value(rootBuildDir)

subprojects {
    val projectDir = project.projectDir.absolutePath
    val rootDir = rootProject.projectDir.absolutePath
    val isSameDrive = if (projectDir.contains(":") && rootDir.contains(":")) {
        projectDir.substringBefore(":").equals(rootDir.substringBefore(":"), ignoreCase = true)
    } else {
        true
    }
    if (isSameDrive) {
        project.layout.buildDirectory.value(rootBuildDir.dir(project.name))
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
