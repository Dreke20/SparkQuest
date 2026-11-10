import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val envKeystorePath = System.getenv("KEYSTORE_PATH")
val envStorePassword = System.getenv("KEYSTORE_PASSWORD")
val envKeyAlias = System.getenv("KEY_ALIAS")
val envKeyPassword = System.getenv("KEY_PASSWORD")

android {
    namespace = "com.sparkquest.sparkquest"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sparkquest.sparkquest"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val alias = envKeyAlias ?: keystoreProperties.getProperty("keyAlias")
            val keyPass = envKeyPassword ?: keystoreProperties.getProperty("keyPassword")
            val storePass = envStorePassword ?: keystoreProperties.getProperty("storePassword")
            val storePath = envKeystorePath ?: keystoreProperties.getProperty("storeFile")

            if (storePath != null && storePass != null) {
                val candidateFile = if (file(storePath).exists()) {
                    file(storePath)
                } else if (rootProject.file(storePath).exists()) {
                    rootProject.file(storePath)
                } else null

                if (candidateFile != null) {
                    storeFile = candidateFile
                    storePassword = storePass
                    keyAlias = alias
                    keyPassword = keyPass ?: storePass
                }
            }
        }
    }

    buildTypes {
        release {
            val relConfig = signingConfigs.getByName("release")
            if (relConfig.storeFile != null && relConfig.storeFile!!.exists()) {
                signingConfig = relConfig
            } else {
                throw GradleException(
                    "CRITICAL: Release build requested without a valid release keystore! " +
                    "Google Play Console rejects debug-signed bundles. " +
                    "Configure sparkquest_flutter/android/key.properties or set KEYSTORE_PATH, " +
                    "KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD environment variables."
                )
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
