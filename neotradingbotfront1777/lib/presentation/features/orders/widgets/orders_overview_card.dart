import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';

class OrdersOverviewCard extends StatelessWidget {
  const OrdersOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is! OrdersLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 24),
              _buildMainStats(context, state),
              const SizedBox(height: 20),
              _buildOrderStatusBreakdown(context, state),
              if (state.symbolLimits != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _buildFeeStats(context, state.symbolLimits!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, OrdersLoaded state) {
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
        Expanded(
          child: Text(
            'PANORAMICA ORDINI',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (state.currentSymbol != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              state.currentSymbol!,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainStats(BuildContext context, OrdersLoaded state) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMainStatsCard(context, state)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatsGrid(context, state)),
      ],
    );
  }

  Widget _buildMainStatsCard(BuildContext context, OrdersLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Ordini Aperti',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            state.totalOrders.toString(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ordini Totali',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, OrdersLoaded state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'BUY',
                state.buyOrders.toString(),
                Icons.trending_up,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'SELL',
                state.sellOrders.toString(),
                Icons.trending_down,
                AppTheme.errorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'In Attesa',
          state.pendingOrders.toString(),
          Icons.schedule,
          AppTheme.warningColor,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child:
          isWide
              ? Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: AppTheme.mutedTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildOrderStatusBreakdown(BuildContext context, OrdersLoaded state) {
    final orderStats = [
      {
        'label': 'Completati',
        'value': state.completedOrders,
        'color': AppTheme.successColor,
        'icon': Icons.check_circle,
      },
      {
        'label': 'In Attesa',
        'value': state.pendingOrders,
        'color': AppTheme.warningColor,
        'icon': Icons.schedule,
      },
      {
        'label': 'Cancellati',
        'value': state.cancelledOrders,
        'color': AppTheme.errorColor,
        'icon': Icons.cancel,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dettaglio Stato',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedTextColor,
              ),
            ),
            const Spacer(),
            if (state.totalOrders > 0)
              Text(
                'Fill: ${state.averageFillPercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children:
              orderStats.map((stat) {
                final index = orderStats.indexOf(stat);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < orderStats.length - 1 ? 12.0 : 0,
                    ),
                    child: _buildStatusChip(stat),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        _buildValueStats(context, state),
      ],
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (stat['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (stat['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat['label'] as String,
                  style: TextStyle(
                    color: stat['color'] as Color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (stat['value'] as int).toString(),
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueStats(BuildContext context, OrdersLoaded state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mutedTextColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.mutedTextColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.mutedTextColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Valore Totale',
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
                  '\$${state.totalOrderValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.paid, color: AppTheme.successColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Eseguito',
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
                  '\$${state.totalExecutedValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeStats(BuildContext context, SymbolLimits limits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Commissioni (${limits.feeCurrency})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedTextColor,
              ),
            ),
            if (limits.isDiscountActive) ...[
              const SizedBox(width: 12),
              _buildDiscountBadge(limits.discountPercentage),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeeItem(
                'Maker Fee',
                '${(limits.makerFee * 100).toStringAsFixed(3)}%',
                Icons.input,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeeItem(
                'Taker Fee',
                '${(limits.takerFee * 100).toStringAsFixed(3)}%',
                Icons.output,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountBadge(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            '-${percentage.toStringAsFixed(0)}% BNB',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.mutedTextColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedTextColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
