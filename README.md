# ⏰ Marakadhey (மறக்காதே) — Never Miss Opportunities

<div align="center">
  <img src="marakadhey_flutter/assets/logo.png" width="100" height="100" alt="Marakadhey Logo" />
  <br />
  <strong>The Ultimate Opportunity Tracker & High-Reliability Deadline Manager for Students & Professionals</strong>
  <p>Never miss another internship application, hackathon deadline, coding contest, scholarship, or webinar registration.</p>
</div>

---

## 🌟 Overview

**Marakadhey** (Tamil for *"Do Not Forget"*) is a purpose-built opportunity tracking ecosystem designed to solve the critical problem of missed deadlines and forgotten applications. 

Whether you discover opportunities through WhatsApp groups, LinkedIn, Telegram, Discord, or campus portals, Marakadhey allows you to capture them instantly via Android native share targets or manual entry, schedule guaranteed full-screen wake alarms, and track your application lifecycle end-to-end.

---

## 🚀 Key Features

### 1. 🚨 Zero-Latency, Doze-Exempt Deadline Alarms
- **Guaranteed Ringing on Locked Screens:** Built on native Android `AlarmManager.setAlarmClock()` and full-screen intent receivers (`USE_FULL_SCREEN_INTENT`), ensuring alarms ring on time even in battery-saving Doze mode.
- **Ringing Alarm Screen:** 
  - Vivid category tags and opportunity details.
  - One-tap **"🌐 Open Application Link"** to launch directly into the job/contest application portal.
  - Flexible **Quick Snooze Chips** (`5m`, `10m`, `15m`, `30m`).
  - Emergency turn-off and interactive notification banners.

### 2. ⚡ Android Native Share Target
- Share opportunity URLs and text directly from **LinkedIn, WhatsApp, Chrome, or Twitter/X** into Marakadhey.
- Automatic URL and opportunity title extraction with instant pre-filling.

### 3. 🛡️ Sikkanam-Style Screen Lock & Biometrics
- Sleek 4-digit PIN authentication with haptic feedback and error animations.
- Optional fingerprint / face unlock via Android BiometricPrompt (`local_auth`).
- Configurable auto-lock timeout (Immediate, 1 min, 5 min, 15 min).
- Safe recovery and reset flow.

### 4. 🔄 Extension Workflow Automation
- **Mark Completed on Open:** Automatically marks opportunities as completed when tapping "Open Link".
- **Clean Inbox View:** Filter completed items while keeping them indexed under the *Completed* tab.
- **Auto-Delete 90-Day Old Archive:** Automatic garbage collection for completed opportunities older than 90 days to keep the database lightweight.

### 5. 📦 Seamless Backup, Restore & JSON Transfer
- **1-Click Export:** Export all opportunities as structured JSON.
- **Universal Import:** Compatible with wrapped schemas and raw lists with per-item validation.
- **Clipboard Sync:** Copy/paste JSON directly for fast device-to-device migration.

### 6. 🪶 Ultra-Lightweight & Optimized Binary
- Compact **19.5 MB** release APK (down from 57+ MB).
- Multi-ABI splits supporting Android 5.0 (Lollipop) all the way up to Android 15 & 16.
- Tree-shaken icons and obfuscated release symbols.

---

## 📂 Project Architecture

```
marakadhey_app/
├── marakadhey_mobile.apk          # Production Release APK (~19.5 MB)
├── marakadhey_flutter/            # Flutter Cross-Platform Client
│   ├── android/                   # Native Android Engine (Kotlin)
│   │   ├── app/src/main/kotlin/com/marakadhey/app/
│   │   │   ├── MainActivity.kt        # Native MethodChannel & Share Receiver
│   │   │   ├── AlarmReceiver.kt       # High-priority WakeLock BroadcastReceiver
│   │   │   ├── AlarmActivity.kt       # Full-screen Ringing Alarm Screen
│   │   │   ├── AlarmSnoozeReceiver.kt # Notification Action Snooze Handler
│   │   │   └── AlarmSoundPlayer.kt    # Ringtone & Audio Focus Manager
│   ├── lib/
│   │   ├── models/                # Opportunity & Category Data Models
│   │   ├── providers/             # OpportunityProvider State Management
│   │   ├── screens/               # Inbox, Add Opportunity, Settings, PIN Lock
│   │   ├── services/              # Notification, Storage, Security & Auth
│   │   └── widgets/               # Opportunity Cards, Stats, Headers, Chips
│   └── test/                      # Automated Unit & Integration Tests
└── src/                           # Web & Extension Integration Specs
```

---

## 🛠️ Tech Stack

- **Mobile Framework:** [Flutter](https://flutter.dev/) (Dart 3.x)
- **Native Android:** Kotlin, Android `AlarmManager`, `KeyguardManager`, `NotificationManager`
- **State Management:** Provider Architecture
- **Local Persistence:** SharedPreferences & Secure Storage
- **Authentication:** Firebase Auth & Google Sign-In with Offline Fallback
- **Audio & Haptics:** Native Android MediaPlayer & Vibration Services

---

## ⚡ Getting Started & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.29+)
- Android SDK (API Level 21 to 35)

### Build and Run Locally
```bash
# 1. Navigate to flutter project
cd marakadhey_flutter

# 2. Get dependencies
flutter pub get

# 3. Run on connected Android device / emulator
flutter run

# 4. Build optimized Release APK (<20 MB)
flutter build apk --split-per-abi --release --obfuscate --split-debug-info=build/app/outputs/symbols --tree-shake-icons
```

---

## 📄 License
Designed and developed for students and career seekers worldwide.
*Don't lose opportunities. Keep tracking with Marakadhey.*
