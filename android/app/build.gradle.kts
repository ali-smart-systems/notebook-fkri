plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.notebook_fkri"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

            defaultConfig {
        applicationId = "com.example.notebook_fkri"
        // التعديل الجديد المتوافق مع KTS
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }



    buildTypes {
        getByName("release") {
            // أضف إعدادات التوقيع هنا إذا كانت موجودة سابقاً
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
android {
    ndkVersion = "28.2.13676358"
    // باقي الإعدادات...
}
flutter {
    source = "../.."
}
