# Keep Google Mobile Ads SDK classes
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.ads.identifier.** { *; }

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# flutter_local_notifications - keeps reflection-based serialization classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# home_widget - keeps plugin classes
-keep class es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**

# sqflite - keeps database access classes
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# audible (audioplayers) - keeps audio plugin classes
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# in_app_review
-keep class com.google.android.play.core.review.** { *; }
-dontwarn com.google.android.play.core.review.**

# in_app_update
-keep class com.google.android.play.core.appupdate.** { *; }
-dontwarn com.google.android.play.core.appupdate.**

# Keep the app's own package classes (avoids issues with ProGuard stripping)
-keep class com.dreamstarx.mita.** { *; }
-keepclassmembers class com.dreamstarx.mita.** { *; }

# Keep generic signatures & annotations for reflection-based libraries
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes MethodParameters

# Keep model classes used with reflection / serialization
-keep class com.dreamstarx.mita.MainActivity { *; }
-keep class com.dreamstarx.mita.HomeWidgetProvider { *; }
-keep class com.dreamstarx.mita.WidgetActionReceiver { *; }
