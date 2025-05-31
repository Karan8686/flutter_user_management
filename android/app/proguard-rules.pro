# Keep network-related classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep http package classes
-keep class org.apache.http.** { *; }
-keep class org.apache.commons.** { *; }
-dontwarn org.apache.http.**
-dontwarn org.apache.commons.**

# Keep JSON-related classes
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }
-dontwarn com.google.gson.**
-dontwarn org.json.**

# Keep Flutter network-related classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep your model classes
-keep class com.example.assesment.features.** { *; }
-keep class com.example.assesment.core.** { *; }

# Keep Retrofit if you're using it
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}
-dontwarn retrofit2.**

# Keep Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Keep Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep your API client
-keep class com.example.assesment.core.api.** { *; } 