import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties()
if (releaseKeyPropertiesFile.exists()) {
    releaseKeyPropertiesFile.inputStream().use { releaseKeyProperties.load(it) }
}
val releaseSigningFields = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val hasReleaseSigning = releaseKeyPropertiesFile.exists() &&
    releaseSigningFields.all { !releaseKeyProperties.getProperty(it).isNullOrBlank() }

// Flutter forwards --dart-define-from-file as base64-encoded key/value pairs.
// Keep the native AdMob resource aligned with the private Dart configuration.
val releaseDartDefines = (project.findProperty("dart-defines") as? String)
    .orEmpty().split(",").filter { it.isNotBlank() }.mapNotNull { encoded ->
        runCatching { String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) }
            .getOrNull()?.let { entry ->
                if (entry.contains("=")) entry.substringBefore("=") to entry.substringAfter("=")
                else null
            }
    }.toMap()
val releaseAdMobAppId = releaseDartDefines["ADMOB_APP_ID"].orEmpty()
val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"

val requireReleaseSigning by tasks.registering {
    group = "verification"
    description = "Require private release signing configuration; never use the debug key."
    doLast {
        if (!Regex("ca-app-pub-[0-9]{16}~[0-9]{10}").matches(releaseAdMobAppId) ||
            releaseAdMobAppId == testAdMobAppId) {
            throw GradleException(
                "Release requires a production ADMOB_APP_ID in private dart defines. " +
                    "Use --dart-define-from-file=tool/release/monetization.json."
            )
        }
        if (!hasReleaseSigning) {
            throw GradleException(
                "Release signing is not configured. Add all required values to the private " +
                    "android/key.properties file. Debug builds remain available."
            )
        }
        if (!rootProject.file(releaseKeyProperties.getProperty("storeFile")).isFile) {
            throw GradleException("The release keystore is unavailable. Check private signing configuration.")
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(requireReleaseSigning)
}

android {
    buildFeatures {
        resValues = true
    }
    namespace = "id.arunika.arunika_growth"
    compileSdk = maxOf(36, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Diwajibkan oleh flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "id.arunika.arunika_growth"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = maxOf(36, flutter.targetSdkVersion)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = releaseKeyProperties["keyAlias"] as String
                keyPassword = releaseKeyProperties["keyPassword"] as String
                storeFile = rootProject.file(releaseKeyProperties["storeFile"] as String)
                storePassword = releaseKeyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        configureEach {
            if (name != "release") resValue("string", "admob_app_id", testAdMobAppId)
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            resValue("string", "admob_app_id", releaseAdMobAppId.ifBlank { testAdMobAppId })
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
