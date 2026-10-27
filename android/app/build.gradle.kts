import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials: placeholders only, never commit real secrets.
// Resolution order per key: local.properties -> environment variable.
// See SIGNING_SETUP.md for the user-run setup commands.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("local.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
fun keystoreProp(name: String, env: String): String? =
    (keystoreProperties.getProperty(name) as String?)
        ?.takeIf { it.isNotBlank() && !it.startsWith("<") }
        ?: System.getenv(env)?.takeIf { it.isNotBlank() }

val keystoreFile: String? = keystoreProp("keystore.file", "KEYSTORE_FILE")
val keystorePassword: String? = keystoreProp("keystore.password", "KEYSTORE_PASSWORD")
val keyAlias: String? = keystoreProp("key.alias", "KEY_ALIAS")
val keyPassword: String? = keystoreProp("key.password", "KEY_PASSWORD")
val hasReleaseSigning = !keystoreFile.isNullOrBlank()
    && !keystorePassword.isNullOrBlank()
    && !keyAlias.isNullOrBlank()
    && !keyPassword.isNullOrBlank()
    && rootProject.file(keystoreFile!!).exists()

android {
    namespace = "com.indianludo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(keystoreFile!!)
                storePassword = keystorePassword
                keyAlias = keyAlias
                keyPassword = keyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.indianludo.app"
        // Versioning: versionName/versionCode come from pubspec.yaml
        // (`version: 1.0.0+1` -> versionName 1.0.0, versionCode 1).
        // Bump the build number (+N) for every Play upload; versionCode must
        // always increase. Override per-build with:
        //   flutter build appbundle --build-name=1.0.1 --build-number=2
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // No keystore configured: debug keys so `flutter run --release`
                // works. Release uploads REQUIRE a configured keystore.
                signingConfigs.getByName("debug")
            }
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
