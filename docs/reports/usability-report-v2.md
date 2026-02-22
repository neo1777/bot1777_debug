# Report Usabilità Frontend — Revisione Completa v2

> Data: 2026-02-19
> Scope: `neotradingbotfront1777/lib/presentation/` — analisi focalizzata sull'esperienza utente
> Stato precedente: 24 issue chiuse (7 critici + 11 significativi + 6 minori → tutti risolti)
> Questa revisione identifica nuovi gap di **usabilità** emersi o rimasti dopo le correzioni.

---

## Legenda severità

| Simbolo | Significato |
|---------|-------------|
| 🔴 | **Critico** — può causare perdita dati / operazioni involontarie / confusione grave |
| 🟠 | **Significativo** — degrada l'esperienza in uso quotidiano |
| 🟡 | **Minore** — piccola incoerenza o miglioramento estetico |

---

## 🔴 PROBLEMI CRITICI DI USABILITÀ

### U1 — STOP senza dialogo di conferma

**File:** `trading_control_panel.dart:621-626`

```dart
void _handleStopStrategy() {
  setState(() => _activeOp = _ActiveOp.stop);
  context.read<StrategyControlBloc>().add(
    StopStrategyRequested(_selectedSymbol),
  );
}
```

**Problema:** Il pulsante STOP invia il comando immediatamente senza nessuna richiesta di conferma. STOP interrompe la strategia in modo definitivo, potenzialmente con trade aperti in corso. Confronto: `orders_page.dart:196-235` mostra `_showCancelAllDialog` con testo esplicito e doppio step di conferma per "Cancella Tutti gli Ordini". La stessa cautela deve essere applicata a STOP.

**Impatto utente:** Click accidentale → stop immediato del bot → posizioni aperte abbandonate senza gestione.

---

### U2 — Warning message raw del server mostrato all'utente

**File:** `strategy_state_card_content.dart:53-98` e `trading_control_panel.dart:541-574`

Nella card "Stato Strategia", il widget `_buildAutoStopPill` analizza correttamente il formato `AUTO_STOP_IN_CYCLES;remaining=5` e mostra la pill "⏱ Cicli rimanenti: 5". **Tuttavia** il blocco immediatamente successivo (linee 53-98) mostra anche il `warningMessage` grezzo nella warning box:

```
⚠ AUTO_STOP_IN_CYCLES;remaining=5
```

L'utente vede quindi **due widget** per lo stesso messaggio: la pill user-friendly e la stringa tecnica raw. Nel `TradingControlPanel` il raw è mostrato senza alcuna pill.

**Impatto utente:** Il trading bot è usato anche da persone non tecniche. Stringa come `AUTO_STOP_IN_CYCLES;remaining=5` o `RECOVERING;no_active_isolate` sono incomprensibili e creano ansia.

---

### U3 — Status della strategia in inglese nella card "Stato Strategia"

**File:** `strategy_state_card_content.dart:36-37`

```dart
_buildInfoRow(
  'Stato:',
  displayState.status.name.toUpperCase(),  // → IDLE, RUNNING, PAUSED, ERROR
  ...
),
```

Il `TradingControlPanel` nella stessa dashboard traduce correttamente gli stessi valori:
- `running` → `ATTIVA`
- `paused` → `IN PAUSA`
- `idle` → `INATTIVA`
- `error` → `ERRORE`

Ma la card "Stato Strategia" mostra `IDLE`, `RUNNING`, `PAUSED`, `ERROR` — inglese — sulla stessa schermata. Un utente italiano vede due rappresentazioni dello stesso stato in due lingue diverse.

**Impatto utente:** Incoerenza linguistica nella pagina più importante dell'app.

---

### U4 — Log di sistema senza timestamp

**File:** `system_logs_page.dart:287-308`

Il renderer di ogni log entry mostra: `[LEVEL] (serviceName)` + `message`. **Nessun timestamp**.

Per un trading bot dove l'ordine temporale degli eventi è critico (es. "il BUY è avvenuto prima o dopo il STOP?"), l'assenza di timestamp rende i log quasi inutilizzabili per il debug. Il dominio `SystemLog` quasi certamente ha un campo `timestamp` o `createdAt` disponibile.

**Impatto utente:** Impossibile determinare quando è avvenuto un evento. Debug criticamente limitato.

---

### U5 — Double Scaffold nella pagina Testnet

**File:** `testnet_monitoring_page.dart:18-112`

```dart
return Scaffold(          // ← Scaffold esterno (wrapper)
  backgroundColor: ...,
  body: BlocBuilder<SettingsBloc, ...>(
    builder: (context, settingsState) {
      return Scaffold(    // ← Scaffold interno (reale)
        appBar: AppBar(...),
        body: SingleChildScrollView(...),
      );
    },
  ),
);
```

