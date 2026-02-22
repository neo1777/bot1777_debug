# Testing Strategy: NeoTradingBot1777

## Status: ACTIVE — v2.1.0

Testing is prioritized to ensure absolute environment isolation, strategy reliability, and code quality.

### 1. Environment Isolation Verification
The core of the testing strategy is the **Isolation Audit**:
- **Setup**: Configure both Real and Testnet accounts with different balances.
- **Protocol**: Execute trades on Testnet and verify that no changes occur in the Real balance.
- **Verification**: Cross-reference Hive boxes (`test_` vs `real_` prefixes) to ensure zero data leakage.

### 2. Manual Testing Guide
The project maintains a comprehensive [Manual Testing Guide](../MANUAL_TESTING_GUIDE.md) covering:
- gRPC connectivity checks.
- Dashboard real-time update validation.
- Critical mode-switching flow.
- Balance integrity and data isolation.

### 3. Automated Testing (Implemented)

#### Backend (42 test files, 442+ test cases)
- **Unit Tests**: Domain services (VolatilityService, FeeCalculationService, TradeValidationService, TradeEvaluator)
- **Integration Tests**: System stability, persistence, gRPC
- **Stress/Performance Tests**: Concurrency, memory, performance, data validation, circuit breaker
- **Mocking**: `mockito` with `build_runner` for code-generated mocks

#### Frontend (21 test files, ~90+ test cases)
- **BLoC Tests**: PriceBlocReal, TradeHistoryBloc, StrategyControlBloc, SystemLogBloc
- **Widget Tests**: StrategyStateCard, StrategyControlWidget
- **Integration Tests**: Advanced trading flow, end-to-end trading, resilience
- **Mocking**: `mocktail` for simpler, no-code-generation mocking

| Progetto | File Test | Test Pass | Test Fail | Test Skip |
|----------|-----------|-----------|-----------|-----------|
| Backend  | 42        | 442       | 48        | 0         |
| Frontend | 21        | ~90       | 0         | 2         |

### 4. Known Design Bugs (Documented)
1. **PriceBlocReal emit-after-complete**: Stream listener calls `emit()` after event handler completes
2. **TradeHistoryLoaded.copyWith**: Null arguments don't clear fields due to `??` operator

### 5. Backtesting
The gRPC service includes `StartBacktest` functionality to validate strategies against historical data before deployment.

### 6. Future Testing Priorities
- [ ] Migrate backend mocks from `mockito` → `mocktail`
- [ ] Frontend: mapper tests (10/11 untested)
- [ ] Frontend: repository tests (0/10)
- [ ] Backend: Expand `binance_api_client_test.dart`
- [ ] Backend: API key sanitization tests

---
Last updated: 2026-02-15 | v2.1.0