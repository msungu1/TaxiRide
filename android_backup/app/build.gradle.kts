import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val localProperties = Properties().apply {
    load(FileInputStream(rootProject.file("local.properties")))
}

android {
    namespace = "com.example.sizemore_taxi"
    compileSdk = localProperties.getProperty("flutter.compileSdkVersion")?.toInt() ?: 34
    ndkVersion = localProperties.getProperty("flutter.ndkVersion") ?: "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.sizemore_taxi"
        minSdk = localProperties.getProperty("flutter.minSdkVersion")?.toInt() ?: 21
        targetSdk = localProperties.getProperty("flutter.targetSdkVersion")?.toInt() ?: 34
        versionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
        versionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}
