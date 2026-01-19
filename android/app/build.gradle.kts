import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties().apply {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        load(FileInputStream(keystoreFile))
    }
}

android {
    namespace = "com.humorstech.respyr_clinical"
    compileSdk = flutter.compileSdkVersion

    // ✅ MUST match installed NDK version exactly
    ndkVersion = "28.1.13356709"


    defaultConfig {
        applicationId = "com.humorstech.respyr_clinical"
        minSdk = flutter.minSdkVersion
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Optional: keep only if you really want to restrict ABIs
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    // ✅ Important for modern packaging of native libs
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        create("release") {
            // If key.properties not present, this will crash. Keep only if always present.
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false

            ndk {
                debugSymbolLevel = "FULL"
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.firebase:firebase-auth:23.1.0")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
