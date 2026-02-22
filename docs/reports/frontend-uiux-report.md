# REPORT UI/UX — neotradingbotfront1777

**Data analisi:** 18 febbraio 2026
**Scope:** Analisi statica completa del codice Flutter frontend (sola lettura, nessuna modifica)
**Versione app:** Flutter + BLoC + go_router + gRPC

---

## 1. PANORAMICA GENERALE

L'app è un pannello di controllo per trading bot su Binance, con architettura Flutter BLoC + go_router + gRPC. Il tema visivo è ispirato a "Solo Leveling" — dark mode con palette viola/cyan su sfondo quasi nero. L'approccio architetturale è solido (Clean Architecture, BLoC, ShellRoute), ma l'analisi rivela **problemi significativi di UX, inconsistenze visive, bug comportamentali e antipattern di performance**.

---

## 2. DESIGN SYSTEM & TEMA

### Punti di forza

- `AppTheme` è centralizzato e ben strutturato con Material 3 (`useMaterial3: true`)
- Palette semantica coerente: success (verde `#10B981`), warning (arancione `#F59E0B`), error (rosso `#EF4444`)
- Gradienti `primaryGradient` usati uniformemente nelle AppBar icon degli header di pagina
- Font mix intenzionale: **Orbitron** per titoli (sci-fi), **Roboto** per body (leggibilità)
- `BoxShadow` con `primaryColor.withValues(alpha: 0.3)` per effetto glow coerente

### Problemi

#### P1 — Font Orbitron usato sui bottoni di controllo a fontSize 9

Orbitron è un font display a spaziatura larga, ottimo per titoli. Usarlo per label dei bottoni (`ElevatedButton`, `OutlinedButton`, `TextButton`) lo rende difficile da leggere in piccolo. In `_buildControlButton` i label dei trading controls usano `fontSize: 9` con Orbitron — ai limiti dell'illeggibilità.

```dart
// trading_control_panel.dart:404-409
style: Theme.of(context).textTheme.bodySmall?.copyWith(
  color: enabled ? color : AppTheme.mutedTextColor,
  fontWeight: FontWeight.w700,
  fontSize: 9,   // ← TROPPO PICCOLO per un font condensed come Orbitron
),
```

#### P2 — Manca un light theme

Solo `darkTheme` è definito. Nessuna possibilità di light mode. Per una dashboard professionale, offrire l'alternativa light sarebbe standard.

---

## 3. NAVIGAZIONE & STRUTTURA

### B1 — Ordine voci INVERTITO tra NavigationRail e Drawer (BUG CRITICO)

Nel `NavigationRail` (desktop, >768px) l'ordine è:

```
0: Dashboard | 1: Testnet | 2: Account | 3: Ordini | 4: Storico | 5: Log | 6: Impostazioni | 7: Diagnostica
```

Nel `Drawer` (mobile, ≤768px) l'ordine è:

```
0: Dashboard | 1: Testnet | 2: Account | 3: Storico | 4: Ordini | 5: Log | 6: Impostazioni | 7: Diagnostica
```

