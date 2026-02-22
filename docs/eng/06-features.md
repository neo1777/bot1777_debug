# Enterprise Features - NeoTradingBot 1777

This document details the advanced features implemented to ensure production-grade reliability and performance.

## 1. Volatility Control System
The system implements a `VolatilityService` that monitors market conditions using Standard Deviation calculations.

- **Objective**: Prevent "catching falling knives" by freezing trading activities during high volatility.
- **Implementation**:
    - **Price Freezing**: When volatility exceeds the configured threshold, the average price is "frozen" to prevent the bot from chasing irrational price movements.
    - **Thresholds**: `VOLATILITY_FREEZE_THRESHOLD` (5%) and `VOLATILITY_UNFREEZE_THRESHOLD` (3%).
- **Files**: `neotradingbotback1777/lib/infrastructure/services/volatility_service_impl.dart`

## 2. Fee-Aware Trading
Implemented to solve the problem of "invisible" losses due to exchange fees eating into DCA profits.

- **Calculation Strategy**:
    - Uses `FeeAwareCalculationService` to compute the target Take Profit price.
    - **Formula**: `target = average_price * (1 + profit_target + fee) / (1 - fee)`
- **Integration**:
    - Automatically fetches real-time fees from Binance.
    - Updates UI targets dynamically based on maker/taker status.

## 3. Log Optimizations & Dust Management
Fixes critical spam and operational issues identified during initial deployment.

- **Dust Management**: Prevents high-frequency loop attempts to sell quantities below the exchange's minimum limit (`DUST_UNSELLABLE`).
- **Log Suppression**: Reduces noisy "SELL decision with fees" logs to avoid IO bottlenecks.
- **High-Performance Evaluation**: Uses cached state values in `TradeEvaluatorService` to minimize computational overhead during high-frequency price updates.

## 4. Checkpoint & Recovery
Ensures that the bot can resume its exact state after a crash or manual restart.

- **Mechanism**: Serializes the complete trading state to JSON every 60 seconds (`CHECKPOINT_INTERVAL_SECONDS`).
- **Storage**: State is persisted in `~/.neotradingbot/checkpoints/`.

## 5. Security & Trust Architecture
- **gRPC TLS**: Secure communication is enforced in production.
- **Certificate Pinning**: Matches server subject/issuer to prevent MITM attacks.
- **Auth Interceptors**: Securely injects JWT tokens into every gRPC call.
