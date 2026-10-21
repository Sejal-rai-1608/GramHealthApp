# Jitsi Meet & WebRTC rules for Release APK to prevent crashing on other phones
-keep class org.webrtc.** { *; }
-keep class org.jitsi.meet.** { *; }
-keep class org.jitsi.meet.sdk.** { *; }
-keep class dev.saibotma.jitsi_meet_wrapper.** { *; }

# React Native rules (required by Jitsi SDK internally)
-keep class com.facebook.react.** { *; }
-keep class com.facebook.yoga.** { *; }
-keep class com.facebook.common.** { *; }
-keep class com.facebook.jni.** { *; }

# Standard Reflection safeguards for plugins
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepclassmembers class ** {
    @org.greenrobot.eventbus.Subscribe <methods>;
}

# MediaPipe tasks-genai pulls in AutoValue, which references javac's
# javax.lang.model compile-time API. Those classes are never present on
# Android, so silence R8's missing-class check for them.
-dontwarn javax.lang.model.SourceVersion
-dontwarn javax.lang.model.element.Element
-dontwarn javax.lang.model.element.ElementKind
-dontwarn javax.lang.model.type.TypeMirror
-dontwarn javax.lang.model.type.TypeVisitor
-dontwarn javax.lang.model.util.SimpleTypeVisitor8