**"Ordini" e "Storico" sono scambiati di posizione.** Un utente che usa l'app su mobile troverà Storico al posto 3 e Ordini al posto 4, mentre su desktop è l'inverso. Nessun impatto funzionale (le voci sono separate, non usano l'index numerico per navigare), ma crea confusione cognitiva.

**File:** `main_shell.dart`

### P3 — Indicatori di connessione duplicati e incoerenti

Esistono **due** indicatori separati dello stato connessione backend, visibili contemporaneamente:

1. **`_ServerHealthBadge`** nel leading del NavigationRail → legge `GrpcClientManager.statusStream` + `health.HealthClient.watch()`
2. **Dot colorato + testo** nell'AppBar della DashboardPage → legge `StrategyStateBloc.status`

Sono due sorgenti diverse che possono mostrare stati contrastanti (es. "SERVING" in un posto, "gRPC Offline" nell'altro). L'utente non capisce quale credere.

**File:** `main_shell.dart`, `dashboard_page.dart`

### P4 — Rotta di errore non tematizzata

```dart
// app_router.dart:69-72
errorBuilder: (context, state) => Scaffold(
  body: Center(child: Text('Pagina non trovata: ${state.error}')),
),
```

Stack trace grezza esposta all'utente. Nessun tema, nessun pulsante per tornare alla dashboard.

**File:** `app_router.dart`

---

## 4. DASHBOARD

### P5 — `childAspectRatio: 1.0` forza card quadrate

```dart
// dashboard_grid.dart:26
childAspectRatio: 1.0,
```

Le card nella dashboard hanno tutte `childAspectRatio: 1.0` (perfettamente quadrate). Il problema è che alcune card — in particolare `TradingControlPanel` e `StrategyTargetsCard` — hanno contenuto denso che non si adatta a proporzioni quadrate. Il risultato è:

- Overflow nascosto da `SingleChildScrollView` interno (scroll within scroll)
- Su schermi medi il contenuto viene troncato o compresso

**File:** `dashboard_grid.dart`

### P6 — `GridView shrinkWrap` dentro `SingleChildScrollView` (antipattern)

```dart
// dashboard_page.dart:136 + dashboard_grid.dart:21-28
SingleChildScrollView(
  child: Column(
    children: [
      DashboardGrid(),  // → GridView(shrinkWrap: true, physics: NeverScrollableScrollPhysics)
      TradingDashboardChartsSimple(...)
    ]
  )
)
```

Antipattern classico Flutter. `GridView` con `shrinkWrap: true` all'interno di uno `ScrollView` causa il calcolo di tutti gli item contemporaneamente (nessuna virtualizzazione), impattando le performance con molte card. Stessa situazione in `SettingsForm`.

**File:** `dashboard_page.dart`, `dashboard_grid.dart`, `settings_form.dart`

### B2 — `SettingsBloc` istanziato due volte

`MainShell` crea un `SettingsBloc` tramite `MultiBlocProvider`. `DashboardView` ne crea un secondo identico:

```dart
// dashboard_page.dart:24-26
return BlocProvider(
  create: (context) => sl<SettingsBloc>()..add(SettingsFetched()),
  child: Scaffold(...)
```

Quello in `DashboardView` fa shadowing di quello di `MainShell` per l'albero della dashboard. Sono due istanze separate che fanno due chiamate gRPC separate per le stesse impostazioni.

**File:** `dashboard_page.dart`, `main_shell.dart`

### P7 — Charts "false" — nessun grafico reale

`TradingDashboardChartsSimple` e `ProfitChartCard` NON usano nessuna libreria di charting. Il "grafico" del profit è un `Container` con gradiente che mostra solo un numero centrato:

```dart
// trading_dashboard_charts_simple.dart:171-220
Container(
  height: 200,
  decoration: BoxDecoration(gradient: LinearGradient(...)),
  child: Center(child: Text('\$${totalProfit.toStringAsFixed(2)}')),
)
```

Per un trading bot, l'assenza di un grafico P&L temporale, candlestick, o curva equity è una mancanza UX significativa. I widget si chiamano "charts" ma non lo sono.

**File:** `trading_dashboard_charts_simple.dart`, `profit_chart_card.dart`

---

## 5. TRADING CONTROL PANEL

### B3 — Dead code nel button START

```dart
// trading_control_panel.dart:311
label: isIdle ? 'START' : 'START',  // ← entrambi i branch identici
```

Il ternario è privo di senso. Probabilmente era `isIdle ? 'START' : 'RESTART'` o simile.

**File:** `trading_control_panel.dart:311`

### P8 — Tutti i bottoni mostrano loading contemporaneamente

I tre pulsanti START/PAUSE/STOP mostrano `CircularProgressIndicator` **tutti insieme** quando un'operazione è in corso:

```dart
// trading_control_panel.dart:315-316
isLoading: controlState.status == OperationStatus.inProgress,
```

Tutti e tre i bottoni mostrano loading contemporaneamente — non è chiaro quale operazione stia avvenendo.

**File:** `trading_control_panel.dart`

### P9 — `FutureBuilder` annidati senza caching

```dart
// trading_control_panel.dart:419-477
FutureBuilder<bool>(
  future: RunControlPrefs.getStopAfterNextSell(...),
  builder: (context, stopSnap) {
    return FutureBuilder<int>(
      future: RunControlPrefs.getMaxCycles(...),
      ...
```

Due `FutureBuilder` annidati che chiamano storage async ad ogni rebuild del widget. Nessun caching. Se il widget si ricostruisce frequentemente (es. per aggiornamenti del BLoC padre), vengono fatte letture di storage inutili.

**File:** `trading_control_panel.dart:419`

---

## 6. SETTINGS PAGE

### P10 — Doppio SnackBar in caso di warning

Esistono **due meccanismi separati** che mostrano SnackBar per i warning:

**Meccanismo 1** — in `BlocConsumer.listener`:
```dart
// settings_page.dart:152-186
if (state.status == SettingsStatus.saved) { ... showSnackBar(...) }
```

**Meccanismo 2** — in `BlocConsumer.builder`:
```dart
// settings_page.dart:191-200
if (state.warnings.isNotEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(...)
  });
}
```

In caso di save con warning, **entrambi si attivano**: il listener per il messaggio "saved", e il builder (via postFrameCallback) per i warning. L'utente vede due SnackBar in rapida successione. Inoltre, la SnackBar nel builder si riattiverà ad ogni rebuild finché i warning non sono svuotati.

**File:** `settings_page.dart`

### P11 — PopupMenu per sezioni: UX sub-ottimale su mobile

Il menu "Vai alla sezione" apre un `PopupMenuButton` con le 6 sezioni. Funziona bene su desktop, ma su mobile con drawer è nascosto nell'AppBar in un menu contestuale — non intuitivo per la navigazione intra-pagina. Una sidebar laterale fissa o un set di tab sarebbe più naturale.

**File:** `settings_page.dart`

---

## 7. SYSTEM LOGS PAGE

### P12 — Nessun AppBar — inconsistenza di navigazione critica

`SystemLogsPage` non ha un `Scaffold.appBar`. Ogni altra pagina dell'app ha un `AppBar` con titolo e azioni. I Log hanno un header costruito manualmente con un `Row` nel body:

```dart
// system_logs_page.dart:69-142
body: Padding(
  child: Column(
    children: [
      Row(children: [
        Text('Log di Sistema'),
        ...FilterChip, FilterChip, FilterChip, TextField, Switch, IconButton...
      ]),
```

Su mobile (drawer layout), questa pagina non avrà il titolo nell'AppBar e il drawer non sarà apribile (non c'è AppBar con menu burger). **L'utente non può navigare ad altra sezione dalla pagina Log su mobile senza gesture di back.**

**File:** `system_logs_page.dart`

### P13 — Overflow del header su schermi stretti

Il `Row` header dei log contiene: testo titolo + 3 `FilterChip` + `TextField` 220px + label "Auto‑scroll" + `Switch` + `IconButton`. Su schermi ≤600px questo **va in overflow** con certezza.

**File:** `system_logs_page.dart:67`

### P14 — Footer loader sempre visibile

```dart
// system_logs_page.dart:203-213
if (index == filtered.length) {
  return Padding(
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}
```

Il `CircularProgressIndicator` come footer è mostrato **sempre**, anche quando non c'è più nulla da caricare (es. se `visibleCount >= logs.length`). L'utente vede un loader eterno in fondo alla lista.

**File:** `system_logs_page.dart:203`

---

## 8. ACCOUNT PAGE

### B4 — Logica play/pause invertita o errata

```dart
// account_page.dart:56-68
onPressed: () {
  if (state is AccountLoaded && state.isStreaming) {
    // "Stop streaming"
    context.read<AccountBloc>().add(const LoadAccountInfo()); // ← carica una volta, non pausa
  } else {
    context.read<AccountBloc>().add(const SubscribeToAccountInfo());
  }
},
```

Quando l'utente preme "Ferma aggiornamenti" (icona pause), viene emesso `LoadAccountInfo` che è un caricamento one-shot, non un vero stop dello stream. Se lo stream è aperto, continuerà ad aggiornare i dati mentre il pulsante cambia icona a "play" — incoerenza tra stato UI e stato reale.

**File:** `account_page.dart:56`

---

## 9. TESTNET PAGE

### P15 — SliverAppBar isolato: inconsistenza visiva

Solo la `TestnetMonitoringPage` usa `SliverAppBar` con `expandedHeight: 120`. Tutte le altre pagine usano `AppBar` standard. Il titolo nella SliverAppBar usa `centerTitle: false` e uno style inline hardcoded, non passando dal theme:

```dart
// testnet_monitoring_page.dart:39-43
Text(
  'Binance Testnet Monitoring',
  style: TextStyle(
    color: isTestMode ? Colors.orangeAccent : AppTheme.primaryColor,
    fontWeight: FontWeight.bold,
    // ← mancano GoogleFonts.orbitron e letterSpacing usati in tutte le altre pagine
  ),
),
```

**File:** `testnet_monitoring_page.dart`

---

## 10. TLS DIAGNOSTICS PAGE

### P16 — Pagina non tematizzata

La `TlsDiagnosticsPage` usa un `ListView` grezzo senza card, senza `AppTheme.cardDecoration`, senza bordi tematici. È l'unica pagina che non usa il design system del progetto.

**File:** `tls_diagnostics_page.dart`

### P17 — Variabile hardcoded con nome fuorviante

```dart
// tls_diagnostics_page.dart:57
final inferredSecureRequested = true;  // ← hardcoded, non inferito
```

Il nome "inferredSecureRequested" suggerisce un calcolo dinamico, ma è una costante `true`. La variabile è usata solo per la display e mostra sempre "true" indipendentemente dalla configurazione reale.

**File:** `tls_diagnostics_page.dart:57`

---

## 11. PRICE DISPLAY CARD

### P18 — Troppi decimali per asset ad alto prezzo

```dart
// price_display_card.dart:125
'\$${widget.priceData!.currentPrice.toStringAsFixed(8)}',
// → $100247.00000000 per BTC/USDC — zeri inutili
```

8 decimali ha senso per asset a basso prezzo (es. DOGE: `$0.12345678`), ma per BTC/USDC mostra `$100247.00000000` — tutti zeri dopo la virgola che occupano spazio senza informazione. Stesso problema per `priceChangeAbsolute24h`.

**File:** `price_display_card.dart:125`

### P19 — Badge "24H" senza Tooltip

Il badge colorato "24H" nel header della card non ha `Tooltip`. Un utente non esperto non può capire cosa rappresenta senza documentazione.

**File:** `price_display_card.dart:103`

---

## 12. STRATEGY TARGETS CARD

### P20 — Triple BlocBuilder annidati — rebuild eccessivi

```dart
// strategy_targets_card.dart:54-131
BlocBuilder<SettingsBloc, ...>(
  builder: (...) {
    return BlocBuilder<StrategyStateBloc, ...>(
      builder: (...) {
        return BlocBuilder<PriceBlocReal, ...>(
          builder: (...) {
            return _buildCard(...);
          },
        );
      },
    );
  },
);
```

Tre `BlocBuilder` annidati. Il terzo (`PriceBlocReal`) si ricostruisce ad **ogni aggiornamento di prezzo** (stream real-time frequente), ridisegnando l'intera card anche quando il contenuto non è cambiato. Considerando la frequenza degli aggiornamenti di prezzo, questa card può generare decine di rebuild al minuto.

**File:** `strategy_targets_card.dart:54`

---

## 13. RIEPILOGO CRITICITÀ PER PRIORITÀ

### 🔴 Critiche — Bug o UX bloccante

| ID | Problema | File | Riga |
|----|----------|------|------|
| B1 | Ordine Ordini/Storico invertito tra Rail e Drawer | `main_shell.dart` | 84–125 / 199–275 |
| B2 | `SettingsBloc` istanziato due volte (shadowing) | `dashboard_page.dart` | 24 |
| B3 | Button START — ternario dead code (sempre 'START') | `trading_control_panel.dart` | 311 |
| B4 | Account "pause" chiama LoadAccountInfo invece di stop stream | `account_page.dart` | 62 |
| P10 | Doppio SnackBar warning in Settings | `settings_page.dart` | 191 |
| P12 | SystemLogsPage senza AppBar — mobile inaccessibile | `system_logs_page.dart` | 61 |
| P14 | Footer loader sempre visibile anche a fine lista | `system_logs_page.dart` | 203 |

### 🟠 Significative — UX degradata

| ID | Problema | File | Riga |
|----|----------|------|------|
| P1 | Font Orbitron size 9px su bottoni controllo | `trading_control_panel.dart` | 407 |
| P3 | Indicatori connessione duplicati e incoerenti | `main_shell.dart`, `dashboard_page.dart` | — |
| P5 | `childAspectRatio: 1.0` — card quadrate con contenuto denso | `dashboard_grid.dart` | 26 |
| P6 | GridView `shrinkWrap` dentro ScrollView (antipattern) | `dashboard_grid.dart`, `settings_form.dart` | 21 |
| P7 | Charts non sono chart — solo stat text e box colorati | `trading_dashboard_charts_simple.dart` | — |
| P8 | Tutti i bottoni mostrano loading contemporaneamente | `trading_control_panel.dart` | 315 |
| P13 | Log header overflow su schermi ≤600px | `system_logs_page.dart` | 67 |
| P15 | SliverAppBar isolato — inconsistenza navigazione | `testnet_monitoring_page.dart` | 25 |
| P16 | TLS page non tematizzata con il design system | `tls_diagnostics_page.dart` | — |
| P18 | 8 decimali su prezzo BTC/USDC — illeggibile | `price_display_card.dart` | 125 |
| P20 | Triple BlocBuilder annidati — rebuild eccessivi | `strategy_targets_card.dart` | 54 |

### 🟡 Minori — Polish / qualità del codice

| ID | Problema | File | Riga |
|----|----------|------|------|
| P2 | Nessun light theme disponibile | `app_theme.dart` | — |
| P4 | Error page router non tematizzata | `app_router.dart` | 69 |
| P9 | FutureBuilder annidati senza caching per SharedPrefs | `trading_control_panel.dart` | 419 |
| P11 | PopupMenu sezioni — UX sub-ottimale su mobile | `settings_page.dart` | 64 |
| P17 | `inferredSecureRequested` hardcoded con nome fuorviante | `tls_diagnostics_page.dart` | 57 |
| P19 | Badge "24H" senza Tooltip descrittivo | `price_display_card.dart` | 103 |

**Totale: 7 critici · 11 significativi · 6 minori = 24 problemi identificati**

---

## 14. ASPETTI POSITIVI DA PRESERVARE

1. **Architettura BLoC rigorosa** — separazione eventi/stati corretta, `buildWhen` usato in diversi punti per ottimizzare i rebuild
2. **Tooltips diffusi** — quasi ogni elemento interattivo ha un `Tooltip` descrittivo
3. **Responsività di base** — `LayoutBuilder` con breakpoint 768px per Rail/Drawer correttamente implementato
4. **Badge TESTNET** in AppBar su Dashboard e Settings — comunicazione del contesto operativo chiara e visibile
5. **Pulse animation** su `PriceDisplayCard` al cambio prezzo — feedback visivo elegante e non invasivo
6. **Warning banner persistente** in Settings AppBar bottom — visibile senza occupare spazio nel body
7. **`AutoSizeText`** usato nelle card per gestire overflow del testo in modo graceful
8. **Lazy loading** nei log con paginazione scroll-to-bottom — approccio corretto per liste potenzialmente infinite
9. **Dialog di conferma** per operazioni distruttive (Cancella Tutti ordini) — protezione adeguata
10. **`AppSnackBar` centralizzato** — stile unificato per tutte le notifiche dell'app

---

*Report generato tramite analisi statica completa — nessuna modifica al codice effettuata.*

