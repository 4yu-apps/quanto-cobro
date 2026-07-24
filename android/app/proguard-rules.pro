# Regras R8/ProGuard do release. Objetivo: encolher o artefato sem quebrar em runtime.
#
# R8 quebrado NAO aparece no build; aparece quando o usuario abre a tela que usa a
# classe removida. Por isso cada bloco aqui existe por um motivo concreto, nao
# "por garantia".
#
# Escopo real: R8 mexe em bytecode JVM (Java/Kotlin). O codigo Dart vira AOT
# nativo e NAO passa por aqui. Consequencia pratica pra este app: a GERACAO do
# PDF (pacote `pdf`, pure-Dart) e imune a R8. Quem pode quebrar no fluxo da
# proposta e o `share_plus`, que tem lado Kotlin (FileProvider + activity result).
#
# Aplicado por android/app/build.gradle.kts (proguardFiles no buildType release).

# ---------------------------------------------------------------------------
# Flutter engine + embedding. Reflexao interna do io.flutter; sem isso os plugins
# param de registrar e o app sobe sem os canais nativos.
# ---------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ---------------------------------------------------------------------------
# Play Core / deferred components. O Flutter referencia essas classes mesmo o app
# nao usando split. Sem o dontwarn, R8 falha o build com "missing_rules".
# ---------------------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---------------------------------------------------------------------------
# share_plus: entrega o PDF da proposta no WhatsApp. Depende do FileProvider do
# AndroidX e do retorno da activity de compartilhamento. E o unico ponto do
# fluxo da proposta que R8 alcanca (o resto e Dart).
# ---------------------------------------------------------------------------
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keep class * extends androidx.core.content.FileProvider { *; }

# ---------------------------------------------------------------------------
# file_picker: usa reflexao no lado nativo pra resolver o content resolver.
# ---------------------------------------------------------------------------
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# ---------------------------------------------------------------------------
# Play Billing (in_app_purchase): a assinatura Pro. Sem isso, comprar/restaurar
# quebra em runtime — e quebra depois de o usuario tocar em "Assinar".
# ---------------------------------------------------------------------------
-keep class com.android.billingclient.api.** { *; }
-dontwarn com.android.billingclient.api.**

# ---------------------------------------------------------------------------
# drift / sqlite3_flutter_libs: a lib nativa e .so (R8 nao toca), mas o loader
# JNI resolve simbolos por nome. Manter evita "library not found" em runtime.
# ---------------------------------------------------------------------------
-keep class com.tekartik.sqflite.** { *; }
-dontwarn org.sqlite.**

# ---------------------------------------------------------------------------
# Firebase (Crashlytics + Analytics). O plugin crashlytics sobe o mapping.txt
# sozinho; estas regras mantem o stack trace legivel e evitam R8 remover classes
# resolvidas por reflexao. gms.** cobre o transporte do Analytics.
# ---------------------------------------------------------------------------
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# flutter_local_notifications (F7): o plugin serializa os detalhes da notificação
# agendada com Gson; sem manter suas classes, o R8 as renomeia e o agendamento
# quebra em runtime (release), não no build.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ---------------------------------------------------------------------------
# NAO tem aqui, de proposito (ver 11-HANDOFF.md §6): AdMob, Maps, ML Kit,
# foreground service. Billing entra quando o in_app_purchase entrar — a regra e
# -keep class com.android.billingclient.api.** { *; }.
# ---------------------------------------------------------------------------
