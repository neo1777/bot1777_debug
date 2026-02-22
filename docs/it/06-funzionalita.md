# Funzionalità Enterprise — NeoTradingBot 1777

## 1. Strategia DCA (Dollar Cost Averaging)

Il motore di trading implementa una strategia DCA multi-livello con configurazione completa.

- **Acquisti Multipli**: Supporto per N livelli di DCA con intervalli e moltiplicatori configurabili
- **Decisioni Intelligenti**: `TradingSignalAnalyzer` valuta segnali Buy/Sell/DCA in modo disaccoppiato
- **Esecuzione Atomica**: `AtomicActionProcessor` garantisce consistenza di stato durante l'esecuzione
- **Configurazione**: `maxDcaOrders`, `dcaMultiplier`, `buyIntervalPercent` configurabili da UI

## 2. Controllo della Volatilità

Il `VolatilityService` monitora le condizioni di mercato usando calcoli di deviazione standard.

- **Congelamento Prezzo**: Quando la volatilità supera `VOLATILITY_FREEZE_THRESHOLD` (5%), il prezzo medio viene "congelato" per evitare inseguimento di movimenti irrazionali
- **Sblocco Automatico**: Alla discesa sotto `VOLATILITY_UNFREEZE_THRESHOLD` (3%)
- **File**: `neotradingbotback1777/lib/infrastructure/services/volatility_service_impl.dart`

## 3. Fee-Aware Trading

Risolve il problema delle perdite "invisibili" causate dalle commissioni exchange.

- **Formula TP**: `target = prezzo_medio × (1 + profit_target + commissione) / (1 - commissione)`
- **Commissioni Real-Time**: Recuperate automaticamente da Binance (`getSymbolFees` gRPC)
- **Visualizzazione UI**: Commissioni maker/taker visibili per simbolo in `/orders`
- **Campi `SymbolLimits`**: `makerCommission`, `takerCommission`, `ioMakerCommission`, `ioBuyerMakerCommission`, `ioSellerMakerCommission`, `lastUpdated`

## 4. Backtesting

Motore completo per simulazione strategie su dati storici Binance.

- **Endpoint gRPC**: `StartBacktest` / `GetBacktestResults` in `trading_service.proto`
- **Input**: simbolo, intervallo (1m/5m/15m/1h/4h/1d), periodo (giorni), nome strategia
- **Output**: `BacktestResult` con:
  - `totalProfit` / `totalProfitStr` — profitto netto
  - `profitPercentage` / `profitPercentageStr` — rendimento %
  - `totalFees` / `totalFeesStr` — fee totali
  - `tradesCount` / `dcaTradesCount` — trade totali e DCA
  - `trades` — lista completa con prezzo, qty, timestamp, P&L per trade
- **UI**: `/backtest` con form parametri e tabella risultati
- **File chiave**: `lib/presentation/features/backtest/`

## 5. Log Settings

Configurazione live del livello di log backend direttamente dalla UI.

- **Livelli Supportati**: DEBUG, INFO, WARNING, ERROR
- **UI**: `/log-settings` con `RadioGroup` (Flutter 3.32+)
- **BLoC**: `LogSettingsBloc` — `LoadLogSettings` / `UpdateLogLevel`
- **Backend**: Applicazione immediata senza riavvio
- **File chiave**: `lib/presentation/features/log_settings/`

## 6. Stato RECOVERING

Gestione e visualizzazione dello stato di recupero della strategia.

- **Stato Proto**: `RECOVERING` mappato da `StrategyStateMapper`
- **Entity**: `StrategyState.warnings` — lista messaggi di warning attivi
- **UI**: Badge arancione `RECOVERING` con lista warnings in `StrategyStateCardContent`

## 7. Gestione "Polvere" (Dust) e Ottimizzazione Log

- **Dust Prevention**: Blocca tentativi di vendita per quantità inferiori al limite minimo exchange (`DUST_UNSELLABLE`)
- **Log Suppression**: Riduce log rumorosi ("SELL decision with fees") per evitare I/O bottleneck
- **Cache-Based Evaluation**: `TradeEvaluatorService` usa valori cached per minimizzare overhead computazionale

## 8. Checkpoint e Recovery

Garantisce ripresa esatta dello stato dopo crash o riavvio manuale.

- **Serializzazione**: Stato completo in JSON ogni 60s (`CHECKPOINT_INTERVAL_SECONDS`)
- **Storage**: `hive_data/` (volume Docker persistente)
- **Ripresa Automatica**: Al riavvio, lo stato viene letto dal checkpoint più recente
- **Isolate Safety**: Scritture atomiche per prevenire corruzione dati

## 9. TLS Diagnostics

Pagina dedicata per debug della connettività gRPC e TLS.

- **Rotta**: `/diagnostics/tls`
- **Info Mostrate**: stato connessione, `kReleaseMode`, host/porta, parametri TLS, cert asset/B64
- **WebSocket Stats**: statistiche server live via `getWebSocketStats` gRPC
- **File**: `lib/presentation/features/diagnostics/pages/tls_diagnostics_page.dart`

## 10. Architettura di Sicurezza

- **gRPC TLS**: Comunicazione sicura obbligatoria in produzione
- **Certificate Pinning**: Frontend verifica soggetto/emittente server (previene MITM)
- **`STRICT_BOOT`**: Il backend non si avvia senza certificati TLS validi
- **Intercettori JWT**: Iniezione sicura di token in ogni chiamata gRPC (se configurati)
- **Segreti**: Tutte le chiavi API in variabili d'ambiente (mai committate)

