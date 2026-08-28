# Expo HAS CHANGED

Read the exact versioned docs at https://docs.expo.dev/versions/v57.0.0/ before writing any code.

# STRICT PROJECT CONSTRAINTS
- **APK SIZE LIMIT**: The generated Android APK (`marakadhey_mobile.apk`) MUST ALWAYS be less than 20 MB.
  - Always build with: `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols`
  - Always copy the ARM64 release APK (`app-arm64-v8a-release.apk`) to `marakadhey_mobile.apk`.
- **ANDROID VERSION COMPATIBILITY**: Must support all Android versions, especially Android 10 (API 29) to Android 16 (API 36).
- **GIT SECURITY**: Never commit raw API keys, `.env`, or `google-services.json` to Git. Keep credentials isolated in `.gitignore`.
