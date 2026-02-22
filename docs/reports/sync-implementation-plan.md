# Piano di Implementazione: Sincronizzazione Backend/Frontend

> **Data**: 2026-02-19
> **Stato**: Da implementare
> **Scope**: Colmare tutti i gap tra backend gRPC e frontend Flutter

---

## Riepilogo Gap Identificati

| ID  | Gap                                    | Priorità | Complessità |
|-----|----------------------------------------|----------|-------------|
| S1  | `warnings` field 12 non mappato        | Alta     | Bassa       |
| S2  | `SymbolLimits` fee fields non mappati  | Media    | Bassa       |
| S3  | 3 chiamate gRPC dirette (bypass arch.) | Alta     | Media       |
| S4  | LogSettings: infrastruttura ok, no UI  | Media    | Media       |
| S5  | WebSocket Stats: zero frontend code    | Bassa    | Bassa       |
| S6  | Backtest: zero frontend code           | Alta     | Alta        |

---

## Fase 1 — Quick Wins: Mapping Dati (S1 + S2)

> **Nessuna nuova pagina, zero dipendenze esterne. Strettamente dati.**

### S1: Mappare `warnings` (repeated string, field 12) in `StrategyState`

Il backend invia due field paralleli:
- **field 11** `warningMessage` (string): warning singolo, testo libero
- **field 12** `warnings` (repeated string): lista strutturata, es. `['RECOVERING']`

Il mapper frontend legge solo field 11 e ignora field 12 completamente.

#### File da modificare

**1. `lib/domain/entities/strategy_state.dart`**

Aggiungere il campo `warnings` alla classe `StrategyState`:

```dart
// PRIMA (riga ~45 — solo warningMessage)
final String? warningMessage;

// DOPO — aggiungere DOPO warningMessage
final String? warningMessage;
final List<String> warnings;

// Nel costruttore aggiungere:
this.warnings = const [],

// In StrategyState.initial() aggiungere:
warnings: const [],

// In copyWith() aggiungere:
List<String>? warnings,
// ...
warnings: warnings ?? this.warnings,
```

**2. `lib/data/mappers/strategy_state_mapper.dart`**

La funzione `_extractWarning` usa `toProto3Json()` e legge solo `warningMessage`.
Aggiungere estrazione di `warnings`:

```dart
// Aggiungere metodo accanto a _extractWarning:
static List<String> _extractWarnings(grpc.StrategyStateResponse proto) {
  try {
    final map = proto.toProto3Json() as Map<String, dynamic>;
    final v = map['warnings'];
    if (v is List) {
      return v.whereType<String>().toList();
    }
  } catch (_) {}
  return const [];
}
```

Nel metodo `fromProto` che costruisce `StrategyState`, aggiungere:

```dart
warnings: _extractWarnings(proto),
```

**3. `lib/presentation/features/dashboard/widgets/strategy_state_card_content.dart`**

La pill `AUTO_STOP_IN_CYCLES` mostra già i warning strutturati. Per il campo `warnings` generico, mostrare un badge compatto solo se contiene `'RECOVERING'` (stato di recovery che il backend emette via `warnings` ma non via `status`):

```dart
// In build(), dopo _buildAutoStopPill(displayState.warningMessage):
if (displayState.warnings.contains('RECOVERING'))
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withAlpha(100)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 14, color: Colors.blueAccent),
          SizedBox(width: 6),
          Text(
            'Recupero isolate in corso...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    ),
  ),
```

> **Nota**: Il backend emette `RECOVERING` solo come elemento di `warnings` (field 12)
> e come prefisso in `warningMessage`, mai come `status` field. Questo badge rende
> visibile lo stato di recupero isolate all'utente.

---

### S2: Mappare i fee fields in `SymbolLimitsResponse`

Il backend invia 6 campi fee che il mapper frontend non legge:
`makerFee`, `takerFee`, `feeCurrency`, `isDiscountActive`, `discountPercentage`, `lastUpdated`

> **Nota**: questi dati esistono già in `FeeInfo` (usato da `IFeeRepository`).
> L'obiettivo qui è arricchire `SymbolLimits` (usato dalla pagina Ordini)
> con le stesse info per evitare una seconda chiamata separata.

#### File da modificare

**1. `lib/domain/entities/symbol_limits.dart`**

```dart
// Aggiungere al costruttore e ai campi esistenti:
final double makerFee;
final double takerFee;
final String feeCurrency;
final bool isDiscountActive;
final double discountPercentage;
final DateTime? lastUpdated;

// Nel costruttore aggiungere con default sicuri:
this.makerFee = 0.001,
this.takerFee = 0.001,
this.feeCurrency = 'BNB',
this.isDiscountActive = false,
this.discountPercentage = 0.0,
this.lastUpdated,
```

**2. `lib/data/mappers/symbol_limits_mapper.dart`**

```dart
// Nel metodo fromProto (o toDomain), aggiungere dopo i campi esistenti:
makerFee: proto.makerFee,
takerFee: proto.takerFee,
feeCurrency: proto.feeCurrency,
isDiscountActive: proto.isDiscountActive,
discountPercentage: proto.discountPercentage,
lastUpdated: proto.lastUpdated > Int64.ZERO
    ? DateTime.fromMillisecondsSinceEpoch(proto.lastUpdated.toInt())
    : null,
```

> Aggiungere import `package:fixnum/fixnum.dart` se non presente.

**3. Visualizzazione in `lib/presentation/features/orders/pages/orders_page.dart`**
(o dove `SymbolLimits` viene mostrato)

Aggiungere sezione "Fee" nella card limiti simbolo, accanto ai limiti esistenti:

