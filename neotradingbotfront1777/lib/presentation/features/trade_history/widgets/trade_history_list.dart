import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_state.dart';

class TradeHistoryList extends StatelessWidget {
  const TradeHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TradeHistoryBloc, TradeHistoryState>(
      builder: (context, state) {
        if (state is TradeHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TradeHistoryError) {
          return Center(
            child: Text(
              'Errore: ${state.message}',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        if (state is TradeHistoryLoaded && state.filteredTrades.isEmpty) {
          return _buildEmptyState();
        }

        if (state is TradeHistoryLoaded) {
          return _buildTradesList(state.filteredTrades);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(Icons.trending_up, size: 64, color: AppTheme.mutedTextColor),
          const SizedBox(height: 16),
          Text(
            'Nessun trade trovato',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I tuoi trade appariranno qui quando inizierai a fare trading',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTradesList(List<AppTrade> trades) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildListHeader(),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: trades.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildTradeItem(trades[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'LISTA TRADE',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeItem(AppTrade trade) {
    final isBuy = trade.isBuy;
    final tradeColor = isBuy ? AppTheme.successColor : AppTheme.errorColor;
    final tradeIcon = isBuy ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Trade Direction Indicator
          Tooltip(
            message: isBuy ? 'Trade di ACQUISTO' : 'Trade di VENDITA',
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tradeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tradeColor.withValues(alpha: 0.3)),
              ),
              child: Icon(tradeIcon, color: tradeColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),

          // Trade Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      trade.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tradeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trade.side,
                        style: TextStyle(
                          color: tradeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusChip(trade.orderStatus),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Prezzo: \$${trade.price.toStringAsFixed(8)}',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Quantità: ${trade.quantity.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Valore: \$${trade.totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(trade.timestamp),
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    String statusLabel;

    switch (status.toUpperCase()) {
      case 'FILLED':
        statusColor = AppTheme.successColor;
        statusLabel = 'Completato';
        break;
      case 'PENDING':
        statusColor = AppTheme.warningColor;
        statusLabel = 'In attesa';
        break;
      case 'CANCELLED':
        statusColor = AppTheme.errorColor;
        statusLabel = 'Cancellato';
        break;
      default:
        statusColor = AppTheme.mutedTextColor;
        statusLabel = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}g fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m fa';
    } else {
      return 'Ora';
    }
  }
}
