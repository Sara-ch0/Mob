# TARTIL - Premium Quran Audio Player 📖

TARTIL is a modern, elegant, and feature-rich Quran audio player application built with Flutter. It provides an immersive listening experience with synchronized Arabic verses, offline playback capabilities, detailed listening statistics, and a strict multi-account privacy architecture.

## ✨ Key Features

- **Immersive "Now Playing" Experience**: Beautiful full-screen player with synchronized, auto-scrolling Arabic verses that highlight as the reciter progresses.
- **Offline Downloads**: Download your favorite Surahs for offline listening. Downloads are strictly isolated per user account.
- **Advanced Favorites Library**: 
  - Save Surahs to your personal library.
  - Swipe-to-delete or use bulk selection mode.
  - **Biometric Security**: Removing a favorite requires fingerprint/face authentication to prevent accidental deletions.
- **Insight Dashboard**: Tracks your daily, weekly, and monthly listening time. Set monthly goals and visualize your progress with beautiful charts.
- **Multi-Account Isolation**: 
  - Downloads, daily reminders, and play histories are securely tied to the active user's Firebase UID.
  - Upon logout, the audio stops, notifications are cancelled, and the screen is cleared to protect your privacy if sharing the device.
- **Daily Reminders**: Set a custom daily push notification to remind you to listen to the Quran.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Auth**: Firebase (Authentication & Cloud Firestore)
- **Audio Playback**: `just_audio` & `audio_service` (for background playback and lock-screen controls)
- **State Management**: Standard Flutter state management with `ValueNotifier` for reactive streams.
- **Local Storage**: `shared_preferences` and `path_provider` for secure local caching.
- **Notifications**: `flutter_local_notifications`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version recommended)
- Android Studio / VS Code
- A Firebase project with Authentication (Email/Password) and Firestore enabled.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/tartil.git
   cd tartil
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   Make sure to generate and place the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) in their respective platform directories.

4. **Run the App:**
   ```bash
   flutter run
   ```

## 📂 Project Structure

- `lib/models/`: Data models (Surah, Reciter, etc.)
- `lib/screens/`: UI Views (Dashboard, Player, Library, Auth)
- `lib/services/`: Core logic and API layers
  - `audio_handler.dart`: Background audio execution
  - `auth_service.dart`: Firebase Authentication & Logout cleanup
  - `download_service.dart`: Handles offline saving and UID isolation
  - `firestore_service.dart`: Syncs stats and favorites to the cloud
  - `notification_service.dart`: OS-level scheduled reminders
  - `quran_api_service.dart`: Fetches Surahs and Ayahs from AlQuran Cloud
- `lib/utils/`: Theme data, colors, and global constants

## 🎨 Design System

TARTIL uses a premium dark theme (`AppTheme.darkTheme`) accented with a signature **Gold** color (`#D4AF37`) for highlights, active verses, and interactive elements. The UI relies heavily on glassmorphism, soft glows, and elegant typography to provide a serene user experience.

---
*Built with ❤️ for the Ummah.*