```dart
// Nella sezione dei limiti simbolo:
_buildFeeRow('Maker Fee:', '${(symbolLimits.makerFee * 100).toStringAsFixed(3)}%'),
_buildFeeRow('Taker Fee:', '${(symbolLimits.takerFee * 100).toStringAsFixed(3)}%'),
if (symbolLimits.isDiscountActive)
  _buildFeeRow(
    'Sconto BNB:',
    '-${(symbolLimits.discountPercentage * 100).toStringAsFixed(1)}%',
    color: Colors.greenAccent,
  ),
```

---

## Fase 2 — Fix Architetturale: Eliminare Chiamate gRPC Dirette (S3)

> **3 punti nel codice bypassano `ITradingRemoteDatasource`**. Questo rompe:
> - Testabilità (non mockabile)
> - Retry logic centralizzato (`_unaryCall`)
> - Intercettori gRPC (API key, logging)

### Callers da correggere

| Caller | Metodo gRPC | Fix |
|--------|-------------|-----|
| `trading_control_panel.dart:84` | `client.getAvailableSymbols()` | Via datasource |
| `fee_repository_impl.dart:37` | `grpcClient.client.getSymbolFees()` | Via datasource |
| `fee_repository_impl.dart:90` | `grpcClient.client.getAllSymbolFees()` | Via datasource |

#### File da modificare

**1. `lib/data/datasources/i_trading_remote_datasource.dart`**

Aggiungere alla fine dell'interfaccia (prima della `}`):

```dart
// --- Symbol & Fee ---
Future<Either<Failure, AvailableSymbolsResponse>> getAvailableSymbols();
Future<Either<Failure, SymbolFeesResponse>> getSymbolFees(String symbol);
Future<Either<Failure, AllSymbolFeesResponse>> getAllSymbolFees();

// --- WebSocket Stats (gap S5, aggiunto qui per completezza architetturale) ---
Future<Either<Failure, LogEntry>> getWebSocketStats();
```

> Gli import gRPC generati sono già presenti nel file. `AvailableSymbolsResponse`,
> `SymbolFeesResponse`, `AllSymbolFeesResponse`, `LogEntry` sono tutti in
> `trading_service.pb.dart`.

**2. `lib/data/datasources/trading_remote_datasource.dart`**

Aggiungere le implementazioni usando il pattern `_unaryCall` già presente:

```dart
@override
Future<Either<Failure, AvailableSymbolsResponse>> getAvailableSymbols() =>
    _unaryCall(
      'getAvailableSymbols',
      (opts) => _client.getAvailableSymbols(Empty(), options: opts),
    );

@override
Future<Either<Failure, SymbolFeesResponse>> getSymbolFees(String symbol) =>
    _unaryCall(
      'getSymbolFees',
      (opts) => _client.getSymbolFees(
        GetSymbolFeesRequest(symbol: symbol),
        options: opts,
      ),
    );

@override
Future<Either<Failure, AllSymbolFeesResponse>> getAllSymbolFees() =>
    _unaryCall(
      'getAllSymbolFees',
      (opts) => _client.getAllSymbolFees(Empty(), options: opts),
    );

@override
Future<Either<Failure, LogEntry>> getWebSocketStats() =>
    _unaryCall(
      'getWebSocketStats',
      (opts) => _client.getWebSocketStats(Empty(), options: opts),
    );
```

**3. `lib/data/repositories/fee_repository_impl.dart`**

Refactoring: sostituire `GrpcClientManager` con `ITradingRemoteDatasource`:

```dart
// PRIMA
class FeeRepositoryImpl implements IFeeRepository {
  final GrpcClientManager _grpcClient;

  FeeRepositoryImpl({required GrpcClientManager grpcClient})
    : _grpcClient = grpcClient;
```

```dart
// DOPO
class FeeRepositoryImpl implements IFeeRepository {
  final ITradingRemoteDatasource _datasource;

  FeeRepositoryImpl({required ITradingRemoteDatasource datasource})
    : _datasource = datasource;
```

Sostituire la chiamata gRPC diretta in `getSymbolFees`:

```dart
// PRIMA
final request = GetSymbolFeesRequest(symbol: symbol);
final response = await grpcClient.client.getSymbolFees(request);
final feeInfo = FeeInfo(
  symbol: response.symbol,
  makerFee: response.makerFee,
  // ...
);
```

```dart
// DOPO
final result = await _datasource.getSymbolFees(symbol);
return result.fold(
  (failure) {
    _logger.w('Errore gRPC per fee di $symbol: $failure');
    final defaultFees = FeeInfo.defaultBinance(symbol: symbol);
    _cache[symbol] = _CachedFeeInfo(feeInfo: defaultFees, timestamp: DateTime.now());
    return Right(defaultFees);
  },
  (response) {
    final feeInfo = FeeInfo(
      symbol: response.symbol,
      makerFee: response.makerFee,
      takerFee: response.takerFee,
      feeCurrency: response.feeCurrency,
      isDiscountActive: response.isDiscountActive,
      discountPercentage: response.discountPercentage,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        response.lastUpdated.toInt(),
      ),
    );
    _cache[symbol] = _CachedFeeInfo(feeInfo: feeInfo, timestamp: DateTime.now());
    return Right(feeInfo);
  },
);
```

Analogamente per `getAllSymbolFees`:

