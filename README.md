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

1. Install Flutter SDK
2. Run `flutter pub get`
3. Configure Firebase:
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
4. Set up Gemini API key in environment
5. Run `flutter run`

## Firebase Setup

The app uses Firebase for:
- Authentication (Email/Password, Google, Email Link)
- Realtime Database (User data, matches, leaderboard)

## Tech Stack

- Flutter 3.x
- Firebase Auth & Realtime Database
- Google Generative AI (Gemini)
- Provider for state management
