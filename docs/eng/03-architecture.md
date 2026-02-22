# NeoTradingBot 1777 - Architecture Diagrams

This document contains comprehensive architecture diagrams for the NeoTradingBot 1777 system, providing visual representations of the system's structure, data flows, and component interactions.

## Table of Contents

1. [System Overview](#system-overview)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [Trading Flow Diagram](#trading-flow-diagram)
4. [Data Flow Diagram](#data-flow-diagram)
5. [Component Interaction Diagram](#component-interaction-diagram)
6. [Security Architecture](#security-architecture)
7. [Deployment Architecture](#deployment-architecture)

## System Overview

```mermaid
graph TB
    subgraph "Frontend (Flutter)"
        UI[Presentation Layer]
        BLoC[BLoC Layer]
        DI[DI Container]
    end

    subgraph "Backend (Dart)"
        GRPC[gRPC Server]
        UC[Use Cases]
        DOM[Domain Layer]
        INF[Infrastructure Layer]
    end

    subgraph "External Services"
        BINANCE[Binance API]
        HIVE[Hive Database]
    end

    UI --> BLoC
    BLoC --> DI
    DI --> GRPC
    GRPC --> UC
    UC --> DOM
    DOM --> INF
    INF --> BINANCE
    INF --> HIVE
```

## Clean Architecture Layers

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[Flutter UI]
        BLoC[BLoC State Management]
        VALID[Input Validation]
    end

    subgraph "Application Layer"
        UC[Use Cases]
        MGR[Managers]
        HANDLER[Error Handlers]
    end

    subgraph "Domain Layer"
        ENT[Entities]
        REPO[Repository Interfaces]
        SERV[Domain Services]
        FAIL[Failures]
    end

    subgraph "Infrastructure Layer"
        API[API Services]
        CACHE[Cache Layer]
        PERSIST[Persistence]
        NET[Network Layer]
    end

    UI --> BLoC
    BLoC --> VALID
    VALID --> UC
    UC --> MGR
    MGR --> HANDLER
    HANDLER --> ENT
    ENT --> REPO
    REPO --> SERV
    SERV --> FAIL
    FAIL --> API
    API --> CACHE
    CACHE --> PERSIST
    PERSIST --> NET
```

## Trading Flow Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant B as Backend
    participant T as Trading Loop
    participant E as Evaluator
    participant A as Binance API

    U->>F: Start Strategy
    F->>B: gRPC StartStrategy
    B->>T: Initialize Trading Loop
    T->>E: Evaluate Trading Decisions
    E->>A: Get Market Data
    A-->>E: Price Data
    E->>E: Calculate P&L
    E->>E: Check TP/SL
    alt TP/SL Triggered
        E->>A: Execute Sell Order
        A-->>E: Order Confirmation
        E->>T: Update State
        T->>B: Check Run Control (Cycles/StopAfterNextSell)
        alt Should Stop
            B->>T: Terminate Loop
            T->>B: Notify Completion
            B->>F: Strategy Complete
            F->>U: Show Results
        else Continue
            B->>T: Continue Next Cycle
            T->>T: Wait for Next Tick
        end
    else Continue Monitoring
        T->>T: Wait for Next Tick
        T->>E: Re-evaluate
    end
```

## Data Flow Diagram

```mermaid
graph LR
    subgraph "Data Sources"
        BINANCE_API[Binance API]
        USER_INPUT[User Input]
        CONFIG[Configuration]
    end

    subgraph "Data Processing"
        VALIDATOR[Input Validator]
        SANITIZER[Data Sanitizer]
        TRANSFORMER[Data Transformer]
    end

    subgraph "Storage"
        CACHE[Thread-Safe Cache]
        HIVE[Hive Database]
        CHECKPOINT[Checkpoint Manager]
    end

    subgraph "Business Logic"
        EVALUATOR[Trade Evaluator]
        FEE_CALC[Fee Calculator]
        VOLATILITY[Volatility Service]
    end

    subgraph "Output"
        TRADES[Trading Orders]
        LOGS[Logs & Metrics]
        UI[User Interface]
    end

    BINANCE_API --> VALIDATOR
    USER_INPUT --> SANITIZER
    CONFIG --> TRANSFORMER

    VALIDATOR --> CACHE
    SANITIZER --> HIVE
    TRANSFORMER --> CHECKPOINT

    CACHE --> EVALUATOR
    HIVE --> FEE_CALC
    CHECKPOINT --> VOLATILITY

    EVALUATOR --> TRADES
    FEE_CALC --> LOGS
    VOLATILITY --> UI
```

## Component Interaction Diagram

```mermaid
graph TB
    subgraph "Core Components"
        LOCK[TradingLockManager]
        ERROR[GlobalErrorHandler]
        CIRCUIT[CircuitBreaker]
        THROTTLE[LogThrottler]
    end

    subgraph "Trading Components"
        EVALUATOR[TradeEvaluatorService]
        FEE[FeeCalculationService]
        VOLATILITY[VolatilityService]
        STATE[AtomicStateManager]
    end

    subgraph "Infrastructure Components"
        API[ApiService]
        CACHE[ThreadSafeCache]
        REPO[Repositories]
        WEBSOCKET[WebSocketManager]
    end

    LOCK --> EVALUATOR
    ERROR --> EVALUATOR
    CIRCUIT --> API
    THROTTLE --> EVALUATOR

    EVALUATOR --> FEE
    EVALUATOR --> VOLATILITY
    EVALUATOR --> STATE

    API --> CACHE
    CACHE --> REPO
    REPO --> WEBSOCKET

    WEBSOCKET --> API
    API --> CIRCUIT
    CIRCUIT --> ERROR
    ERROR --> THROTTLE
```

## Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        TLS[TLS Encryption]
        PINNING[Certificate Pinning]
        AUTH[API Authentication]
        VALID[Input Validation]
    end

    subgraph "Data Protection"
        ENCRYPT[Data Encryption]
        SANITIZE[Input Sanitization]
        AUDIT[Audit Logging]
        BACKUP[Secure Backup]
    end

    subgraph "Access Control"
        RATE_LIMIT[Rate Limiting]
        CIRCUIT_BREAK[Circuit Breaker]
        LOCK[Distributed Locks]
        PERMISSIONS[Permission System]
    end

    TLS --> PINNING
    PINNING --> AUTH
    AUTH --> VALID

    VALID --> ENCRYPT
    ENCRYPT --> SANITIZE
    SANITIZE --> AUDIT
    AUDIT --> BACKUP

    BACKUP --> RATE_LIMIT
    RATE_LIMIT --> CIRCUIT_BREAK
    CIRCUIT_BREAK --> LOCK
    LOCK --> PERMISSIONS
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development Environment"
        DEV_FRONT[Frontend Dev]
        DEV_BACK[Backend Dev]
        DEV_DB[Local Hive DB]
    end

    subgraph "Production Environment"
        PROD_FRONT[Frontend Prod]
        PROD_BACK[Backend Prod]
        PROD_DB[Production Hive DB]
        PROD_MONITOR[Monitoring]
    end

    subgraph "External Services"
        BINANCE_PROD[Binance Production API]
        BINANCE_TEST[Binance Testnet API]
    end

    DEV_FRONT --> DEV_BACK
    DEV_BACK --> DEV_DB
    DEV_BACK --> BINANCE_TEST

    PROD_FRONT --> PROD_BACK
    PROD_BACK --> PROD_DB
    PROD_BACK --> BINANCE_PROD
    PROD_BACK --> PROD_MONITOR

    PROD_MONITOR --> PROD_FRONT
    PROD_MONITOR --> PROD_BACK
```

## Trading Strategy Flow

```mermaid
stateDiagram-v2
    [*] --> IDLE: Initialize
    IDLE --> MONITORING_FOR_BUY: Start Strategy
    MONITORING_FOR_BUY --> POSITION_OPEN: Initial Buy
    MONITORING_FOR_BUY --> IDLE: Stop Strategy
    POSITION_OPEN --> POSITION_OPEN: DCA Buy
    POSITION_OPEN --> IDLE: Sell (TP/SL)
    POSITION_OPEN --> IDLE: Stop Strategy
    IDLE --> [*]: Shutdown
```

## Error Handling Flow

```mermaid
graph TB
    subgraph "Error Sources"
        API_ERROR[API Errors]
        VALIDATION_ERROR[Validation Errors]
        NETWORK_ERROR[Network Errors]
        BUSINESS_ERROR[Business Logic Errors]
    end

    subgraph "Error Processing"
        GLOBAL_HANDLER[GlobalErrorHandler]
        CIRCUIT_BREAKER[CircuitBreaker]
        RETRY_LOGIC[Retry Logic]
        FALLBACK[Fallback Mechanisms]
    end

    subgraph "Error Response"
        LOGGING[Structured Logging]
        METRICS[Error Metrics]
        USER_FEEDBACK[User Feedback]
        RECOVERY[Auto Recovery]
    end

    API_ERROR --> GLOBAL_HANDLER
    VALIDATION_ERROR --> GLOBAL_HANDLER
    NETWORK_ERROR --> CIRCUIT_BREAKER
    BUSINESS_ERROR --> RETRY_LOGIC

    GLOBAL_HANDLER --> LOGGING
    CIRCUIT_BREAKER --> METRICS
    RETRY_LOGIC --> USER_FEEDBACK
    FALLBACK --> RECOVERY

    LOGGING --> METRICS
    METRICS --> USER_FEEDBACK
    USER_FEEDBACK --> RECOVERY
```

## Performance Monitoring Architecture

```mermaid
graph TB
    subgraph "Metrics Collection"
        LATENCY[Latency Metrics]
        THROUGHPUT[Throughput Metrics]
        MEMORY[Memory Metrics]
        CPU[CPU Metrics]
    end

    subgraph "Analysis & Alerting"
        TREND[Trend Analysis]
        THRESHOLD[Threshold Monitoring]
        ALERT[Alert System]
        DASHBOARD[Dashboard]
    end

    subgraph "Optimization"
        CACHE_OPT[Cache Optimization]
        LOG_OPT[Log Optimization]
        PERF_OPT[Performance Optimization]
        CLEANUP[Resource Cleanup]
    end

    LATENCY --> TREND
    THROUGHPUT --> THRESHOLD
    MEMORY --> ALERT
    CPU --> DASHBOARD

    TREND --> CACHE_OPT
    THRESHOLD --> LOG_OPT
    ALERT --> PERF_OPT
    DASHBOARD --> CLEANUP
```

## Database Schema

```mermaid
erDiagram
    ACCOUNT_INFO ||--o{ BALANCE : contains
    STRATEGY_STATE ||--o{ TRADE : has
    TRADE ||--|| FEE_INFO : includes
    SETTINGS ||--|| STRATEGY_STATE : configures
    LOG_ENTRY ||--|| STRATEGY_STATE : tracks

    ACCOUNT_INFO {
        string symbol
        datetime lastUpdated
    }

    BALANCE {
        string asset
        double free
        double locked
    }

    STRATEGY_STATE {
        string symbol
        StrategyStatus status
        double currentPrice
        datetime lastUpdate
    }

    TRADE {
        string id
        string symbol
        double price
        double quantity
        TradeSide side
        datetime timestamp
    }

    FEE_INFO {
        string symbol
        double makerFee
        double takerFee
        double discountPercentage
        datetime lastUpdated
    }

    SETTINGS {
        double tradeAmount
        double profitTargetPercentage
        double stopLossPercentage
        double dcaDecrementPercentage
        int maxOpenTrades
        bool enableFeeAwareTrading
    }

    LOG_ENTRY {
        string level
        string message
        datetime timestamp
        string source
    }
```

## API Endpoints Structure

```mermaid
graph TB
    subgraph "gRPC Services"
        TRADING_SERVICE[TradingService]
        HEALTH_SERVICE[HealthService]
    end

    subgraph "TradingService Methods"
        GET_SETTINGS[GetSettings]
        UPDATE_SETTINGS[UpdateSettings]
        START_STRATEGY[StartStrategy]
        STOP_STRATEGY[StopStrategy]
        PAUSE_TRADING[PauseTrading]
        RESUME_TRADING[ResumeTrading]
        GET_STRATEGY_STATE[GetStrategyState]
        GET_TRADE_HISTORY[GetTradeHistory]
        GET_ACCOUNT_INFO[GetAccountInfo]
        STREAM_CURRENT_PRICE[StreamCurrentPrice]
        GET_SYMBOL_FEES[GetSymbolFees]
    end

    subgraph "HealthService Methods"
        CHECK[Check]
        WATCH[Watch]
    end

    TRADING_SERVICE --> GET_SETTINGS
    TRADING_SERVICE --> UPDATE_SETTINGS
    TRADING_SERVICE --> START_STRATEGY
    TRADING_SERVICE --> STOP_STRATEGY
    TRADING_SERVICE --> PAUSE_TRADING
    TRADING_SERVICE --> RESUME_TRADING
    TRADING_SERVICE --> GET_STRATEGY_STATE
    TRADING_SERVICE --> GET_TRADE_HISTORY
    TRADING_SERVICE --> GET_ACCOUNT_INFO
    TRADING_SERVICE --> STREAM_CURRENT_PRICE
    TRADING_SERVICE --> GET_SYMBOL_FEES

    HEALTH_SERVICE --> CHECK
    HEALTH_SERVICE --> WATCH
```

---

## Legend

- **Solid arrows**: Direct dependencies
- **Dashed arrows**: Optional or conditional dependencies
- **Rectangles**: Components/Modules
- **Circles**: External services
- **Diamonds**: Decision points
- **Hexagons**: Data stores

## Notes

- All diagrams are created using Mermaid syntax
- Diagrams can be rendered in any Mermaid-compatible viewer
- Architecture follows Clean Architecture principles
- Security is implemented at multiple layers
- Performance monitoring is built-in throughout the system
- Error handling is centralized and comprehensive

