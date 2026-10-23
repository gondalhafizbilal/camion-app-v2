import java.util.Properties
import java.io.FileInputStream
import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension


plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

fun readEnvFile(envFile: File): Map<String, String> {
    if (!envFile.exists()) return emptyMap()
    return envFile.readLines()
        .map { it.trim() }
        .filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
        .associate { line ->
            val idx = line.indexOf("=")
            val key = line.substring(0, idx).trim()
            val value = line.substring(idx + 1).trim()
            key to value
        }
}

val requestedTasks = gradle.startParameter.taskNames.joinToString(" ").lowercase()
val selectedEnvFile = if (requestedTasks.contains("development")) {
    rootProject.file("../.env.development")
} else {
    rootProject.file("../.env.production")
}
val env = readEnvFile(selectedEnvFile)

val facebookAppId = (env["FACEBOOK_APP_ID"]
    ?: localProperties.getProperty("facebook.appId")
    ?: System.getenv("FACEBOOK_APP_ID")
    ?: "").trim()
val facebookClientToken = (env["FACEBOOK_CLIENT_TOKEN"]
    ?: localProperties.getProperty("facebook.clientToken")
    ?: System.getenv("FACEBOOK_CLIENT_TOKEN")
    ?: "").trim()
val tiktokAppSecret = (env["TIKTOK_APP_SECRET"]
    ?: localProperties.getProperty("tiktok.appSecret")
    ?: System.getenv("TIKTOK_APP_SECRET")
    ?: "").trim()
val tiktokTTAppId = (env["TIKTOK_TT_APP_ID"]
    ?: localProperties.getProperty("tiktok.ttAppId")
    ?: System.getenv("TIKTOK_TT_APP_ID")
    ?: "").trim()

android {
    namespace = "com.camiontrading.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_11
//        targetCompatibility = JavaVersion.VERSION_11
//    }
//
//    kotlinOptions {
//        jvmTarget = JavaVersion.VERSION_11.toString()
//    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.camiontrading.app"
//        applicationId = "com.quality.camion"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["facebookAppId"] = facebookAppId
        manifestPlaceholders["facebookClientToken"] = facebookClientToken

        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
        resValue("string", "tiktok_app_secret", tiktokAppSecret)
        resValue("string", "tiktok_tt_app_id", tiktokTTAppId)
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = false
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("development") {
            dimension = "environment"
            applicationId = "com.camion.development"
            versionNameSuffix = "-dev"
            resValue(
                type = "string",
                name = "app_name",
                value = "Camion Development",
            )
        }
        create("production") {
            dimension = "environment"
            applicationId = "com.camiontrading.app"
            resValue(
                type = "string",
                name = "app_name",
                value = "Camion",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.github.tiktok:tiktok-business-android-sdk:1.6.1")
    implementation("androidx.lifecycle:lifecycle-process:2.3.1")
    implementation("androidx.lifecycle:lifecycle-common-java8:2.3.1")
    implementation("com.android.billingclient:billing:8.3.0")
    implementation("com.android.installreferrer:installreferrer:2.2")
}
