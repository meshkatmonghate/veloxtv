# ⚡ VeloxTV

> **The Ultra-Fast, Remote-First & Open-Source IPTV Player for Android TV, Android Mobile & Windows**

[![Build Android APK](https://github.com/YOUR_USERNAME/veloxtv/actions/workflows/build-android.yml/badge.svg)](https://github.com/YOUR_USERNAME/veloxtv/actions)
[![Build Windows Release](https://github.com/YOUR_USERNAME/veloxtv/actions/workflows/build-windows.yml/badge.svg)](https://github.com/YOUR_USERNAME/veloxtv/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20TV%20%7C%20Android%20%7C%20Windows-brightgreen.svg)](#)

---

## 📺 Why VeloxTV?

Most existing IPTV clients on the market fall into two extremes:
* **IPTV Smarters Pro & Clones:** Outdated 2015 UI, laggy navigation with large playlists, buggy stream recording, and awkward TV remote navigation.
* **TiviMate:** Excellent, but closed-source, Android TV only, and requires an expensive paid license.

**VeloxTV** was created to bridge this gap: a modern, open-source, lightning-fast IPTV player built specifically with **Remote-First (D-Pad)** navigation in mind, zero bloat, and full cross-platform support.

---

## ✨ Key Features

* **⚡ Ultra-Fast Core Engine (Rust & Dart):** Instant channel switching and zero-freeze parsing for large M3U playlists (100k+ channels).
* **🎮 Remote-First (10-Foot UI):** Built from scratch for Android TV remotes and game controllers. Neon glow focus indicator, smooth scale animations, and intuitive D-pad navigation.
* **🔴 Live Stream Recording (DVR):** Record live TV streams directly to local storage in the background without interrupting your current playback.
* **🛡️ Real Parental Control:**
  * 4-digit PIN security dialog.
  * SHA-256 hashed password storage.
  * Automatic detection and locking for adult categories (`XXX`, `18+`, `Adult`, `Porn`).
* **👁️ Category & Privacy Manager:**
  * Bulk **Hide / Unhide** unwanted channel bouquets and foreign languages.
  * Lock specific categories behind PIN codes.
* **⭐ Favorites & History:**
  * Quick star/favorite toggle directly inside the player overlay or grid.
  * Instant access to recently watched channels.
  * Resume playback timestamp tracking for VOD movies and series.
* **🎬 High-Performance Video Engine (`libmpv`):**
  * Hardware-accelerated decoding.
  * Native support for `MPEG-TS`, `HLS (.m3u8)`, `MKV`, `MP4`, `RTMP`.
  * Multi-audio track switching (including Dolby Digital / AC3 / E-AC3) and subtitle support.
  * Quick aspect ratio cycle (`16:9`, `Fill`, `Zoom`).
* **🌐 Dual Protocol Support:**
  * **Xtream Codes API:** Live TV, VOD Movies, Series, and EPG.
  * **M3U / M3U8 Playlists:** Import via direct URL or local file with automatic metadata parsing (`tvg-id`, `tvg-logo`, `group-title`).

---

## 🏗️ Architecture

```
veloxtv/
├── core_engine/                 # High-performance Rust engine
│   ├── src/
│   │   ├── xc_client.rs         # Xtream Codes API protocol implementation
│   │   ├── m3u_parser.rs        # Memory-efficient streaming M3U parser
│   │   ├── recorder.rs          # Background HTTP chunk stream writer
│   │   ├── security.rs          # Parental control PIN hashing & rule engine
│   │   └── models.rs            # Clean data types
│   └── Cargo.toml
├── lib/                         # Remote-First Flutter Frontend
│   ├── tv/                      # Android TV Focus & D-Pad components
│   │   ├── tv_focusable.dart    # Neon glow & scale-up focus wrapper
│   │   ├── tv_card.dart         # TV channel cards and VOD posters
│   │   └── tv_sidebar.dart      # 10-foot navigation sidebar
│   ├── services/                # Storage, Xtream, M3U & Recording services
│   ├── screens/                 # Dashboard, Live Player, Settings, PIN dialog
│   └── main.dart
└── .github/workflows/           # Automated Cloud Builds (APK & Windows Exe)
```

---

## 🚀 Automated Builds via GitHub Actions

You don't need to install 50 GB of Android SDK, NDK, and Gradle on your computer!

1. Fork or push this repository to your GitHub account.
2. Go to the **Actions** tab in your GitHub repository.
3. Every time you push a commit or create a Git tag (e.g. `v1.0.0`), GitHub automatically builds:
   * **`VeloxTV-Android-Release.apk`** (Ready to install on Android TV & phones).
   * **`VeloxTV-Windows-x64.zip`** (Portable executable for Windows).
4. Download the `.apk` from the **Releases** page and install it on your TV with any file manager or adb!

---

## 💻 Local Development

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
* [Rust & Cargo](https://rustup.rs/) (Optional, for core engine development)

### Run on Windows
```bash
flutter pub get
flutter run -d windows
```

### Build APK locally
```bash
flutter build apk --release
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
