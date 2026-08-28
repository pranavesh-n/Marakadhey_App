# PROJECT RULES & CONSTRAINTS

1. **APK Size**: Must ALWAYS remain strictly **< 20 MB**.
   - Build command: `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols`
   - Copy `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` to `marakadhey_mobile.apk`.
2. **Android OS Support**: Android 10 to 16 compatibility across all features.
3. **Secret Isolation**: Never expose secrets or API keys in git tracking.