```dart
// DOPO
final result = await _datasource.getAllSymbolFees();
return result.fold(
  (failure) {
    _logger.w('Errore gRPC batch per fee multiple: $failure');
    // Fallback: recupera singolarmente
    // ... (logica esistente)
  },
  (response) {
    final feeMap = <String, FeeInfo>{};
    for (final symbolFee in response.symbolFees) {
      final feeInfo = FeeInfo(
        symbol: symbolFee.symbol,
        makerFee: symbolFee.makerFee,
        takerFee: symbolFee.takerFee,
        feeCurrency: symbolFee.feeCurrency,
        isDiscountActive: symbolFee.isDiscountActive,
        discountPercentage: symbolFee.discountPercentage,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          symbolFee.lastUpdated.toInt(),
        ),
      );
      feeMap[symbolFee.symbol] = feeInfo;
      _cache[symbolFee.symbol] = _CachedFeeInfo(
        feeInfo: feeInfo,
        timestamp: DateTime.now(),
      );
    }
    return Right(feeMap);
  },
);
```

Rimuovere tutti gli import non più usati: `grpc_client.dart`, `GetSymbolFeesRequest`, `Empty`.
Aggiungere: `import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';`

**4. `lib/core/di/injection.dart`**

Aggiornare la registrazione di `IFeeRepository`:

```dart
// PRIMA
sl.registerLazySingleton<IFeeRepository>(
  () => FeeRepositoryImpl(grpcClient: sl<GrpcClientManager>()),
);

// DOPO
sl.registerLazySingleton<IFeeRepository>(
  () => FeeRepositoryImpl(datasource: sl<ITradingRemoteDatasource>()),
);
```

**5. `lib/presentation/common_widgets/trading_control_panel.dart`**

Sostituire la chiamata diretta al client gRPC in `_loadSymbols()`:

```dart
// PRIMA (riga 82-84)
Future<void> _loadSymbols() async {
  try {
    final client = sl<trading_grpc.TradingServiceClient>();
    final response = await client.getAvailableSymbols(pb_empty.Empty());
    final symbols = response.symbols.toList();
```

```dart
// DOPO
Future<void> _loadSymbols() async {
  try {
    final datasource = sl<ITradingRemoteDatasource>();
    final result = await datasource.getAvailableSymbols();
    final symbols = result.fold(
      (_) => <String>[],
      (response) => response.symbols.toList(),
    );
```

Rimuovere gli import non più usati:
- `package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart` (se usato solo per `getAvailableSymbols`)
- `package:protobuf/well_known_types/google/protobuf/empty.pb.dart` (se usato solo lì)

Aggiungere:
```dart
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
```

---

## Fase 3 — LogSettings UI (S4)

> **L'infrastruttura è completa** (datasource, mapper, repository, entity).
> Mancano solo: BLoC, Page, Route, Nav item, DI.

### Struttura target

```
lib/presentation/features/log_settings/
├── bloc/
│   ├── log_settings_bloc.dart
│   ├── log_settings_event.dart
│   └── log_settings_state.dart
└── pages/
    └── log_settings_page.dart
```

### 3.1 — BLoC Events

**`lib/presentation/features/log_settings/bloc/log_settings_event.dart`** (nuovo file)

```dart
part of 'log_settings_bloc.dart';

abstract class LogSettingsEvent {}

/// Carica le impostazioni di log dal backend.
class LogSettingsFetched extends LogSettingsEvent {}

/// Salva le nuove impostazioni di log.
class LogSettingsUpdated extends LogSettingsEvent {
  final LogSettings settings;
  LogSettingsUpdated(this.settings);
}
```

### 3.2 — BLoC State

**`lib/presentation/features/log_settings/bloc/log_settings_state.dart`** (nuovo file)

```dart
part of 'log_settings_bloc.dart';

enum LogSettingsStatus { initial, loading, loaded, saving, saved, failure }

class LogSettingsState {
  final LogSettingsStatus status;
  final LogSettings? settings;
  final String? errorMessage;

  const LogSettingsState({
    this.status = LogSettingsStatus.initial,
    this.settings,
    this.errorMessage,
  });

  LogSettingsState copyWith({
    LogSettingsStatus? status,
    LogSettings? settings,
    String? errorMessage,
  }) => LogSettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```

### 3.3 — BLoC

**`lib/presentation/features/log_settings/bloc/log_settings_bloc.dart`** (nuovo file)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_log_settings_repository.dart';

part 'log_settings_event.dart';
part 'log_settings_state.dart';

class LogSettingsBloc extends Bloc<LogSettingsEvent, LogSettingsState> {
  final ILogSettingsRepository _repository;

  LogSettingsBloc({required ILogSettingsRepository repository})
      : _repository = repository,
        super(const LogSettingsState()) {
    on<LogSettingsFetched>(_onFetched);
    on<LogSettingsUpdated>(_onUpdated);
  }

