import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';

/// Formatta i messaggi di notifica per Telegram.
///
/// Tutti i messaggi usano Markdown per una resa visiva ricca in Telegram.
/// I metodi sono statici e puri (nessun side-effect) per facilitare il testing.
class NotificationFormatter {
  const NotificationFormatter._();

  // ─── BUY ─────────────────────────────────────────────────────

  /// Messaggio inviato dopo un acquisto iniziale completato.
  static String formatBuy({
    required String symbol,
    required AppTrade trade,
    required AppStrategyState state,
  }) {
    final price = trade.price.value.toStringAsFixed(6);
    final qty = trade.quantity.value.toStringAsFixed(8);
    final round = state.currentRoundId;
    return '🟢 *BUY* | `$symbol`\n'
        '💰 Prezzo: `$price`\n'
        '📦 Quantità: `$qty`\n'
        '🔄 Round: `$round`';
  }

  // ─── SELL ────────────────────────────────────────────────────

  /// Messaggio inviato dopo una vendita completata con P/L.
  static String formatSell({
    required String symbol,
    required AppTrade trade,
    required AppStrategyState state,
    required double profitPercent,
  }) {
    final price = trade.price.value.toStringAsFixed(6);
    final qty = trade.quantity.value.toStringAsFixed(8);
    final profit =
        trade.profit != null ? trade.profit!.value.toStringAsFixed(6) : '—';
    final emoji = profitPercent >= 0 ? '📈' : '📉';
    final pctStr = profitPercent >= 0
        ? '+${profitPercent.toStringAsFixed(2)}%'
        : '${profitPercent.toStringAsFixed(2)}%';
    final cumProfit = state.cumulativeProfit.toStringAsFixed(4);

    return '🔴 *SELL* | `$symbol`\n'
        '💰 Prezzo: `$price`\n'
        '📦 Quantità: `$qty`\n'
        '$emoji P/L: `$profit` ($pctStr)\n'
        '💵 Profitto cumulativo: `$cumProfit`\n'
        '✅ Round completati: `${state.successfulRounds}` | '
        '❌ Falliti: `${state.failedRounds}`';
  }

  // ─── DCA ─────────────────────────────────────────────────────

  /// Messaggio inviato dopo un acquisto DCA (incrementale).
  static String formatDca({
    required String symbol,
    required AppTrade trade,
    required AppStrategyState state,
  }) {
    final price = trade.price.value.toStringAsFixed(6);
    final qty = trade.quantity.value.toStringAsFixed(8);
    final openCount = state.openTrades.length;
    final avgPrice = state.averagePrice.toStringAsFixed(6);

    return '🔵 *DCA BUY* | `$symbol`\n'
        '💰 Prezzo: `$price`\n'
        '📦 Quantità: `$qty`\n'
        '📊 Posizioni aperte: `$openCount`\n'
        '📐 Prezzo medio: `$avgPrice`';
  }

  // ─── ERRORI ──────────────────────────────────────────────────

  /// Messaggio inviato su errore critico nel loop di trading.
  static String formatError({
    required String symbol,
    required String action,
    required String errorMessage,
  }) {
    return '⚠️ *ERRORE* | `$symbol`\n'
        '🔧 Azione: `$action`\n'
        '❗ Dettaglio: `$errorMessage`';
  }

  // ─── DUST DISCARD ────────────────────────────────────────────

  /// Messaggio inviato quando la quantità residua è considerata dust.
  static String formatDustDiscard({
    required String symbol,
    required double price,
  }) {
    return '🧹 *DUST DISCARD* | `$symbol`\n'
        '💰 Prezzo: `${price.toStringAsFixed(6)}`\n'
        '📝 Quantità residua troppo piccola, round chiuso in perdita.';
  }
}
