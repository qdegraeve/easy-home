import java.util.Properties

plugins {
    id("com.android.application")
}

// URL of the Rails app. In debug, the phone reaches the Rails server of the Mac through the USB cable
// (`adb reverse tcp:3000 tcp:3000`), hence localhost. Override with `easyhome.baseUrl=...` in local.properties
// (never committed). The release URL comes with the deployment (roadmap, step 4).
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

    buildTypes {
        debug {
            buildConfigField(
                "String",
                "BASE_URL",
                "\"${localProperties.getProperty("easyhome.baseUrl", "http://localhost:3000")}\""
            )
        }
        release {
            isMinifyEnabled = false
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
}
