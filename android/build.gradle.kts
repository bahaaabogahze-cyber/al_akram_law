import com.android.build.gradle.LibraryExtension

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

    // Keep Android library modules on the same SDK used by the application.
    // This is a compatibility fallback for older third-party Flutter plugins.
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            compileSdk = 36

            // app_links versions that predate their namespace migration used
            // the Java package as the Android namespace. Only set it when the
            // module has not supplied a namespace itself.
            if (project.name == "app_links" && namespace == null) {
                namespace = "com.llfbandit.app_links"
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
