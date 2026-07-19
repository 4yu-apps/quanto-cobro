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

// Alguns plugins (ex.: file_picker 8.x) fixam compileSdk 34, mas dependências
// transitivas exigem 36. O plugin seta 34 no PRÓPRIO evaluate, então só um
// afterEvaluate (registrado ANTES de forçar a avaliação) sobrescreve pra 36.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            runCatching {
                (ext as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
