plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing configuration from key.properties
val keystoreFile = rootProject.file("key.properties")
val keyProperties = java.util.Properties()
if (keystoreFile.exists()) {
    keyProperties.load(keystoreFile.inputStream())
}

android {
    namespace = "id.pintarbisnis.pintarx"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // Application ID
        applicationId = "id.pintarbisnis.pintarx"
        
        // SDK Versions
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // Version Info (update these for each release)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing Configuration for Release
    signingConfigs {
        create("release") {
            keyAlias = keyProperties.getProperty("keyAlias", "upload")
            keyPassword = keyProperties.getProperty("keyPassword", "")
            storeFile = if (keyProperties.containsKey("storeFile")) {
                file(keyProperties.getProperty("storeFile"))
            } else {
                null
            }
            storePassword = keyProperties.getProperty("storePassword", "")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            // Sign release build with configured signing config
            signingConfig = signingConfigs.getByName("release")
        }
        
        debug {
        }
    }
}

// Override Kotlin compilation tasks to use Java 11
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.fragment:fragment:1.5.7")
}

