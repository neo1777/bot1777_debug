# Sviluppo e Testing — NeoTradingBot 1777

## Suite di Test

### Metriche Aggiornate

| Progetto | File Test | Test Pass | Test Skip |
|----------|-----------|-----------|-----------|
| Backend  | 42        | 442+      | 0         |
| Frontend | 21        | ~90       | 2         |
| **Totale** | **63**  | **530+**  | **2**     |

I 2 skip frontend sono bug di design documentati (vedi sezione Bug Noti).

### Backend — Test Core (42 file)

**Domain Services** (11 file):
- `VolatilityService`: 21 test — volatilità, edge case, performance
- `FeeCalculationService`: 27 test — maker/taker, discount, multi-simbolo
- `TradeValidationService`: 23 test — `roundUpToStep`, `validateAndFormatQuantity`
- `TradeEvaluatorService`: 8 file — concurrency, stress, edge case, stato corrotto, DCA

**Application Layer** (9 file):
- Use case atomici: buy, sell, start strategy, trading loop
- Test concorrenza, race condition, circuit breaker
- `AtomicStateManager`: race condition tests

**Core Layer** (10 file):
- `DecimalUtils`, `DecimalCompare`, `JsonParser`
- Stress test: concurrency, memory, performance, data validation

**Infrastructure** (3 file):
- `BinanceApiClient`, `ApiServiceKlines`, `StrategyStateRepository`

### Frontend — Test (21 file)

**BLoC Tests**:
- `PriceBlocReal` (11 test, 9 pass, 2 skip) — subscribe, unsubscribe, error handling
- `TradeHistoryBloc` (21 test) — load, refresh, filtri, streaming
- `StrategyControlBloc` (7 file) — integration, gRPC, recovery, race condition
- `SystemLogBloc` — test completi

**Widget Tests**:
- `strategy_state_card_content_test.dart` — stati: loading, posizione aperta, P&L, errore
- `strategy_state_card_stress_test.dart` — aggiornamenti rapidi senza glitch
- `strategy_control_widget_test.dart` — interazioni utente

## Esecuzione Test

```bash
# Backend (dalla directory neotradingbotback1777)
dart test

# Frontend (dalla directory neotradingbotfront1777)
flutter test

# Singola categoria
dart test test/domain/services/volatility_service_test.dart
flutter test test/presentation/blocs/

# Con coverage
dart test --coverage=coverage
flutter test --coverage
```

## Dipendenze di Test

```yaml
# Backend
dev_dependencies:
  test: ^1.24.0
  mockito: ^5.4.0
  build_runner: ^2.4.0

# Frontend
dev_dependencies:
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
  flutter_test:
    sdk: flutter
```

### Generazione Mock (solo Backend)

```bash
cd neotradingbotback1777
dart run build_runner build --delete-conflicting-outputs
```

## Policy di Code Review

### Regole Generali

| Tipo Modifica | Requisito |
| :--- | :--- |
| Nuova feature | Unit test obbligatori |
| Bug fix | Test di regressione che riproduce il bug |
| Widget complesso (con logica o stati multipli) | Widget Test o Golden Test |

### Struttura e Naming

- **Pattern AAA**: `// ARRANGE`, `// ACT`, `// ASSERT` chiaramente separati
- **Naming Backend**: `[BACKEND-TEST-001] should return valid price`
- **Naming Frontend**: `[FRONTEND-TEST-001] descrizione comportamento`
- **File Test**: devono rispecchiare struttura `lib/`. Es: `lib/services/auth.dart` → `test/services/auth_test.dart`

### Qualità del Codice di Test

- **No Logic**: Test senza `if`/loop complessi — estrarre in helper se necessario
- **Mocking**: `mocktail` (Frontend), `mockito` (Backend); reset in `setUp`
- **Assertion**: Un test verifica UNA cosa specifica; evitare "assertion roulette"

### Gestione Flaky Tests

Un test è **flaky** se fallisce in CI ma passa localmente (o viceversa).

1. **Causa tipica**: `Future.delayed`, race conditions, stato condiviso
2. **Fix**: Usa `pump`/`pumpAndSettle` Flutter invece di `Future.delayed`
3. **Se non risolvibile subito**: `@Tags(['flaky'])` + Issue dedicata

### Performance

- Test unitari: < 100ms ciascuno
- Test pesanti (benchmark, integrazione): gruppo separato o tag `slow`/`integration`

### Checklist Review

- [ ] Test coprono i casi limite (edge case)?
- [ ] Nomi test descrittivi?
- [ ] Nessuna dipendenza non necessaria?
- [ ] Il test fallisce se la logica viene rotta?
- [ ] Mock puliti nel `tearDown`?

## Bug di Design Noti

1. **PriceBlocReal emit-after-complete**: `_onSubscribeToPriceUpdates` crea un `.listen()` il cui callback chiama `emit()` dopo che l'event handler è già completato → `AssertionError('!_isCompleted')`. 2 test skippati.

2. **TradeHistoryLoaded.copyWith**: Usa `??` per campi nullable — passare `null` non resetta il campo, impedendo a `ClearFilters` di cancellare i metadati dei filtri.

## Roadmap Testing

- [ ] Migrazione backend mocks da `mockito` → `mocktail`
- [ ] Frontend: mapper tests (10/11 non testati)
- [ ] Frontend: repository tests (0/10)
- [ ] Test integrazione E2E completi
- [ ] Test sicurezza e vulnerabilità

