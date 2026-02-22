# NeoTradingBot Frontend

This is the control panel and visualization interface for **NeoTradingBot 1777**, built with Flutter. It connects to the Dart backend via gRPC to provide real-time metrics, configuration of api keys, and monitoring of active trading loops.

## Features
- Real-time dashboard showing account balance, open orders, and strategy performance.
- Log viewer to trace the trading engine's backend events.
- Configuration pages for API keys and Telegram bot integration.

## Setup & Running
To run the web, desktop, or mobile version of the frontend:
```bash
# Fetch dependencies
flutter pub get

# Generate gRPC bindings (if necessary)
# Add steps here to run protoc if needed

# Run the app (ensure backend is already running)
flutter run
```

## Testing
To run the automated test suite for the frontend:
```bash
flutter test
```

