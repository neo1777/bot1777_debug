import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_state.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/charts/profit_chart_widget.dart';

class ProfitChartCard extends StatefulWidget {
  const ProfitChartCard({super.key});

  @override
  State<ProfitChartCard> createState() => _ProfitChartCardState();
}

class _ProfitChartCardState extends State<ProfitChartCard> {
  int _selectedPeriod = 7; // 7, 30, 90 days

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          BlocBuilder<TradeHistoryBloc, TradeHistoryState>(
            builder: (context, state) {
              if (state is TradeHistoryLoaded) {
                return _buildContent(state);
              }
              return _buildPlaceholder();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'ANDAMENTO PROFITTO',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        const Spacer(),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            [7, 30, 90].map((period) {
              final isSelected = _selectedPeriod == period;
              return GestureDetector(
                onTap: () => setState(() => _selectedPeriod = period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${period}G',
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.mutedTextColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildContent(TradeHistoryLoaded state) {
    return Column(
      children: [
        _buildStatsRow(state),
        const SizedBox(height: 20),
        _buildProfitChartCristalyse(state),
      ],
    );
  }

  Widget _buildStatsRow(TradeHistoryLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Profitto Totale',
            '\$${state.totalProfit.toStringAsFixed(2)}',
            state.totalProfit >= 0
                ? AppTheme.successColor
                : AppTheme.errorColor,
            state.totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Trade Totali',
            state.totalTrades.toString(),
            AppTheme.primaryColor,
            Icons.analytics,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Volume',
            '\$${_formatVolume(state.totalVolume)}',
            AppTheme.mutedTextColor,
            Icons.account_balance_wallet,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChartCristalyse(TradeHistoryLoaded state) {
    // I trades del bloc sono già AppTrade
    final List<AppTrade> trades = state.trades;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: ProfitChartWidget(
        trades: trades,
        height: 220,
        showCumulative: true,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toStringAsFixed(0);
  }
}
