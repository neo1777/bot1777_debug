# NeoTradingBot 1777 (Debug Repository)

This repository contains the complete source code for **NeoTradingBot 1777**, divided into two main components:

1. **Backend (`neotradingbotback1777`)**: The core trading logic, API integrations (Binance, Telegram), and strategy execution loop, built in Dart.
2. **Frontend (`neotradingbotfront1777`)**: The control panel UI, built in Flutter, communicating with the backend via gRPC.

## Status
✅ **Full Codebase Audit Completed**: The repository has undergone a comprehensive security and architectural audit (February 2026). All identified high-priority issues, including authentication bypass risks and order deduplication bugs, have been resolved.

## Directory Structure
- `neotradingbotback1777/`: Backend Dart Application
- `neotradingbotfront1777/`: Frontend Flutter Application
- `docs/`: Project documentation and research notes

## Setup Instructions

### Backend
1. Navigate to the backend directory: `cd neotradingbotback1777`
2. Fetch dependencies: `dart pub get`
3. Configure your API keys (via environment variables or secure configuration mechanisms). *Note: Ensure you never commit actual secrets.*
4. Run the backend server: `dart run bin/server.dart`

### Frontend
1. Navigate to the frontend directory: `cd neotradingbotfront1777`
2. Fetch dependencies: `flutter pub get`
3. Start the application: `flutter run` (Ensure the backend is running to avoid gRPC connection errors).

## Warning
This is the `bot1777_debug` repository intended for debugging and development. Ensure no actual trading API secrets or passwords are accidentally committed to this repository. All sensitive information should be excluded via `.gitignore`.