Il `Scaffold` esterno avvolge un `BlocBuilder` che restituisce un secondo `Scaffold` con `appBar`. Questo è un antipattern Flutter noto che causa:
- Conflitti con `MediaQuery.padding` (doppio safe area)
- `SnackBar` che potrebbero apparire sullo scaffold sbagliato
- Problemi con drawer e overlay

**Fix corretto:** spostare il `BlocBuilder` nel `body` di un singolo Scaffold, o costruire l'`AppBar` condizionalmente.

---

## 🟠 PROBLEMI SIGNIFICATIVI

### U6 — "PAUSE" e "RESUME" in inglese, resto dell'app in italiano

**File:** `trading_control_panel.dart:341`

```dart
label: isPaused ? 'RESUME' : 'PAUSE',
```

Il pannello di controllo mostra: `START` / `RIAVVIA` · `PAUSE` / `RESUME` · `STOP`. Due pulsanti su tre sono italiani/neutri, due sono inglesi. Incoerenza linguistica nell'elemento di controllo più critico dell'app.

**Proposta:** `isPaused ? 'RIPRENDI' : 'PAUSA'`

---

### U7 — Pulsante "SALVA IMPOSTAZIONI" non accessibile su mobile

**File:** `settings_form.dart:401-444`

Il bottone è posizionato in fondo al form, dopo 6 card di impostazioni in `GridView`. Su mobile con 1 colonna e `childAspectRatio: 1.0`:
- Ogni card è ~400×400px = 400px di altezza
- 6 card = **2400px di scroll** prima di raggiungere il tasto SALVA

C'è un FAB "Torna su" (`settings_page.dart:239`) ma nessun "Quick Save" sticky. L'utente modifica una setting, poi deve scrollare a fondo per salvare, o non sapere che c'è un tasto lì.

**Fix proposto:** Aggiungere un secondo FAB "Salva" (es. `Icons.save` in `AppTheme.accentColor`), oppure rendere il pulsante sticky in fondo allo schermo.

---

### U8 — Cambio simbolo senza conferma con bot in esecuzione

**File:** `trading_control_panel.dart:280-295`

Selezionare un nuovo simbolo dal dropdown provoca immediatamente:
1. `SymbolContext.setActiveSymbol(newValue)` — cambia simbolo globale
2. `PriceBlocReal.add(SubscribeToPriceUpdates(newValue))` — cambia feed prezzi
3. `TradeHistoryBloc.add(LoadTradeHistory(newValue))` — cambia storico
4. `StrategyStateBloc.add(SymbolChanged(newValue))` — cambia stream strategia

Se il bot è `running` su BTCUSDC e l'utente seleziona ETHUSDC per sbaglio, il monitoraggio cambia mentre le posizioni aperte su BTC rimangono senza visualizzazione. Nessun warning, nessuna conferma.

---

### U9 — "Pulisci" log senza conferma

**File:** `system_logs_page.dart:152-158`

```dart
IconButton(
  tooltip: 'Pulisci',
  onPressed: () => context.read<SystemLogBloc>().add(
    const SystemLogClearRequested(),
  ),
),
```

I log vengono cancellati istantaneamente senza conferma. I log sono l'unica fonte di debug in tempo reale. Cancellazione accidentale durante un'analisi di un problema è un'operazione non reversibile.

---

### U10 — Card "Stato Strategia" mostra 0.000000 invece di "—" per stato idle

**File:** `strategy_state_card_content.dart:40-51`

Con strategia non avviata, la card mostra:
```
Prezzo Medio Acquisto:  0.000000
Trade Aperti:           0
Profitto Cumulativo:    0.00 $
```

Il `_isDefaultState()` (linea 283) rileva già questo caso e mostra la pill "Strategia non ancora avviata." ma i valori 0 rimangono visibili sopra. La `StrategyTargetsCard` nella stessa dashboard usa correttamente `'—'` per tutti i valori non disponibili. Incoerenza visiva tra due card sulla stessa schermata.

---

### U11 — Prezzi e target nella `StrategyTargetsCard` sempre con 6 decimali

**File:** `strategy_targets_card.dart:185, 321, 337, 355, 385`

```dart
'\$${currentPrice.toStringAsFixed(6)}'
'\$${tpTarget.toStringAsFixed(6)}'
'\$${slTarget.toStringAsFixed(6)}'
```

Per BTC a $97,000, l'utente vede: `$97000.000000`. Per ETH a $3,000: `$3000.000000`. La `PriceDisplayCard` ha già implementato `_formatPrice()` con logica adattiva (2/4/8 decimali). La stessa funzione non è condivisa tra i widget.

---

### U12 — Settings: nessun avviso per navigazione con modifiche non salvate

**File:** `settings_form.dart`

Il form ha `~15 TextEditingController` e vari bool. Se l'utente modifica campi e naviga ad un'altra sezione (via drawer o NavigationRail), le modifiche vanno perse silenziosamente. Non c'è dirty state tracking né dialog "Modifiche non salvate".

Per un'app finanziaria dove le impostazioni impattano direttamente il trading, questo è un gap significativo.

---

