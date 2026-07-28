# App-specific R8 rules.
#
# NOTE: the Flutter tooling already injects keep rules for the Flutter engine
# and every registered plugin, so broad `-keep class io.flutter.** { *; }`
# rules are unnecessary and defeat code shrinking (they inflate the APK).

# Flutter deferred-components / Play Core references (not used by this app,
# but the engine mentions them; silence R8 warnings instead of keeping them).
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.**
