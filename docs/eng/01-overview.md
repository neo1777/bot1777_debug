# System Overview - NeoTradingBot 1777

## Overview
NeoTradingBot 1777 is an automated trading system based on DCA (Dollar Cost Averaging) strategies with advanced risk management and real-time monitoring. The system is composed of a backend in Dart and a frontend in Flutter for management and strategy monitoring.

## System Architecture

### Backend (neotradingbotback1777)
- **Language**: Dart
- **Communication**: gRPC (real-time stream)
- **Database**: Hive (NoSQL, fast local persistence)
- **Trading Engine**: Atomic execution in dedicated isolates.
- **Modular Components**:
    - `TradingSignalAnalyzer`: Decoupled logic for evaluating Buy, Sell, and DCA signals.
    - `AtomicActionProcessor`: Orchestrates the execution of trading actions and state synchronization.
- **Risk Management**: Volatility-aware price freezing and intelligent trade evaluation.

### Frontend (neotradingbotfront1777)
- **Framework**: Flutter
- **State Management**: BLoC / Cubit
- **Navigation**: GoRouter
- **DI**: GetIt
- **UI Components**: Modern design with responsive layouts for mobile and desktop.

## Key Features
1. **DCA Strategy**: Multi-tier buying strategy with configurable intervals and multiplier.
2. **Volatility Control**: System prevents buying/selling during extreme market conditions via the `VolatilityService`.
3. **Fee-Aware Trading**: Calculates Take Profit and targets by considering exchange fees.
4. **Security**: Mandatory TLS and Certificate Pinning for production environments.
5. **Recovery**: Checkpoint system to resume trading state after restart/crash.
6. **Health Monitoring**: Real-time server status visibility in the dashboard.

