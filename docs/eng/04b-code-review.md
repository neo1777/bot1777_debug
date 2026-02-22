# Policy di Code Review per i Test

## Obiettivo
Garantire che ogni modifica al codice mantenga o migliori la qualità, l'affidabilità e la manutenibilità della suite di test del progetto `neotradingbot1777`.

## 1. Copertura e Scope
- **Nuove Features**: Ogni nuova funzionalità DEVE essere accompagnata da Unit Test.
- **Bug Fix**: Ogni bug fix DEVE includere un test di regressione che riproduce il bug (inizialmente fallendo) e poi passa con il fix.
- **UI/Widget**: I widget Flutter complessi (con logica o stati multipli) devono avere Widget Test o Golden Test.

## 2. Struttura e Naming
Rispettare scrupolosamente le convenzioni definite in `test/README.md` (Backend e Frontend).
- **Pattern AAA**: Arrange, Act, Assert devono essere chiaramente separati visivamente.
- **Naming**: `[AREA-ID] Descrizione del comportamento atteso`. Esempio: `[BACKEND-TEST-001] should return valid price`.
- **File Test**: Devono rispecchiare la struttura della cartella `lib/`. Esempio: `lib/services/auth_service.dart` -> `test/services/auth_service_test.dart`.

## 3. Qualità del Codice di Test
- **No Logic in Tests**: I test NON devono contenere logica condizionale (if, loops complessi). Se necessaria, estrarla in helper methods.
- **Mocking**:
  - Usare `mocktail` (Frontend) o `mockito` (Backend).
  - Non mockare classi che sono puramente dati (Enitites/DTOs semplici).
  - Resettare i mock in `setUp` per evitare inquinamento tra test.
- **Assertion**:
  - Un test deve verificare UNA cosa specifica (o un gruppo coeso di asserzioni).
  - Evitare "Assertion Roulette" (troppe asserzioni senza messaggi chiari).

## 4. Gestione Flaky Tests
- Se un test fallisce in CI ma passa localmente (o viceversa), è considerato **Flaky**.
- **Azione Immediata**: Identificare la causa (spesso `Future.delayed`, race conditions, o stato condiviso).
- **Fix**: Usare sincronizzazione deterministica (es. `pump`, `pumpAndSettle` in Flutter) invece di `Future.delayed` quando possibile.
- Se non risolvibile immediatamente, marcare con `@Tags(['flaky'])` e aprire una Issue dedicata.

## 5. Performance
- I test unitari devono essere veloci (< 100ms).
- I test di benchmark o integrazione pesanti devono essere in group separati o taggati come `slow` o `integration`.

## 6. Review Checklist
Il reviewer deve verificare:
- [ ] I test coprono i casi limite (edge cases)?
- [ ] I nomi dei test sono descrittivi?
- [ ] Non ci sono dipendenze non necessarie?
- [ ] Il test fallisce se la logica viene rotta?
- [ ] Pulizia dei mock nel `tearDown` se necessario?
