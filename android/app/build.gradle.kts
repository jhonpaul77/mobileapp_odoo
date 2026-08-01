import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Membaca konfigurasi signing dari android/key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}

android {
    namespace = "id.pintarbisnis.pintarx"
    compileSdk = flutter.compileSdkVersion

    // Pakai NDK yang sudah tersedia di D:\Android\ndk
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "salespro.nextnusantara.com"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")

            val keystorePath =
                keystoreProperties.getProperty("storeFile")

            if (!keystorePath.isNullOrBlank()) {
                storeFile = rootProject.file(keystorePath)
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Debug mode - no minification (lebih cepat build)
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // Release mode - disable minification to avoid NDK/stripping issues
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Menyamakan target Kotlin dengan Java 11.
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
    .configureEach {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            )
        }
    }

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.fragment:fragment:1.5.7")
}