import java.util.Properties

plugins {
    id("com.android.application")
}

// Firebase (push notifications, ADR 0012): its configuration, app/google-services.json, is downloaded from the
// Firebase console and never committed. Without it (CI, a fresh clone), the app builds without Firebase and says it
// cannot receive notifications.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// URL of the Rails app. In debug, the phone reaches the Rails server of the Mac through the USB cable
// (`adb reverse tcp:3000 tcp:3000`), hence localhost. Override with `easyhome.baseUrl=...` in local.properties
// (never committed). In release, the production URL comes from `easyhome.releaseUrl` in the same file.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "app.easyhome.android"
    compileSdk = 37

    defaultConfig {
        applicationId = "app.easyhome.android"
        minSdk = 28
        targetSdk = 37
        versionCode = 1
        versionName = "0.1.0"
    }

    // Release signing key: kept outside the repository, configured in local.properties. Without it (CI), the
    // release build stays unsigned instead of failing.
    signingConfigs {
        create("release") {
            val store = localProperties.getProperty("easyhome.signing.storeFile")
            if (store != null) {
                storeFile = file(store)
                storePassword = localProperties.getProperty("easyhome.signing.storePassword")
                keyAlias = localProperties.getProperty("easyhome.signing.keyAlias")
                keyPassword = localProperties.getProperty("easyhome.signing.keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            // A separate app on the phone, so the test and production versions can be installed side by side.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            buildConfigField(
                "String",
                "BASE_URL",
                "\"${localProperties.getProperty("easyhome.baseUrl", "http://localhost:3000")}\""
            )
        }
        release {
            isMinifyEnabled = false
            if (localProperties.getProperty("easyhome.signing.storeFile") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
            buildConfigField(
                "String",
                "BASE_URL",
                "\"${localProperties.getProperty("easyhome.releaseUrl", "https://easyhome.invalid")}\""
            )
        }
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("dev.hotwire:core:1.4.1")
    implementation("dev.hotwire:navigation-fragments:1.4.1")
    implementation("com.google.android.material:material:1.14.0")
    implementation(platform("com.google.firebase:firebase-bom:35.2.0"))
    implementation("com.google.firebase:firebase-messaging")
}
