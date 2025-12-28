# Master Checkers AI

A premium Checkers (Draughts) application built with Flutter, featuring:

- 🤖 **AI Opponent** - Powered by Google Gemini
- 🌐 **Online Multiplayer** - Real-time matchmaking
- 👥 **Pass & Play** - Local two-player mode
- 🏆 **Leaderboard** - Global rankings
- 👫 **Friend System** - Add friends and challenge them
- 🎨 **Chess.com Theme** - Beautiful dark UI

## Game Variants

- **American (Standard)** - Classic checkers rules
- **Brazilian** - Flying kings, men capture backwards

## Setup

### Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run automated Firebase setup (recommended)
bash setup_firebase.sh

# 3. Run the app
flutter run
```

### Manual Firebase Setup

If you prefer manual configuration or need detailed instructions:

1. **Read the complete guide:** [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

2. **Quick steps:**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Google Sign-In)
   - Create a Realtime Database
   - Run `firebase login`
   - Run `flutterfire configure`

3. **Configure Gemini API** (for AI opponent):
   - Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Set environment variable or add to app configuration

## Firebase Setup

The app uses Firebase for:
- **Authentication** - Email/Password, Google Sign-In, Email Link (passwordless)
- **Realtime Database** - User profiles, game data, leaderboard, friends
- **Security Rules** - Configured for multi-user access control

**⚠️ Important:** The current `firebase_options.dart` contains placeholder values. You MUST configure your own Firebase project for the app to work.

## Tech Stack

- Flutter 3.x
- Firebase Auth & Realtime Database
- Google Generative AI (Gemini)
- Provider for state management
