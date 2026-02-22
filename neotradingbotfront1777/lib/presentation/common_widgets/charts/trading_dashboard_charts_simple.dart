import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_state.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/charts/profit_chart_widget.dart';

/// Versione semplificata di TradingDashboardCharts che usa solo dati reali
/// dal backend (TradeHistory). Non include prezzi in tempo reale perché
/// il backend streamCurrentPrice non è implementato.
class TradingDashboardChartsSimple extends StatelessWidget {
  const TradingDashboardChartsSimple({required this.symbol, super.key});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor,
            AppTheme.backgroundColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildTradeHistoryChart()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trading Analytics',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Symbol: $symbol (Dati reali backend)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistoryChart() {
    return BlocBuilder<TradeHistoryBloc, TradeHistoryState>(
      builder: (context, state) {
        if (state is TradeHistoryLoading) {
          return _buildLoadingWidget('Caricamento storico trading...');
        }

        if (state is TradeHistoryError) {
          return _buildErrorWidget('Errore caricamento dati: ${state.message}');
        }

        if (state is TradeHistoryLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTradeStatistics(state.trades),
                const SizedBox(height: 16),
                _buildProfitChart(state.trades),
              ],
            ),
          );
        }

        return _buildEmptyWidget('Nessun dato trading disponibile');
      },
    );
  }

  Widget _buildTradeStatistics(List<AppTrade> trades) {
    final totalTrades = trades.length;
    final profitableTrades =
        trades
            .where((trade) => trade.profit != null && trade.profit! > 0)
            .length;
    final totalProfit = trades.fold<double>(0.0, (sum, trade) {
      final profit = trade.profit;
      return sum + (profit ?? 0.0);
    });
    final winRate =
        totalTrades > 0 ? (profitableTrades / totalTrades) * 100 : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Totale Trade',
            totalTrades.toString(),
            Icons.analytics,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Profitto Totale',
            '\$${totalProfit.toStringAsFixed(2)}',
            Icons.trending_up,
            totalProfit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Win Rate',
            '${winRate.toStringAsFixed(1)}%',
            Icons.percent,
            winRate >= 60 ? AppTheme.successColor : AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitChart(List<AppTrade> trades) {
    // P7 fix: usa il widget reale fl_chart al posto del placeholder gradiente
    return ProfitChartWidget(trades: trades, height: 200, showCumulative: true);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.textColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage, size: 48, color: AppTheme.mutedTextColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
