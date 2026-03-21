# 🙏 Prayer Walk Tracker — Flutter

A production-ready Flutter app for tracking prayer walks on a live GPS map. Built with Supabase, Google Maps, and a beautiful dark UI.

---

## 📱 Screens

| Screen | Description |
|---|---|
| **Auth** | Email/password login + signup via Supabase |
| **Dashboard** | Full-screen dark Google Map showing all users' walks as green polylines |
| **Active Walk** | Live GPS tracking — blue polyline, timer, distance, pace |
| **Profile** | Personal stats + recent walk history |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter + Dart |
| Auth & DB | Supabase (`supabase_flutter`) |
| Maps | Google Maps (`google_maps_flutter`) |
| GPS | `geolocator` |
| State | `provider` |
| Env | `flutter_dotenv` |

---

## 🚀 Setup

### 1. Install Flutter

Download and install Flutter SDK from https://docs.flutter.dev/get-started/install

Verify:
```bash
flutter doctor
```

### 2. Initialize the Native Project

The `android/` and `ios/` directories need Flutter's generated files. Run:

```bash
cd prayer
flutter create . --project-name prayer_walk --org com.prayerwalk --platforms android,ios
```

> This generates `MainActivity.kt`, Xcode project files, etc. **Your source files will NOT be overwritten.**

### 3. Configure Environment

The `.env` file already has your Supabase credentials. Just add your Google Maps key:

```env
SUPABASE_URL=https://zzhvuoylsanybhcvxtsq.supabase.co
SUPABASE_ANON_KEY=<already set>
GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

### 4. Add Google Maps API Keys

**Get a key:** [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Enable *Maps SDK for Android* + *Maps SDK for iOS*

**Android** — edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_KEY"/>
```

**iOS** — edit `ios/Runner/Info.plist`:
```xml
<key>GMSApiKey</key>
<string>YOUR_IOS_KEY</string>
```

### 5. Install Packages

```bash
flutter pub get
```

### 6. Run Supabase Schema

Open your Supabase project → SQL Editor → paste and run `supabase/schema.sql`.

### 7. Run the App

```bash
# Android device/emulator
flutter run

# iOS simulator (macOS only)
flutter run -d ios

# Release build
flutter build apk          # Android
flutter build ios          # iOS
```

---

## 📂 Project Structure

```
prayer/
├── lib/
│   ├── main.dart                   ← App entry + auth gate
│   ├── core/
│   │   ├── theme.dart              ← Dark theme + colors
│   │   └── map_style.dart          ← Dark Google Maps JSON style
│   ├── models/
│   │   ├── coordinate.dart
│   │   └── walk.dart
│   ├── providers/
│   │   ├── auth_provider.dart      ← Supabase auth state
│   │   └── walks_provider.dart     ← Walks CRUD + Realtime
│   ├── utils/
│   │   └── distance.dart           ← Haversine + formatters
│   └── screens/
│       ├── auth_screen.dart
│       ├── dashboard_screen.dart
│       ├── active_walk_screen.dart
│       └── profile_screen.dart
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml     ← Permissions + Maps key
├── ios/
│   └── Runner/
│       ├── AppDelegate.swift
│       └── Info.plist              ← Permissions + Maps key
├── supabase/
│   └── schema.sql                  ← DB schema + RLS policies
├── pubspec.yaml
└── .env                            ← Supabase + Maps keys
```

---

## 🗺️ Map Colors

| Color | Meaning |
|---|---|
| 🔵 Indigo polyline | Your current active walk |
| 🟢 Green polylines | All completed global walks |
| 🔵 Blue dot | Your real-time location |

---

## 🔒 Security

Row-Level Security is enforced in Supabase:
- **Read**: everyone can see all walks (global map)
- **Write**: users can only insert/update/delete their own walks
