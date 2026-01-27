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

    // ✅ Updated to 36 to satisfy plugin requirements (shared_preferences, image_picker, etc.)
    compileSdk = 36

    // Using the NDK version you specified
    ndkVersion = "28.1.13356709"

    defaultConfig {
        applicationId = "com.humorstech.respyr_clinical"

        // Recommended to hardcode or ensure flutter.minSdkVersion is at least 23
        minSdk = flutter.minSdkVersion

        // targetSdk 35 is currently the requirement for Google Play
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        create("release") {
            val hasKeyProps = keystoreProperties.containsKey("storeFile")
                    && keystoreProperties.containsKey("storePassword")
                    && keystoreProperties.containsKey("keyAlias")
                    && keystoreProperties.containsKey("keyPassword")

            if (hasKeyProps) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
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
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
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
