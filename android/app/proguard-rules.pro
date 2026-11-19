# Aturan R8 untuk build release SodiScan.
# flutter_local_notifications menyimpan jadwal notifikasi memakai Gson (refleksi).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.errorprone.annotations.**
