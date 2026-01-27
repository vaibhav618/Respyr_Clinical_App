pluginManagement {
    val localPropertiesFile = File(rootDir, "local.properties")
    val localProperties = java.util.Properties()
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
    }

    val flutterSdkPath = localProperties.getProperty("flutter.sdk")
        ?: error("flutter.sdk not set in android/local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

dependencyResolutionManagement {
    // PREFER_SETTINGS means Gradle will use the repos listed below for all plugins
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

        // ✅ ADD THIS LINE: This is where com.github.felHR85:UsbSerial is located
        maven { url = uri("https://jitpack.io") }
    }
}

include(":app")