import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase (telemetria): lê o google-services.json e sobe o mapping do R8.
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Assinatura de release. Duas fontes, nesta ordem:
//
//  1. android/key.properties (gitignored) — o que o CI recria a partir dos
//     secrets do GitHub (KEYSTORE_BASE64, STORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS).
//  2. variaveis de ambiente — o caminho da maquina local.
//
// A ordem 2 existe porque o contrato da 4YU (CLAUDE.md) proibe segredo DENTRO do
// repo, mesmo gitignored: um key.properties com a senha da keystore e um segredo
// em repouso na arvore do projeto, esperando um `git add -f` distraido. Com env,
// a senha nunca toca o disco do repo:
//
//   set -a && . /home/gabrielbarbosa/dev/gabriel/4yu-apps/.secrets/4yu.env && set +a
//   export QUANTOCOBRO_KEYSTORE_FILE=/home/gabrielbarbosa/dev/gabriel/4yu-apps/.secrets/quantocobro-upload.jks
//   flutter build apk --release
//
// Sem nenhuma das duas, o build cai na chave de debug: instala em aparelho pra
// teste, e a Play recusa.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// storeFile default: a keystore de upload vive no cofre compartilhado, fora de
// qualquer git. So o CAMINHO aparece aqui; a senha, nunca.
val envKeystoreFile: String? = System.getenv("QUANTOCOBRO_KEYSTORE_FILE")
val envKeystorePass: String? = System.getenv("QUANTOCOBRO_KEYSTORE_PASS")
val envKeyAlias: String? = System.getenv("QUANTOCOBRO_KEY_ALIAS")

// A env so vale se der pra assinar de verdade: caminho, senha e alias, e o
// arquivo existindo. Meio-caminho viraria erro no meio do build.
val assinaPorEnv = envKeystoreFile != null &&
    envKeystorePass != null &&
    envKeyAlias != null &&
    file(envKeystoreFile).exists()

val temAssinaturaRelease = keystorePropertiesFile.exists() || assinaPorEnv

android {
    namespace = "com.fouryuapps.quantocobro"
    // Plugins recentes (file_picker etc.) exigem compileSdk 36+.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fouryuapps.quantocobro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (temAssinaturaRelease) {
            create("release") {
                if (keystorePropertiesFile.exists()) {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                } else {
                    // A keystore de upload usa a MESMA senha pra store e pra
                    // chave (foi gerada assim, `.secrets/4yu.env`).
                    keyAlias = envKeyAlias
                    keyPassword = envKeystorePass
                    storeFile = file(envKeystoreFile!!)
                    storePassword = envKeystorePass
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temAssinaturaRelease) {
                signingConfigs.getByName("release")
            } else {
                // Sem keystore: chave de debug. Instala em aparelho pra teste,
                // a Play recusa.
                signingConfigs.getByName("debug")
            }

            // R8 ligado por padrao: encolhe o artefato e conta na nota de
            // "Otimizacao" da Play. Desligavel com -Pminify=false pra isolar
            // uma quebra de runtime — R8 nao falha o build, falha na tela.
            // As regras de keep estao em proguard-rules.pro.
            val minify = (project.findProperty("minify") as String?) != "false"
            isMinifyEnabled = minify
            isShrinkResources = minify
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
