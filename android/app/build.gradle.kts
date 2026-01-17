import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties (safe)
val keystoreProperties = Properties().apply {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        load(FileInputStream(keystoreFile))
    }
}

android {
    namespace = "com.humorstech.respyr_clinical"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    defaultConfig {
        applicationId = "com.humorstech.respyr_clinical"
        minSdk = flutter.minSdkVersion
        targetSdk = 35

        // ✅ keep Flutter-managed version values
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Support common ABIs
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    signingConfigs {
        create("release") {
            // ✅ Only configure signing if key.properties contains storeFile
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            }
        }
    }

    buildTypes {
        getByName("release") {
            // ✅ Only attach signing config if present (prevents crash)
            if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfig = signingConfigs.getByName("release")
            }

            // Optional size optimizations
            isMinifyEnabled = false
            isShrinkResources = false

            // ✅ Include debug symbols for crash analysis
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
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.firebase:firebase-auth:22.3.0")
    implementation("com.google.android.gms:play-services-auth:21.1.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
