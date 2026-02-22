# API gRPC e Protobuf — NeoTradingBot 1777

## Struttura Proto (Source of Truth)

```
proto/
├── trading/v1/
│   └── trading_service.proto   # API principale trading bot
└── grpc/health/v1/
    └── health.proto             # Health check standard gRPC
```

I proto sono centralizzati nella root del progetto. **Non duplicare in altre cartelle.**

## Servizi gRPC Disponibili

### TradingService (`trading.v1.TradingService`)

| Metodo | Tipo | Descrizione |
| :--- | :--- | :--- |
| `GetPrice` | Server Stream | Stream prezzi real-time per simbolo |
| `StartStrategy` | Unary | Avvia la strategia di trading |
| `StopStrategy` | Unary | Ferma la strategia |
| `GetStrategyState` | Server Stream | Stream stato strategia |
| `GetOrders` | Unary | Lista ordini con commissioni |
| `GetTradeHistory` | Unary | Storico trade con filtri |
| `GetAccountInfo` | Unary | Info account Binance |
| `GetSymbolLimits` | Unary | Limiti e commissioni per simbolo |
| `GetSymbolFees` | Unary | Commissioni maker/taker per simbolo |
| `GetAllSymbolFees` | Unary | Commissioni di tutti i simboli |
| `GetAvailableSymbols` | Unary | Lista simboli disponibili |
| `StartBacktest` | Unary | Avvia simulazione backtest |
| `GetBacktestResults` | Unary | Risultati backtest per ID |
| `GetSystemLogs` | Server Stream | Stream log di sistema |
| `SetLogLevel` | Unary | Imposta livello log backend |
| `GetLogLevel` | Unary | Legge livello log corrente |
| `GetWebSocketStats` | Unary | Statistiche WebSocket e sistema |
| `HealthCheck` | Unary | Health check connessione |

### BacktestResultsResponse — Campi

```protobuf
message BacktestResultsResponse {
  string backtest_id = 1;
  double total_profit = 2;
  double profit_percentage = 3;
  int32 trades_count = 4;
  int32 dca_trades_count = 5;
  double total_fees = 6;
  string total_profit_str = 7;
  string profit_percentage_str = 8;
  string total_fees_str = 9;
  repeated Trade trades = 10;
}
```

### StrategyState — Valori Enum

| Valore | Descrizione |
| :--- | :--- |
| `IDLE` | Strategia ferma |
| `MONITORING_FOR_BUY` | In attesa segnale acquisto |
| `POSITION_OPEN` | Posizione aperta |
| `RECOVERING` | In fase di recupero (con warnings) |

## Generazione Codice Dart

```bash
# Dalla root del progetto
./generate_proto.sh
```

Genera stub Dart per:
- Backend: `neotradingbotback1777/lib/generated/proto/`
- Frontend: `neotradingbotfront1777/lib/generated/proto/`

**Non modificare mai manualmente** i file `.pb.dart`, `.pbgrpc.dart`, `.pbenum.dart`, `.pbjson.dart`.

### Requisiti

```bash
# Installare plugin protoc per Dart
dart pub global activate protoc_plugin
```

- `protoc` (Protocol Buffer Compiler) — disponibile in `tools/protoc/bin/`
- `protoc-gen-dart` — installato via pub global

## Architettura Client Frontend

```
ITradingRemoteDatasource (interfaccia)
  └── TradingRemoteDatasource (impl)
        └── GrpcClientManager (gestione connessione + status stream)
              └── GrpcClient (canale gRPC con TLS)
```

Tutti i metodi ritornano `Either<Failure, T>` (fpdart). Pattern `_unaryCall`:

```dart
Future<Either<Failure, T>> _unaryCall<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on GrpcError catch (e) {
    return Left(ServerFailure(message: e.message ?? e.toString()));
  } catch (e) {
    return Left(ServerFailure(message: e.toString()));
  }
}
```

## Best Practices Protobuf

### Naming e Tag

- Messaggi: `UpperCamelCase` (es. `StartBacktestRequest`)
- Campi: `snake_case` (es. `backtest_id`)
- Enum: primo valore sempre `NOME_UNSPECIFIED = 0`
- Tag 1-15: per campi ad alta frequenza (1 byte); 16-2047: per campi occasionali

### Versioning e Compatibilità

- **Non cambiare mai** tag o tipi di campi esistenti (breaking change)
- **Aggiungi nuovi campi** con nuovi tag numerici
- Usa `reserved` per rimuovere campi deprecati
- Incrementa versione del namespace (`v1` → `v2`) solo per breaking changes architetturali

### Well-Known Types

Usa i proto standard Google invece di creare tipi custom:

```protobuf
import "google/protobuf/empty.proto";      // → google.protobuf.Empty
import "google/protobuf/timestamp.proto";  // → google.protobuf.Timestamp
```

### Workflow Modifica Proto

1. **Edita** solo file in `/proto/`
2. **Rigenera** con `./generate_proto.sh`
3. **Verifica** che backend e frontend compilino
4. **Committa** proto + file generati insieme

## Stato Best Practices

- [x] Namespace isolati: `trading.v1`, `grpc.health.v1`
- [x] Proto centralizzati, nessun duplicato
- [x] Valori decimali con alta precisione (campi stringa + double)
- [x] TLS end-to-end abilitato
- [x] Certificate Pinning nel frontend
- [x] `STRICT_BOOT` nel backend
- [x] Health check conforme a specifica ufficiale gRPC
