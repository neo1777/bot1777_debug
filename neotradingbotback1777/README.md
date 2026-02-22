# NeoTradingBot Backend

The backend engine for NeoTradingBot, responsible for handling real-time market data, executing trading strategies, computing performance metrics, and exposing a gRPC interface for the frontend control panel.

## Features
- Scalable gRPC server architecture.
- Modular trading strategy engine.
- Integrated Binance API connector for tracking market prices.
- Background execution loop for continual trading operations.

## Running the Server
```bash
# Fetch dependencies
dart pub get

# Run the backend server
dart run bin/server.dart
```

## Testing
To run the automated test suite for the backend:
```bash
dart test
```
