plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Google Services plugin
}

kotlin {
    jvmToolchain(17)
}
    // mobile_ai_utility_app (Removed)

    android {
        namespace = "com.example.mobile_ai_utility_app"
        compileSdk = 36
        ndkVersion = "27.0.12077973" // replace with flutter.ndkVersion if needed

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        kotlinOptions {
            jvmTarget = "17"
        }

    defaultConfig {
        applicationId = "com.example.mobile_ai_utility_app" // Must match Firebase app
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // your flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
        }
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
}
