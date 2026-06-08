# flutter_local_notifications + Gson: R8 strips generic type info that
# the plugin's loadScheduledNotifications() relies on, which makes cancel()
# throw "Missing type parameter." in release builds. Keep the plugin
# classes and Gson reflection metadata so deserialization works.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
