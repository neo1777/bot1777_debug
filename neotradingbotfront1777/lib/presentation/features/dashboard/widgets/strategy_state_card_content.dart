import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

// [AUDIT-PHASE-10] - Presentation & UX Audit Marker
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';

class StrategyStateCardContent extends StatelessWidget {
  final StrategyState? state;
  final String? failureMessage;
  final String? symbol;

  const StrategyStateCardContent({
    super.key,
    this.state,
    this.failureMessage,
    this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    // Se abbiamo un errore lato stream ma nessuno stato, mostriamo un contenuto "vuoto"
    // più user-friendly invece del pannello d'errore bloccante.
    if (failureMessage != null && state == null) {
      return _buildEmptyPlaceholder();
    } else if (failureMessage != null) {
      return _buildErrorContent(failureMessage!);
    }

    // Se lo stato è nullo, creiamo uno stato di default "IDLE" per il simbolo fornito o attivo.
    final displayState =
        state ??
        StrategyState.initial(
          symbol: symbol ?? sl<SymbolContext>().activeSymbol,
        );

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Stato:',
            _getStatusText(displayState.status),
            _getStatusColor(displayState.status),
          ),
          _buildInfoRow('Simbolo:', displayState.symbol),
          _buildInfoRow(
            'Profitto Cumulativo:',
            displayState.status == StrategyStatus.idle
                ? '—'
                : '${displayState.cumulativeProfit.toStringAsFixed(2)} \$',
          ),
          _buildInfoRow(
            'Prezzo Medio Acquisto:',
            displayState.status == StrategyStatus.idle
                ? '—'
                : displayState.averagePrice.toStringAsFixed(6),
          ),
          _buildInfoRow(
            'Trade Aperti:',
            displayState.status == StrategyStatus.idle
                ? '—'
                : displayState.openTradesCount.toString(),
          ),
          _buildAutoStopPill(displayState.warningMessage),
          if (displayState.warnings.contains('RECOVERING'))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: _RecoveringIndicator(),
            ),
          if ((displayState.warningMessage ?? '').isNotEmpty &&
              _shouldShowRawWarning(displayState.warningMessage!))
            _WarningBanner(message: displayState.warningMessage!),
          if (_isDefaultState(displayState))
            const _StrategyNotStartedIndicator(),
        ],
      ),
    );
  }
}

class _RecoveringIndicator extends StatelessWidget {
  const _RecoveringIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Tooltip(
        message: message,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warningColor.withAlpha(100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AutoSizeText(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 3,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategyNotStartedIndicator extends StatelessWidget {
  const _StrategyNotStartedIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.orange.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Strategia non ancora avviata.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on StrategyStateCardContent {
  Widget _buildAutoStopPill(String? warningMessage) {
    if (warningMessage == null || warningMessage.isEmpty) {
      return const SizedBox.shrink();
    }
    // Estrai remaining da pattern AUTO_STOP_IN_CYCLES;remaining=N...
    try {
      final parts = warningMessage.split(';');
      final rem = parts.firstWhere(
        (p) => p.trim().startsWith('AUTO_STOP_IN_CYCLES'),
        orElse: () => '',
      );
      if (rem.isEmpty) return const SizedBox.shrink();
      // Se presente anche in warnings come AUTO_STOP_IN_CYCLES:N, la pill rimane valida comunque
      String? remainingText;
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2 && kv[0].trim() == 'remaining') {
          remainingText = kv[1].trim();
          break;
        }
      }
      if (remainingText == null) return const SizedBox.shrink();
      final remaining = int.tryParse(remainingText) ?? -1;
      if (remaining < 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningColor.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timelapse,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cicli rimanenti: $remaining',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400, size: 28),
            const SizedBox(height: 8),
            AutoSizeText(
              'Strategia non ancora avviata',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
            const SizedBox(height: 8),
            AutoSizeText(
              'Errore: $message',
              style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    final tileColor = (valueColor ?? AppTheme.mutedTextColor).withAlpha(25);
    final borderColor = (valueColor ?? AppTheme.mutedTextColor).withAlpha(80);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: AutoSizeText(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppTheme.textColor,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                minFontSize: 11,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(StrategyStatus status) => status.displayName;

  Color _getStatusColor(StrategyStatus status) => status.color;

  bool _shouldShowRawWarning(String msg) {
    if (msg.isEmpty) return false;
    final lower = msg.toLowerCase();
    final rawTerms = [
      'auto_stop_in_cycles',
      'serverfailure',
      'exception',
      'grpc error',
      'status(',
      'connection closed',
      'channel is in state',
      'failed to connect',
    ];
    for (final term in rawTerms) {
      if (lower.contains(term)) return false;
    }
    return true;
  }

  /// Determina se lo stato corrente è quello di default (tutti valori a 0)
  /// Questo indica che stiamo usando dati di fallback del frontend
  bool _isDefaultState(StrategyState state) {
    return state.status == StrategyStatus.idle &&
        state.openTradesCount == 0 &&
        state.averagePrice == 0.0 &&
        state.totalQuantity == 0.0 &&
        state.lastBuyPrice == 0.0 &&
        state.cumulativeProfit == 0.0 &&
        state.successfulRounds == 0 &&
        state.failedRounds == 0;
  }
}
