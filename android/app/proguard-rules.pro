# Flutter Local Notifications ProGuard / R8 Rules

# Keep generic type signatures (prevents "Missing type parameter" crashes on Gson deserialization)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep Gson library classes and members
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Keep serialized names and Serializable classes intact
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    Object writeReplace();
    Object readResolve();
}

# Keep the plugin itself and its serializable models
-keep class com.dexterous.flutterlocalnotifications.** { *; }
