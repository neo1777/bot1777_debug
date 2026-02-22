# Roadmap — NeoTradingBot 1777

Ultimo aggiornamento: Febbraio 2026

## Fase 1: Fondamenta e Consolidamento ✅ COMPLETA

- [x] **Architettura Clean**: Backend Dart + Frontend Flutter separati, comunicazione gRPC
- [x] **Sicurezza TLS**: `STRICT_BOOT`, certificate pinning, TLS obbligatorio in produzione
- [x] **Deploy Containerizzato**: `docker-compose.yml`, `deploy.sh` per deploy remoto VPS
- [x] **Database Hive**: Persistenza locale ultra-veloce, checkpoint atomici ogni 60s
- [x] **Circuit Breaker**: Protezione da errori a cascata API Binance
- [x] **Fee-Aware Trading**: Calcolo TP con commissioni maker/taker in tempo reale
- [x] **Controllo Volatilità**: `VolatilityService` con congelamento prezzi adattivo
- [x] **Clean Architecture Frontend**: BLoC/Cubit, GoRouter ShellRoute, GetIt DI
- [x] **Documentazione**: Setup, Runbook, Guide Utente, Troubleshooting

## Fase 2: Feature Avanzate ✅ COMPLETA

- [x] **Motore di Backtesting**: Simulazione strategie su dati storici Binance (StartBacktest gRPC)
  - Report completo: profitto netto, rendimento %, fee totali, trade DCA, lista trade
  - UI dedicata `/backtest` con parametri configurabili (simbolo, intervallo, periodo)
- [x] **Log Settings**: Configurazione live del livello log backend dalla UI (`/log-settings`)
- [x] **Fee Display**: Visualizzazione commissioni maker/taker per simbolo in `/orders`
  - `SymbolLimits` entity estesa con `makerCommission`, `takerCommission`, `ioMakerCommission`, ecc.
- [x] **TLS Diagnostics**: Pagina `/diagnostics/tls` con status gRPC, parametri cert, WebSocket stats
- [x] **RECOVERING State**: Badge dedicato UI per stato RECOVERING della strategia con lista warnings
- [x] **Gestione Simboli Dinamica**: `getAvailableSymbols` via `ITradingRemoteDatasource`
- [x] **Audit Codice**: `flutter analyze` = 0 warning, allineamento completo frontend/backend proto

## Fase 3: QA e CI/CD

- [ ] **Pipeline CI**: GitHub Actions per linting e test automatici su PR
- [ ] **Pipeline CD**: Build Docker automatica al merge su `main`
- [ ] **Test E2E**: Flusso completo frontend → backend → Binance API (simulata)
- [ ] **Frontend Test Coverage**: Mapper tests (10/11 non testati), repository tests (0/10)
- [ ] **Backend Mock Migration**: Da `mockito` → `mocktail` per uniformità

## Fase 4: Funzionalità di Trading Avanzate

- [ ] **Supporto Multi-Simbolo**: Trading simultaneo su più coppie
- [ ] **Strategie Configurabili**: Oltre a ClassicDCA, aggiunta di strategie alternative
- [ ] **Notifiche Telegram**: Alerting configurabile per eventi critici (TP/SL, errori)
- [ ] **Supporto Multi-Exchange**: Astrazione exchange per Bybit/OKX
- [ ] **Dashboard Backtest Avanzata**: Grafici P&L, Drawdown, Sharpe Ratio

## Fase 5: Scala Enterprise

- [ ] **Supporto Kubernetes**: Helm charts per deploy su K8s
- [ ] **Multi-Tenancy**: Supporto multi-utente con portfolio isolati
- [ ] **App Mobile**: Rilascio iOS/Android della dashboard
- [ ] **Integrazione ML**: Sperimentazione TFLite per price prediction