  Future<void> _onFetched(
    LogSettingsFetched event,
    Emitter<LogSettingsState> emit,
  ) async {
    emit(state.copyWith(status: LogSettingsStatus.loading));
    final result = await _repository.getLogSettings();
    result.fold(
      (failure) => emit(state.copyWith(
        status: LogSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (settings) => emit(state.copyWith(
        status: LogSettingsStatus.loaded,
        settings: settings,
      )),
    );
  }

  Future<void> _onUpdated(
    LogSettingsUpdated event,
    Emitter<LogSettingsState> emit,
  ) async {
    emit(state.copyWith(status: LogSettingsStatus.saving));
    final result = await _repository.updateLogSettings(event.settings);
    result.fold(
      (failure) => emit(state.copyWith(
        status: LogSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (settings) => emit(state.copyWith(
        status: LogSettingsStatus.saved,
        settings: settings,
      )),
    );
  }
}
```

### 3.4 — Page

**`lib/presentation/features/log_settings/pages/log_settings_page.dart`** (nuovo file)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_bloc.dart';

class LogSettingsPage extends StatelessWidget {
  const LogSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LogSettingsBloc>()..add(LogSettingsFetched()),
      child: const _LogSettingsView(),
    );
  }
}

class _LogSettingsView extends StatelessWidget {
  const _LogSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.of(context).size.width <= 768
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    MainShell.mobileScaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: const Text('Impostazioni Log'),
      ),
      body: BlocConsumer<LogSettingsBloc, LogSettingsState>(
        listener: (context, state) {
          if (state.status == LogSettingsStatus.saved) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Impostazioni log salvate'),
                backgroundColor: AppTheme.accentColor,
              ));
          } else if (state.status == LogSettingsStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('Errore: ${state.errorMessage}'),
                backgroundColor: AppTheme.errorColor,
              ));
          }
        },
        builder: (context, state) {
          if (state.status == LogSettingsStatus.loading ||
              state.status == LogSettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.settings == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Impossibile caricare le impostazioni di log.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<LogSettingsBloc>().add(LogSettingsFetched()),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            );
          }
          return _LogSettingsForm(settings: state.settings!);
        },
      ),
    );
  }
}

class _LogSettingsForm extends StatefulWidget {
  final LogSettings settings;
  const _LogSettingsForm({required this.settings});

  @override
  State<_LogSettingsForm> createState() => _LogSettingsFormState();
}

class _LogSettingsFormState extends State<_LogSettingsForm> {
  late LogLevel _selectedLevel;
  late bool _fileLogging;
  late bool _consoleLogging;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.settings.logLevel;
    _fileLogging = widget.settings.enableFileLogging;
    _consoleLogging = widget.settings.enableConsoleLogging;
  }

  void _save() {
    context.read<LogSettingsBloc>().add(
          LogSettingsUpdated(LogSettings(
            logLevel: _selectedLevel,
            enableFileLogging: _fileLogging,
            enableConsoleLogging: _consoleLogging,
          )),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Livello di log
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Livello di Log',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...LogLevel.values.map((level) => RadioListTile<LogLevel>(
                      title: Text(level.name.toUpperCase()),
                      subtitle: Text(_levelDescription(level)),
                      value: level,
                      groupValue: _selectedLevel,
                      onChanged: (v) => setState(() => _selectedLevel = v!),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Output
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Output',
                    style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  title: const Text('Log su file'),
                  subtitle: const Text('Salva i log in un file sul server'),
                  value: _fileLogging,
                  onChanged: (v) => setState(() => _fileLogging = v),
                ),
                SwitchListTile(
                  title: const Text('Log su console'),
                  subtitle: const Text('Mostra i log nella console del server'),
                  value: _consoleLogging,
                  onChanged: (v) => setState(() => _consoleLogging = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Salva Impostazioni Log'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  String _levelDescription(LogLevel level) {
    switch (level) {
      case LogLevel.trace:   return 'Tutto (molto verboso)';
      case LogLevel.debug:   return 'Debug + info + warning + errori';
      case LogLevel.info:    return 'Info + warning + errori';
      case LogLevel.warning: return 'Solo warning ed errori';
      case LogLevel.error:   return 'Solo errori';
      case LogLevel.fatal:   return 'Solo errori fatali';
      default:               return '';
    }
  }
}
```

### 3.5 — DI Registration

**`lib/core/di/injection.dart`**

Aggiungere import:
```dart
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_bloc.dart';
```

Aggiungere nella sezione BLoC:
```dart
sl.registerFactory<LogSettingsBloc>(
  () => LogSettingsBloc(repository: sl()),
);
```

### 3.6 — Route

**`lib/core/routing/app_router.dart`**

Aggiungere import:
```dart
import 'package:neotradingbotfront1777/presentation/features/log_settings/pages/log_settings_page.dart';
```

Aggiungere route nella `ShellRoute.routes`:
```dart
GoRoute(
  path: '/log-settings',
  builder: (context, state) => const LogSettingsPage(),
),
```

### 3.7 — Navigation (main_shell.dart)

Aggiungere `NavigationRailDestination` nell'array `destinations` (dopo 'Impostazioni'):
```dart
NavigationRailDestination(
  icon: Icon(Icons.tune_outlined),
  selectedIcon: Icon(Icons.tune),
  label: Text('Log'),
),
```

Aggiungere `ListTile` nel `Drawer` (dopo il tile Impostazioni):
```dart
ListTile(
  leading: const Icon(Icons.tune_outlined),
  title: const Text('Log Settings'),
  selected: _calculateSelectedIndex(context) == 8,
  onTap: () {
    context.go('/log-settings');
    Navigator.pop(context);
  },
),
```

Aggiornare `_calculateSelectedIndex()` aggiungendo il mapping per `/log-settings`.

---

## Fase 4 — WebSocket Stats UI (S5)

> **Approccio**: integrare nella pagina TLS Diagnostics esistente invece di creare
> una pagina separata. Le WS Stats sono diagnostiche al pari del TLS.

Il backend ritorna `LogEntry` con `message` = stringa della mappa Dart
(es. `{streamCount: 2, reconnects: 0, recvWindowMs: 5000}`).

### File da modificare

**`lib/data/datasources/i_trading_remote_datasource.dart`**
*(già aggiunto in S3 Fase 2 — `getWebSocketStats()`)*

**`lib/data/datasources/trading_remote_datasource.dart`**
*(già implementato in S3)*

**`lib/presentation/features/diagnostics/pages/tls_diagnostics_page.dart`**

Aggiungere una sezione "WebSocket Stats" in fondo alla pagina esistente.

```dart
// Aggiungere alla fine del body (dopo la sezione TLS esistente):

// In initState (o come FutureBuilder nel build):
Future<void> _loadWsStats() async {
  final ds = sl<ITradingRemoteDatasource>();
  final result = await ds.getWebSocketStats();
  result.fold(
    (f) => setState(() => _wsStats = {'error': f.message}),
    (entry) {
      // Parsa la stringa mappa Dart in una Map
      try {
        final raw = entry.message
          .replaceAll('{', '')
          .replaceAll('}', '');
        final map = <String, String>{};
        for (final part in raw.split(',')) {
          final kv = part.trim().split(':');
          if (kv.length == 2) {
            map[kv[0].trim()] = kv[1].trim();
          }
        }
        setState(() => _wsStats = map);
      } catch (_) {
        setState(() => _wsStats = {'raw': entry.message});
      }
    },
  );
}

// Widget da aggiungere al body:
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.cable, color: AppTheme.accentColor),
          const SizedBox(width: 8),
          Text('WebSocket Stats',
              style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadWsStats,
            tooltip: 'Aggiorna statistiche WS',
          ),
        ]),
        const Divider(),
        if (_wsStats == null)
          const Center(child: CircularProgressIndicator())
        else
          ..._wsStats!.entries.map((e) => _kv(e.key, e.value)),
      ],
    ),
  ),
),
```

> `_kv()` è il metodo esistente in `TlsDiagnosticsPage` per mostrare coppie chiave/valore.
> `_wsStats` è una `Map<String, String>?` aggiunta come variabile di stato.

---

## Fase 5 — Backtest UI (S6)

> **Feature completa da creare ex-novo**. Il backend è pienamente funzionale.
>
> **Backend contract**:
> - `StartBacktest(StartBacktestRequest{symbol, startTime, endTime, initialBalance, settings}) → BacktestResponse{success, message, backtestId}`
> - `GetBacktestResults(GetBacktestResultsRequest{backtestId}) → BacktestResultsResponse{backtestId, totalProfit, profitPercentage, tradesCount, totalProfitStr, profitPercentageStr, totalFees, totalFeesStr, dcaTradesCount, trades}`

### Struttura target

```
lib/
├── domain/
│   ├── entities/
│   │   └── backtest_result.dart          (nuovo)
│   └── repositories/
│       └── i_backtest_repository.dart    (nuovo)
├── data/
│   ├── mappers/
│   │   └── backtest_result_mapper.dart   (nuovo)
│   └── repositories/
│       └── backtest_repository_impl.dart (nuovo)
└── presentation/
    └── features/
        └── backtest/
            ├── bloc/
            │   ├── backtest_bloc.dart     (nuovo)
            │   ├── backtest_event.dart    (nuovo)
            │   └── backtest_state.dart    (nuovo)
            └── pages/
                └── backtest_page.dart    (nuovo)
```

### 5.1 — Entity

**`lib/domain/entities/backtest_result.dart`** (nuovo file)

```dart
import 'package:neotradingbotfront1777/domain/entities/trade.dart';

class BacktestResult {
  final String backtestId;
  final double totalProfit;
  final double profitPercentage;
  final int tradesCount;
  final int dcaTradesCount;
  final double totalFees;
  final String totalProfitStr;
  final String profitPercentageStr;
  final String totalFeesStr;
  final List<Trade> trades;

  const BacktestResult({
    required this.backtestId,
    required this.totalProfit,
    required this.profitPercentage,
    required this.tradesCount,
    required this.dcaTradesCount,
    required this.totalFees,
    required this.totalProfitStr,
    required this.profitPercentageStr,
    required this.totalFeesStr,
    required this.trades,
  });
}
```

> `Trade` è già l'entity esistente (usata in `TradeHistory`).
> Verificare il nome esatto — potrebbe essere `AppTrade` nel backend, ma nel frontend
> si chiama `Trade` in `lib/domain/entities/trade.dart`.

### 5.2 — Repository Interface

**`lib/domain/repositories/i_backtest_repository.dart`** (nuovo file)

```dart
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/failures/failures.dart';

abstract class IBacktestRepository {
  Future<Either<Failure, String>> startBacktest({
    required String symbol,
    required int startTimeMs,
    required int endTimeMs,
    required double initialBalance,
  });

  Future<Either<Failure, BacktestResult>> getBacktestResults(String backtestId);
}
```

### 5.3 — Datasource Methods

**`lib/data/datasources/i_trading_remote_datasource.dart`**

Aggiungere:
```dart
// --- Backtest ---
Future<Either<Failure, BacktestResponse>> startBacktest({
  required String symbol,
  required int startTimeMs,
  required int endTimeMs,
  required double initialBalance,
});
Future<Either<Failure, BacktestResultsResponse>> getBacktestResults(
  String backtestId,
);
```

**`lib/data/datasources/trading_remote_datasource.dart`**

```dart
@override
Future<Either<Failure, BacktestResponse>> startBacktest({
  required String symbol,
  required int startTimeMs,
  required int endTimeMs,
  required double initialBalance,
}) =>
    _unaryCall(
      'startBacktest',
      (opts) => _client.startBacktest(
        StartBacktestRequest(
          symbol: symbol,
          startTime: Int64(startTimeMs),
          endTime: Int64(endTimeMs),
          initialBalance: initialBalance,
        ),
        options: opts,
      ),
      timeout: const Duration(minutes: 2), // Backtest può essere lento
    );

@override
Future<Either<Failure, BacktestResultsResponse>> getBacktestResults(
  String backtestId,
) =>
    _unaryCall(
      'getBacktestResults',
      (opts) => _client.getBacktestResults(
        GetBacktestResultsRequest(backtestId: backtestId),
        options: opts,
      ),
    );
```

> Aggiungere `import 'package:fixnum/fixnum.dart';` se non già presente.

### 5.4 — Mapper

**`lib/data/mappers/backtest_result_mapper.dart`** (nuovo file)

```dart
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/entities/trade.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

class BacktestResultMapper {
  static BacktestResult fromProto(grpc.BacktestResultsResponse proto) {
    return BacktestResult(
      backtestId: proto.backtestId,
      totalProfit: proto.totalProfit,
      profitPercentage: proto.profitPercentage,
      tradesCount: proto.tradesCount,
      dcaTradesCount: proto.dcaTradesCount,
      totalFees: proto.totalFees,
      totalProfitStr: proto.totalProfitStr.isNotEmpty
          ? proto.totalProfitStr
          : proto.totalProfit.toStringAsFixed(6),
      profitPercentageStr: proto.profitPercentageStr.isNotEmpty
          ? proto.profitPercentageStr
          : proto.profitPercentage.toStringAsFixed(4),
      totalFeesStr: proto.totalFeesStr.isNotEmpty
          ? proto.totalFeesStr
          : proto.totalFees.toStringAsFixed(6),
      trades: proto.trades.map(TradeMapper.fromProto).toList(),
    );
  }
}
```

> `TradeMapper` è il mapper esistente per `Trade`.
> Verificare il nome esatto in `lib/data/mappers/trade_mapper.dart`.

### 5.5 — Repository Implementation

**`lib/data/repositories/backtest_repository_impl.dart`** (nuovo file)

```dart
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/backtest_result_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/failures/failures.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';

class BacktestRepositoryImpl implements IBacktestRepository {
  final ITradingRemoteDatasource _datasource;

  BacktestRepositoryImpl({required ITradingRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<Failure, String>> startBacktest({
    required String symbol,
    required int startTimeMs,
    required int endTimeMs,
    required double initialBalance,
  }) async {
    final result = await _datasource.startBacktest(
      symbol: symbol,
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
      initialBalance: initialBalance,
    );
    return result.fold(
      Left.new,
      (response) => response.success
          ? Right(response.backtestId)
          : Left(UnexpectedFailure(message: response.message)),
    );
  }

  @override
  Future<Either<Failure, BacktestResult>> getBacktestResults(
      String backtestId) async {
    final result = await _datasource.getBacktestResults(backtestId);
    return result.fold(
      Left.new,
      (response) => Right(BacktestResultMapper.fromProto(response)),
    );
  }
}
```

### 5.6 — BLoC

**`lib/presentation/features/backtest/bloc/backtest_event.dart`** (nuovo file)

```dart
part of 'backtest_bloc.dart';

abstract class BacktestEvent {}

/// Avvia un backtest con i parametri forniti.
class BacktestStarted extends BacktestEvent {
  final String symbol;
  final DateTime startDate;
  final DateTime endDate;
  final double initialBalance;
  BacktestStarted({
    required this.symbol,
    required this.startDate,
    required this.endDate,
    required this.initialBalance,
  });
}

/// Carica i risultati di un backtest già eseguito.
class BacktestResultsRequested extends BacktestEvent {
  final String backtestId;
  BacktestResultsRequested(this.backtestId);
}

/// Reset dello stato.
class BacktestReset extends BacktestEvent {}
```

**`lib/presentation/features/backtest/bloc/backtest_state.dart`** (nuovo file)

```dart
part of 'backtest_bloc.dart';

enum BacktestStatus { initial, running, success, failure }

class BacktestState {
  final BacktestStatus status;
  final BacktestResult? result;
  final String? errorMessage;
  final String? currentBacktestId;

  const BacktestState({
    this.status = BacktestStatus.initial,
    this.result,
    this.errorMessage,
    this.currentBacktestId,
  });

  BacktestState copyWith({
    BacktestStatus? status,
    BacktestResult? result,
    String? errorMessage,
    String? currentBacktestId,
  }) =>
      BacktestState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
        currentBacktestId: currentBacktestId ?? this.currentBacktestId,
      );
}
```

**`lib/presentation/features/backtest/bloc/backtest_bloc.dart`** (nuovo file)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';

part 'backtest_event.dart';
part 'backtest_state.dart';

class BacktestBloc extends Bloc<BacktestEvent, BacktestState> {
  final IBacktestRepository _repository;

  BacktestBloc({required IBacktestRepository repository})
      : _repository = repository,
        super(const BacktestState()) {
    on<BacktestStarted>(_onStarted);
    on<BacktestResultsRequested>(_onResultsRequested);
    on<BacktestReset>(_onReset);
  }

  Future<void> _onStarted(
    BacktestStarted event,
    Emitter<BacktestState> emit,
  ) async {
    emit(state.copyWith(status: BacktestStatus.running, result: null));

    // Step 1: lancia backtest → ottieni backtestId
    final startResult = await _repository.startBacktest(
      symbol: event.symbol,
      startTimeMs: event.startDate.millisecondsSinceEpoch,
      endTimeMs: event.endDate.millisecondsSinceEpoch,
      initialBalance: event.initialBalance,
    );

    await startResult.fold(
      (failure) async => emit(state.copyWith(
        status: BacktestStatus.failure,
        errorMessage: failure.message,
      )),
      (backtestId) async {
        emit(state.copyWith(currentBacktestId: backtestId));
        // Step 2: recupera risultati
        final resultsResult = await _repository.getBacktestResults(backtestId);
        resultsResult.fold(
          (failure) => emit(state.copyWith(
            status: BacktestStatus.failure,
            errorMessage: failure.message,
          )),
          (result) => emit(state.copyWith(
            status: BacktestStatus.success,
            result: result,
          )),
        );
      },
    );
  }

  Future<void> _onResultsRequested(
    BacktestResultsRequested event,
    Emitter<BacktestState> emit,
  ) async {
    emit(state.copyWith(status: BacktestStatus.running));
    final result = await _repository.getBacktestResults(event.backtestId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: BacktestStatus.failure,
        errorMessage: failure.message,
      )),
      (r) => emit(state.copyWith(
        status: BacktestStatus.success,
        result: r,
      )),
    );
  }

  void _onReset(BacktestReset event, Emitter<BacktestState> emit) {
    emit(const BacktestState());
  }
}
```

### 5.7 — Page UI

**`lib/presentation/features/backtest/pages/backtest_page.dart`** (nuovo file)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/core/utils/price_formatter.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_bloc.dart';

class BacktestPage extends StatelessWidget {
  const BacktestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BacktestBloc>(),
      child: const _BacktestView(),
    );
  }
}

class _BacktestView extends StatefulWidget {
  const _BacktestView();

  @override
  State<_BacktestView> createState() => _BacktestViewState();
}

class _BacktestViewState extends State<_BacktestView> {
  late String _symbol;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final _balanceController = TextEditingController(text: '1000');

  @override
  void initState() {
    super.initState();
    _symbol = sl<SymbolContext>().activeSymbol;
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _runBacktest() {
    final balance = double.tryParse(_balanceController.text);
    if (balance == null || balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un saldo iniziale valido')),
      );
      return;
    }
    context.read<BacktestBloc>().add(BacktestStarted(
          symbol: _symbol,
          startDate: _startDate,
          endDate: _endDate,
          initialBalance: balance,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.of(context).size.width <= 768
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    MainShell.mobileScaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: const Text('Backtest Strategia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Form parametri ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parametri Backtest',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    // Simbolo (read-only — usa simbolo attivo)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.currency_bitcoin),
                      title: const Text('Simbolo'),
                      trailing: Text(
                        _symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                    const Divider(),
                    // Data inizio
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Data Inizio'),
                      trailing: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _pickDate(true),
                    ),
                    // Data fine
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Data Fine'),
                      trailing: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _pickDate(false),
                    ),
                    const Divider(),
                    // Saldo iniziale
                    TextField(
                      controller: _balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Saldo Iniziale (USDT)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pulsante avvia
                    BlocBuilder<BacktestBloc, BacktestState>(
                      builder: (context, state) {
                        final isRunning =
                            state.status == BacktestStatus.running;
                        return ElevatedButton.icon(
                          onPressed: isRunning ? null : _runBacktest,
                          icon: isRunning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(isRunning
                              ? 'Backtest in corso...'
                              : 'Avvia Backtest'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- Risultati ---
            BlocConsumer<BacktestBloc, BacktestState>(
              listener: (context, state) {
                if (state.status == BacktestStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Errore: ${state.errorMessage}'),
                    backgroundColor: AppTheme.errorColor,
                  ));
                }
              },
              builder: (context, state) {
                if (state.status == BacktestStatus.success &&
                    state.result != null) {
                  return _BacktestResults(result: state.result!);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BacktestResults extends StatelessWidget {
  final dynamic result; // BacktestResult

  const _BacktestResults({required this.result});

  @override
  Widget build(BuildContext context) {
    final profitColor = result.totalProfit >= 0
        ? Colors.greenAccent
        : AppTheme.errorColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Risultati', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // KPI card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kpiRow(context, 'Profitto Netto',
                    '${result.totalProfitStr.isNotEmpty ? result.totalProfitStr : result.totalProfit.toStringAsFixed(4)} USDT',
                    profitColor),
                _kpiRow(context, 'Rendimento %',
                    '${result.profitPercentageStr.isNotEmpty ? result.profitPercentageStr : result.profitPercentage.toStringAsFixed(2)}%',
                    profitColor),
                _kpiRow(context, 'Fee Totali',
                    '${result.totalFeesStr.isNotEmpty ? result.totalFeesStr : result.totalFees.toStringAsFixed(4)} USDT',
                    AppTheme.mutedTextColor),
                _kpiRow(context, 'Trade Totali',
                    result.tradesCount.toString(), null),
                _kpiRow(context, 'Trade DCA',
                    result.dcaTradesCount.toString(), null),
                _kpiRow(context, 'ID Backtest',
                    result.backtestId, AppTheme.mutedTextColor),
              ],
            ),
          ),
        ),
        if (result.trades.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Storico Trade Simulati (${result.trades.length})',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.trades.length > 50
                  ? 50
                  : result.trades.length, // max 50 righe
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final trade = result.trades[i];
                final isBuy = trade.isBuyer ?? false;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isBuy ? Colors.greenAccent : AppTheme.errorColor,
                    size: 18,
                  ),
                  title: Text(
                    '${isBuy ? "BUY" : "SELL"} @ ${PriceFormatter.format(trade.price)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Text(
                    trade.qty.toStringAsFixed(4),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          if (result.trades.length > 50)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... e altri ${result.trades.length - 50} trade non mostrati',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.mutedTextColor),
              ),
            ),
        ],
      ],
    );
  }

  Widget _kpiRow(
      BuildContext context, String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.textColor,
              )),
        ],
      ),
    );
  }
}
```

### 5.8 — DI Registration

**`lib/core/di/injection.dart`**

Aggiungere import:
```dart
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';
import 'package:neotradingbotfront1777/data/repositories/backtest_repository_impl.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_bloc.dart';
```

Aggiungere nella sezione Repositories:
```dart
sl.registerLazySingleton<IBacktestRepository>(
  () => BacktestRepositoryImpl(datasource: sl()),
);
```

Aggiungere nella sezione BLoC:
```dart
sl.registerFactory<BacktestBloc>(
  () => BacktestBloc(repository: sl()),
);
```

### 5.9 — Route

**`lib/core/routing/app_router.dart`**

```dart
import 'package:neotradingbotfront1777/presentation/features/backtest/pages/backtest_page.dart';

// Aggiungere nella ShellRoute.routes:
GoRoute(
  path: '/backtest',
  builder: (context, state) => const BacktestPage(),
),
```

### 5.10 — Navigation (main_shell.dart)

Aggiungere `NavigationRailDestination` (dopo Diagnostica):
```dart
NavigationRailDestination(
  icon: Icon(Icons.analytics_outlined),
  selectedIcon: Icon(Icons.analytics),
  label: Text('Backtest'),
),
```

Aggiungere `ListTile` nel Drawer:
```dart
ListTile(
  leading: const Icon(Icons.analytics_outlined),
  title: const Text('Backtest'),
  selected: _calculateSelectedIndex(context) == 9,
  onTap: () {
    context.go('/backtest');
    Navigator.pop(context);
  },
),
```

Aggiornare `_calculateSelectedIndex()` per gestire il path `/backtest`.

---

## Checklist Implementazione

### Fase 1 — Mapping Dati (S1 + S2)
- [ ] S1.1: Aggiungere `List<String> warnings` a `strategy_state.dart`
- [ ] S1.2: Implementare `_extractWarnings()` in `strategy_state_mapper.dart`
- [ ] S1.3: Aggiungere badge RECOVERING in `strategy_state_card_content.dart`
- [ ] S2.1: Aggiungere fee fields a `symbol_limits.dart`
- [ ] S2.2: Mappare fee fields in `symbol_limits_mapper.dart`
- [ ] S2.3: Mostrare fee fields nell'UI ordini/simbolo

### Fase 2 — Architettura (S3)
- [ ] S3.1: Aggiungere 4 metodi a `i_trading_remote_datasource.dart`
- [ ] S3.2: Implementare 4 metodi in `trading_remote_datasource.dart`
- [ ] S3.3: Refactoring `fee_repository_impl.dart` → usa datasource
- [ ] S3.4: Aggiornare DI per `FeeRepositoryImpl`
- [ ] S3.5: Aggiornare `trading_control_panel.dart` → usa datasource

### Fase 3 — LogSettings UI (S4)
- [ ] S4.1: Creare `log_settings_event.dart`
- [ ] S4.2: Creare `log_settings_state.dart`
- [ ] S4.3: Creare `log_settings_bloc.dart`
- [ ] S4.4: Creare `log_settings_page.dart`
- [ ] S4.5: Registrare `LogSettingsBloc` in DI
- [ ] S4.6: Aggiungere route `/log-settings`
- [ ] S4.7: Aggiungere voce nav in `main_shell.dart`

### Fase 4 — WS Stats (S5)
- [ ] S5.1: Aggiungere WS stats section in `tls_diagnostics_page.dart`

### Fase 5 — Backtest UI (S6)
- [ ] S6.1: Creare `backtest_result.dart` (entity)
- [ ] S6.2: Creare `i_backtest_repository.dart`
- [ ] S6.3: Aggiungere metodi backtest a datasource interface + impl
- [ ] S6.4: Creare `backtest_result_mapper.dart`
- [ ] S6.5: Creare `backtest_repository_impl.dart`
- [ ] S6.6: Creare BLoC (event + state + bloc)
- [ ] S6.7: Creare `backtest_page.dart`
- [ ] S6.8: Registrare repository + BLoC in DI
- [ ] S6.9: Aggiungere route `/backtest`
- [ ] S6.10: Aggiungere voce nav in `main_shell.dart`

---

## Note Importanti

### Ordine di implementazione consigliato
Seguire le fasi nell'ordine indicato (S1 → S2 → S3 → S4 → S5 → S6):
- S3 deve precedere S4 e S6 perché entrambi dipendono dai nuovi metodi datasource
- S1 e S2 sono indipendenti e possono essere fatti in parallelo

### Verifica import gRPC
I nomi esatti dei tipi gRPC generati dipendono dalla versione del proto compilato.
Verificare in `lib/generated/proto/trading/v1/trading_service.pb.dart`:
- `AvailableSymbolsResponse` vs `GetAvailableSymbolsResponse`
- `SymbolFeesResponse` vs `GetSymbolFeesResponse`
- `AllSymbolFeesResponse` vs `GetAllSymbolFeesResponse`
- `BacktestResponse` vs `StartBacktestResponse`
- `GetBacktestResultsRequest` — verificare nome esatto

### Trade entity nel backtest
Il tipo `Trade` nel frontend potrebbe non avere il campo `isBuyer`.
Verificare `lib/domain/entities/trade.dart` e adattare `_BacktestResults` di conseguenza.

### Timeout backtest
`startBacktest` usa `timeout: const Duration(minutes: 2)` perché il backend
esegue la simulazione sincrona. Verificare che il timeout lato backend non sia
inferiore (attualmente usa il timeout default di 30s in `_unaryCall`).

### `_calculateSelectedIndex` in main_shell.dart
Aggiornare i path mappings per includere `/log-settings` e `/backtest`
con i nuovi indici corrispondenti.

