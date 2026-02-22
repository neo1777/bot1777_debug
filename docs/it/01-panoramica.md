# Panoramica del Sistema — NeoTradingBot 1777

## Descrizione Generale

NeoTradingBot 1777 è un sistema di trading automatizzato basato su strategie DCA (Dollar Cost Averaging) con gestione avanzata del rischio, monitoraggio in tempo reale e funzionalità enterprise di backtesting e analisi. Il sistema è composto da un backend Dart e un frontend Flutter comunicanti via gRPC con TLS obbligatorio.

## Architettura del Sistema

### Backend (`neotradingbotback1777`)

| Componente | Dettaglio |
| :--- | :--- |
| **Linguaggio** | Dart (Stable SDK 3.x) |
| **Comunicazione** | gRPC con TLS end-to-end |
| **Database** | Hive (NoSQL, persistenza locale ultra-veloce) |
| **Concorrenza** | Esecuzione atomica in isolate dedicati |
| **Esternalizzazione** | Docker + docker-compose, deploy remoto via script |

Componenti principali:

- `TradingSignalAnalyzer` — logica disaccoppiata per valutazione segnali Buy/Sell/DCA
- `AtomicActionProcessor` — orchestra esecuzione azioni e sincronizzazione stato
- `VolatilityService` — congelamento prezzi in condizioni di mercato estreme
- `FeeAwareCalculationService` — calcolo TP considerando commissioni maker/taker
- `CircuitBreaker` — protezione contro errori a cascata dell'API Binance
- `BacktestEngine` — simulazione strategie su dati storici Binance (klines)

### Frontend (`neotradingbotfront1777`)

| Componente | Dettaglio |
| :--- | :--- |
| **Framework** | Flutter 3.x |
| **Stato** | BLoC / Cubit |
| **Navigazione** | GoRouter (ShellRoute) |
| **DI** | GetIt (`sl<T>()`) |
| **Rete** | gRPC via `GrpcClientManager` + `ITradingRemoteDatasource` |

## Schermate e Funzionalità

| Rotta | Pagina | Funzione |
| :--- | :--- | :--- |
| `/dashboard` | Dashboard | Stato strategia, prezzi real-time, controllo trading |
| `/orders` | Ordini | Storico ordini e commissioni per simbolo |
| `/trade-history` | Trade History | Storico completo con filtri |
| `/account` | Account | Saldo e info account Binance |
| `/settings` | Impostazioni | Configurazione parametri strategia |
| `/system-logs` | Log Sistema | Stream log live dal backend |
| `/log-settings` | Log Settings | Configurazione livello log backend (RadioGroup) |
| `/backtest` | Backtest | Simulazione strategia su dati storici |
| `/testnet` | Testnet Monitor | Monitoraggio ambiente testnet |
| `/diagnostics/tls` | Diagnostica TLS | Status gRPC, certificati, WebSocket stats |

## Funzionalità Chiave

1. **Strategia DCA** — acquisto a più livelli con intervalli e moltiplicatori configurabili
2. **Controllo Volatilità** — congelamento prezzi con soglie `VOLATILITY_FREEZE_THRESHOLD` / `VOLATILITY_UNFREEZE_THRESHOLD`
3. **Fee-Aware Trading** — calcolo TP che include commissioni maker/taker in tempo reale
4. **Backtesting** — simulazione completa su dati storici con report profitto, DCA trades, fee totali
5. **Sicurezza** — TLS obbligatorio, certificate pinning, `STRICT_BOOT`
6. **Checkpoint & Recovery** — serializzazione stato ogni 60s, ripresa automatica dopo riavvio
7. **Monitoraggio Real-Time** — stream gRPC per prezzi, log, stato strategia (incl. stato RECOVERING)
8. **Log Settings** — configurazione live del livello di log backend dalla UI
9. **Fee Display** — visualizzazione commissioni maker/taker per simbolo nella scheda Ordini
10. **Diagnostica TLS** — pagina dedicata con status connessione, parametri certificato, WebSocket stats

## Stack Tecnologico

```
Frontend (Flutter)          Backend (Dart)
─────────────────           ───────────────────
BLoC / Cubit                Isolate-based concurrency
GoRouter (ShellRoute)       gRPC server (TLS)
GetIt DI                    Hive database
grpc / protobuf             Binance REST API
fpdart (Either monad)       Circuit Breaker pattern
intl / fl_chart             Atomic state management
```

## Struttura Monorepo

```
neotradingbot1777/
├── proto/                  # Proto files (source of truth)
│   ├── trading/v1/trading_service.proto
│   └── grpc/health/v1/health.proto
├── neotradingbotback1777/  # Backend Dart
├── neotradingbotfront1777/ # Frontend Flutter
├── scripts/                # Deploy, cert generation, protoc
├── certs/                  # TLS certificates (gitignored)
├── docs/                   # Documentazione (questa directory)
└── docker-compose.yml
```

