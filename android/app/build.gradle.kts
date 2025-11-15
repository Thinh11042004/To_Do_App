plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter plugin phải sau Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Google services (áp dụng đúng 1 lần ở module app)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.to_do_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.to_do_app"

        // minSdk 23 (hoặc theo flutter.minSdkVersion nhưng không thấp hơn 23)
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Bật desugaring + dùng JDK 17
    compileOptions {
        // Dự án Flutter hiện đại yêu cầu Java 17
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // RẤT QUAN TRỌNG cho flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // demo: dùng keystore debug. Khi phát hành thì thay bằng signingConfig riêng.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔧 Thư viện desugaring cho Java 8+ API trên minSdk thấp
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Nếu bạn đang dùng Firebase (Auth/Firestore/Messaging...), khuyến nghị dùng BOM:
    // implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    // rồi khai báo từng SDK không kèm version, ví dụ:
    // implementation("com.google.firebase:firebase-analytics")
    // implementation("com.google.firebase:firebase-messaging")
}