### U13 — Testnet: bilanci mostrati con 8 decimali fissi

**File:** `testnet_monitoring_page.dart:314`

```dart
subtitle: Text(
  'Disponibile: ${balance.free.toStringAsFixed(8)}',
),
```

`0.00000000` per asset in idle, `97543.12345678` per USDC. Stessa carenza della TargetsCard: dovrebbe usare la stessa logica adattiva di `PriceDisplayCard._formatPrice()`.

---

### U14 — Auto-scroll dei log: `jumpTo(0)` brusco

**File:** `system_logs_page.dart:175`

```dart
listener: (context, state) {
  if (state.autoScroll && _scrollController.hasClients) {
    _scrollController.jumpTo(0);
  }
},
```

`jumpTo` è un salto istantaneo senza animazione. Con log che arrivano frequentemente (es. ogni secondo), la lista "teletrasporta" continuamente. `animateTo(0, duration: ...)` sarebbe molto più leggibile, oppure uno scroll soft debounced.

---

## 🟡 PROBLEMI MINORI

### U15 — `_kv()` in TLS Diagnostics con larghezza fissa 210px

**File:** `tls_diagnostics_page.dart:139-145`

```dart
SizedBox(
  width: 210,
  child: Text(key, ...),
),
```

Su schermi molto stretti (320-360px), la label da 210px + valore `Expanded` causa layout stretto. Preferire `Flexible(flex: 2)` per la label e `Flexible(flex: 3)` per il valore.

---

### U16 — Tooltip duplicato sull'icona visibilità avvisi

**File:** `trading_control_panel.dart:194-208`

```dart
Tooltip(
  message: _showWarnings ? 'Nascondi avvisi' : 'Mostra avvisi',  // ← tooltip esterno
  child: IconButton(
    ...
    tooltip: _showWarnings ? 'Nascondi avvisi' : 'Mostra avvisi', // ← tooltip interno (ridondante)
  ),
),
```

Il `Tooltip` widget esterno ha priorità e sovrascrive `IconButton.tooltip`. Il tooltip interno è dead code.

---

### U17 — Diagnostica TLS: titolo senza icona gradient (inconsistenza visiva)

**File:** `tls_diagnostics_page.dart:74-76`

```dart
title: const Text('Diagnostica TLS / gRPC'),
```

Tutte le altre pagine usano: `Row([GradientIconContainer(icon), SizedBox(12), Text(title)])`. La pagina TLS ha solo il `Text` plain, rompendo la coerenza visiva dell'app.

---

### U18 — Auto-scroll: label senza contesto per l'utente

**File:** `system_logs_page.dart:139-149`

Il toggle `Auto‑scroll` non indica la direzione (scrolla all'inizio = log più recenti in cima? o alla fine?). Aggiungere un tooltip `'Scorri automaticamente ai log più recenti'` chiarirebbe il comportamento.

---

### U19 — `_maxCyclesController` doppia inizializzazione

**File:** `settings_form.dart:130, 147`

```dart
_maxCyclesController = TextEditingController(text: '0');  // init 1
...
_maxCyclesController.text = settings.maxCycles.toString(); // init 2
```

Non è un bug (la seconda sovrascrive la prima prima del primo frame), ma è codice confuso. Inizializzare direttamente con il valore corretto.

---

## Riepilogo

| Priorità | Numero | Issue |
|----------|--------|-------|
| 🔴 Critici | 5 | U1, U2, U3, U4, U5 |
| 🟠 Significativi | 9 | U6, U7, U8, U9, U10, U11, U12, U13, U14 |
| 🟡 Minori | 5 | U15, U16, U17, U18, U19 |
| **Totale** | **19** | |

---

## Aspetti Positivi Confermati

Le seguenti issue precedentemente segnalate sono correttamente risolte e funzionano bene:

- ✅ Hamburger button su mobile — presente in tutte le 8 pagine
- ✅ NavigationRail e Drawer in ordine coerente
- ✅ `SettingsBloc` singola istanza via `AppDependenciesProvider`
- ✅ `_ActiveOp` enum per loading state per-button
- ✅ `_formatPrice()` adattivo in `PriceDisplayCard` (ma non condiviso)
- ✅ Tooltip "24H" con spiegazione
- ✅ AppBar in `SystemLogsPage`
- ✅ `Wrap` per filtri log (niente overflow)
- ✅ Loader condizionale (mostra solo se ci sono più log)
- ✅ `ProfitChartWidget` reale al posto del placeholder gradiente
- ✅ AppBar standard in Testnet (no più SliverAppBar isolato)
- ✅ `inferredSecureRequested` dinamico in TLS
- ✅ `_buildAutoStopPill` che traduce `AUTO_STOP_IN_CYCLES` in pill leggibile
- ✅ `SwitchListTile` "Ferma alla prossima vendita" con tooltip
- ✅ Pulse animation sul prezzo in `PriceDisplayCard`
- ✅ Error page tematizzata con `ElevatedButton` → Dashboard

